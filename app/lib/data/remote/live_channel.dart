import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../../core/log.dart';
import 'sync_api.dart';

/// Live-байланыстың күйі.
enum LiveStatus {
  /// Синхрондау қосылмаған — сокет ашылмайды.
  off,

  /// Қосылып жатыр (алғашқы рет не қайта).
  connecting,

  /// Ашық: өзгерістер бірден жіберіледі және келеді.
  live,

  /// Байланыс үзілді; [LiveChannel.retryAt] уақытында қайта қосылады.
  waiting,
}

/// Сокет ашу (тесттерде ауыстырылады).
typedef LiveConnector = Future<WebSocketChannel> Function(
  Uri uri,
  Map<String, String> headers,
);

/// Live жоқ кезде сұрау жіберілмеді — HTTP-ге көшу керек.
class LiveUnavailable implements Exception {
  const LiveUnavailable(this.reason);
  final String reason;

  @override
  String toString() => 'LiveUnavailable($reason)';
}

/// `GET /v1/live` WebSocket байланысы (практикалық №7).
///
/// * Синхрондау сокет арқылы: `{"type":"sync"}` → `{"type":"synced"}`.
/// * Сервер `{"type":"changed"}` жіберсе — [changes] оқиғасы: басқа
///   құрылғыда дерек өзгерді, жаңа суретті сұрау керек.
/// * Байланыс үзілсе — экспоненциалды кідіріспен қайта қосылады
///   (1, 2, 4, 8, 16, 30 с), қосылған сайын [connected] оқиғасы:
///   үзіліс кезінде жіберілмеген өзгерістерді қуып жету үшін.
class LiveChannel extends ChangeNotifier {
  LiveChannel({
    LiveConnector? connector,
    Duration Function(int attempt)? backoff,
    this.requestTimeout = const Duration(seconds: 8),
  }) : _connector = connector ?? _ioConnect,
       _backoff = backoff ?? defaultBackoff,
       enabled = true;

  /// Сокетсіз нұсқа: синхрондау тек HTTP арқылы (басқа транспорт
  /// берілген тесттер мен құралдар үшін).
  LiveChannel.disabled()
    : _connector = _ioConnect,
      _backoff = defaultBackoff,
      requestTimeout = Duration.zero,
      enabled = false;

  /// false — [start] ештеңе істемейді, күйі әрдайым [LiveStatus.off].
  final bool enabled;

  static const ping = Duration(seconds: 20);

  static Duration defaultBackoff(int attempt) =>
      Duration(seconds: math.min(30, 1 << math.min(attempt, 5)));

  static Future<WebSocketChannel> _ioConnect(
    Uri uri,
    Map<String, String> headers,
  ) async {
    final channel = IOWebSocketChannel.connect(
      uri,
      headers: headers,
      pingInterval: ping,
      connectTimeout: const Duration(seconds: 8),
    );
    await channel.ready;
    return channel;
  }

  final LiveConnector _connector;
  final Duration Function(int attempt) _backoff;
  final Duration requestTimeout;

  final _changes = StreamController<void>.broadcast();
  final _connected = StreamController<void>.broadcast();
  final _unauthorized = StreamController<void>.broadcast();
  final _pending = <int, Completer<Map<String, Object?>>>{};

  LiveStatus _status = LiveStatus.off;
  DateTime? _retryAt;
  int _attempt = 0;
  int _nextId = 0;
  int _generation = 0;
  WebSocketChannel? _channel;
  StreamSubscription<Object?>? _sub;
  Timer? _retryTimer;
  ({Uri base, String token, String device})? _target;

  LiveStatus get status => _status;
  bool get isLive => _status == LiveStatus.live;

  /// Келесі қайта қосылу уақыты ([LiveStatus.waiting] кезінде).
  DateTime? get retryAt => _retryAt;

  /// Басқа құрылғыдағы өзгеріс туралы хабар.
  Stream<void> get changes => _changes.stream;

  /// Сокет (қайта) ашылды.
  Stream<void> get connected => _connected.stream;

  /// Сервер токенді қабылдамады (4401 не 401): қайта қосылмаймыз,
  /// шақырушы байланысты тексереді (HTTP 401 → қайта кіру).
  Stream<void> get unauthorized => _unauthorized.stream;

  /// Сервер жабқанда: токен жарамсыз.
  static const unauthorizedCode = 4401;

  /// Қосылу. Сол мекенжай мен токенге қайта шақырылса — ештеңе өзгермейді.
  void start({
    required Uri base,
    required String token,
    required String device,
  }) {
    if (!enabled) return;
    final target = (base: base, token: token, device: device);
    if (_target == target && _status != LiveStatus.off) return;
    _close();
    _target = target;
    _attempt = 0;
    unawaited(_connect());
  }

  /// Ажырату (синхрондау өшірілді не аккаунттан шықты).
  void stop() {
    if (_target == null && _status == LiveStatus.off) return;
    _target = null;
    _close();
    _set(LiveStatus.off);
  }

  /// Кідірісті күтпей қазір қосылу («Қазір қосылу», қосымша ашылғанда).
  void retryNow() {
    if (_status != LiveStatus.waiting || _target == null) return;
    _retryTimer?.cancel();
    unawaited(_connect());
  }

  Future<void> _connect() async {
    final target = _target;
    if (target == null) return;
    final generation = ++_generation;
    _retryAt = null;
    _set(LiveStatus.connecting);
    final scheme = target.base.scheme == 'https' ? 'wss' : 'ws';
    final uri = target.base.replace(scheme: scheme, path: '/v1/live');
    try {
      final channel = await _connector(uri, {
        'authorization': 'Bearer ${target.token}',
        HttpSyncApi.deviceHeader: target.device,
      });
      if (generation != _generation) {
        unawaited(channel.sink.close());
        return;
      }
      _channel = channel;
      _sub = channel.stream.listen(
        _onMessage,
        onDone: () => channel.closeCode == unauthorizedCode
            ? _rejected(generation)
            : _lost(generation, 'closed ${channel.closeCode}'),
        onError: (Object e) => _lost(generation, '$e'),
        cancelOnError: true,
      );
    } catch (e) {
      // Upgrade алдында 401: dart:io мәтінінде ғана көрінеді.
      if ('$e'.contains('status code: 401')) {
        _rejected(generation);
      } else if (generation == _generation) {
        _lost(generation, '$e');
      }
    }
  }

  void _onMessage(Object? raw) {
    final Map<String, Object?> m;
    try {
      m = (jsonDecode(raw! as String) as Map).cast<String, Object?>();
    } on Object {
      Log.warn('live', 'bad message');
      return;
    }
    switch (m['type']) {
      case 'ready':
        _attempt = 0;
        _set(LiveStatus.live);
        Log.info('live', 'connected');
        _connected.add(null);
      case 'changed':
        Log.info('live', 'changed on another device');
        _changes.add(null);
      case 'synced':
        final snapshot = m['snapshot'];
        final c = _pending.remove(m['id']);
        if (snapshot is Map) {
          c?.complete(snapshot.cast<String, Object?>());
        } else {
          c?.completeError(const SyncApiException(SyncFailure.server));
        }
      case 'error':
        final status = m['status'];
        _pending
            .remove(m['id'])
            ?.completeError(
              SyncApiException(
                failureFor(status is int ? status : 500, m['error']),
                m['message'] as String?,
              ),
            );
    }
  }

  void _lost(int generation, String reason) {
    if (generation != _generation || _target == null) return;
    _dropConnection();
    final delay = _backoff(_attempt++);
    _retryAt = DateTime.now().add(delay);
    Log.warn('live', 'disconnected ($reason), retry in ${delay.inSeconds}s');
    _set(LiveStatus.waiting);
    _retryTimer = Timer(delay, () => unawaited(_connect()));
  }

  void _rejected(int generation) {
    if (generation != _generation || _target == null) return;
    Log.warn('live', 'token rejected, not reconnecting');
    _target = null;
    _close();
    _set(LiveStatus.off);
    _unauthorized.add(null);
  }

  /// Синхрондау сокет арқылы. Live жоқ болса не уақыт өтсе —
  /// [LiveUnavailable] (шақырушы HTTP-ге көшеді).
  Future<Map<String, Object?>> sync(Map<String, Object?> body) async {
    final channel = _channel;
    if (!isLive || channel == null) throw const LiveUnavailable('not live');
    final id = ++_nextId;
    final completer = _pending[id] = Completer<Map<String, Object?>>();
    channel.sink.add(jsonEncode({'type': 'sync', 'id': id, 'body': body}));
    try {
      return await completer.future.timeout(requestTimeout);
    } on TimeoutException {
      _pending.remove(id);
      throw const LiveUnavailable('timeout');
    }
  }

  void _dropConnection() {
    _sub?.cancel();
    _sub = null;
    final channel = _channel;
    _channel = null;
    if (channel != null) unawaited(channel.sink.close());
    for (final c in _pending.values) {
      c.completeError(const LiveUnavailable('connection lost'));
    }
    _pending.clear();
  }

  void _close() {
    _generation++;
    _retryTimer?.cancel();
    _retryTimer = null;
    _retryAt = null;
    _dropConnection();
  }

  void _set(LiveStatus status) {
    if (_status == status) {
      notifyListeners(); // retryAt өзгерді
      return;
    }
    _status = status;
    notifyListeners();
  }

  @override
  void dispose() {
    _target = null;
    _close();
    _changes.close();
    _connected.close();
    _unauthorized.close();
    super.dispose();
  }
}
