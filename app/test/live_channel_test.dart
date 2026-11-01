// LiveChannel (практикалық №7): тест ішіндегі нақты WebSocket сервері
// (dart:io) — қосылу, хабар алу, сокет арқылы синхрондау, үзілу және
// қайта қосылу. Әр тестте «күтілетін нәтиже» expect-те көрсетілген.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:intrvue/data/remote/live_channel.dart';
import 'package:intrvue/data/remote/sync_api.dart';

/// Бір клиентті қабылдайтын шағын сервер: келген хабарларды жазады,
/// [reply] арқылы жауап береді.
class _WsServer {
  late HttpServer _http;
  final sockets = <WebSocket>[];
  final headers = <HttpHeaders>[];
  final received = <Map<String, Object?>>[];
  int accepted = 0;

  /// true — қосылуды 503-пен қабылдамау (сервер «құлаған»).
  bool refuse = false;

  /// sync сұрауына жауап; null — жауап бермеу.
  Map<String, Object?>? Function(Map<String, Object?> m) reply = (m) => {
    'type': 'synced',
    'id': m['id'],
    'snapshot': {'topics': [], 'echo': m['body']},
  };

  Uri get base => Uri.parse('http://127.0.0.1:${_http.port}');
  WebSocket get last => sockets.last;

  Future<void> start() async {
    _http = await HttpServer.bind('127.0.0.1', 0);
    _http.listen((request) async {
      if (refuse) {
        request.response.statusCode = 503;
        await request.response.close();
        return;
      }
      headers.add(request.headers);
      final ws = await WebSocketTransformer.upgrade(request);
      accepted++;
      sockets.add(ws);
      ws.add(jsonEncode({'type': 'ready'}));
      ws.listen((raw) {
        final m = (jsonDecode(raw as String) as Map).cast<String, Object?>();
        received.add(m);
        if (m['type'] == 'sync') {
          final r = reply(m);
          if (r != null) ws.add(jsonEncode(r));
        }
      });
    });
  }

  void send(Map<String, Object?> m) => last.add(jsonEncode(m));

  Future<void> dropAll() async {
    for (final s in sockets) {
      await s.close(1011, 'restart');
    }
  }

  Future<void> close() => _http.close(force: true);
}

/// Шарт орындалғанша күту (нақты уақыт).
Future<void> until(bool Function() test, {String? reason}) async {
  final deadline = DateTime.now().add(const Duration(seconds: 5));
  while (!test()) {
    if (DateTime.now().isAfter(deadline)) {
      fail('timeout: ${reason ?? 'condition'}');
    }
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
}

void main() {
  late _WsServer server;
  late LiveChannel live;

  setUp(() async {
    server = _WsServer();
    await server.start();
    live = LiveChannel(
      backoff: (attempt) => Duration(milliseconds: 50 * (attempt + 1)),
      requestTimeout: const Duration(milliseconds: 300),
    );
  });

  tearDown(() async {
    live.dispose();
    await server.close();
  });

  void connect() =>
      live.start(base: server.base, token: 'tok-123', device: 'dev-a');

  test('қосылу: токен мен құрылғы тақырыптарда, күйі live', () async {
    final connected = live.connected.first;
    expect(live.status, LiveStatus.off);
    connect();
    expect(live.status, LiveStatus.connecting);
    await connected;
    expect(live.status, LiveStatus.live);
    expect(server.headers.single.value('authorization'), 'Bearer tok-123');
    expect(server.headers.single.value(HttpSyncApi.deviceHeader), 'dev-a');
  });

  test('сервер «changed» жіберсе — changes оқиғасы келеді', () async {
    connect();
    await live.connected.first;
    final changed = live.changes.first;
    server.send({'type': 'changed'});
    await changed.timeout(const Duration(seconds: 2));
  });

  test('синхрондау сокет арқылы: id сәйкес жауап қайтады', () async {
    connect();
    await live.connected.first;
    final result = await live.sync({'topics': [], 'n': 1});
    expect(server.received.single['type'], 'sync');
    expect(result['echo'], {'topics': [], 'n': 1});
  });

  test('сервер қатесі SyncApiException-ға айналады', () async {
    server.reply = (m) => {
      'type': 'error',
      'id': m['id'],
      'status': 400,
      'error': 'invalid_request',
      'message': 'bad body',
    };
    connect();
    await live.connected.first;
    await expectLater(
      live.sync({}),
      throwsA(
        isA<SyncApiException>().having(
          (e) => e.failure,
          'failure',
          SyncFailure.invalidRequest,
        ),
      ),
    );
  });

  test('live жоқ не жауап жоқ — LiveUnavailable (HTTP-ге көшу)', () async {
    await expectLater(live.sync({}), throwsA(isA<LiveUnavailable>()));
    server.reply = (_) => null;
    connect();
    await live.connected.first;
    await expectLater(
      live.sync({}),
      throwsA(
        isA<LiveUnavailable>().having((e) => e.reason, 'reason', 'timeout'),
      ),
    );
  });

  test('үзілу → waiting + retryAt → өздігінен қайта қосылады', () async {
    connect();
    await live.connected.first;
    final reconnected = live.connected.first;
    await server.dropAll();
    await until(() => live.status == LiveStatus.waiting, reason: 'waiting');
    expect(live.retryAt, isNotNull);
    await reconnected.timeout(const Duration(seconds: 2));
    expect(live.status, LiveStatus.live);
    expect(server.accepted, 2);
  });

  test('сервер құласа — кідіріс өседі; retryNow бірден қосады', () async {
    final delays = <Duration>[];
    live.dispose();
    live = LiveChannel(
      backoff: (attempt) {
        final d = Duration(seconds: 30 + attempt); // ұзақ: тек retryNow
        delays.add(d);
        return d;
      },
    );
    server.refuse = true;
    connect();
    await until(() => live.status == LiveStatus.waiting, reason: 'waiting');
    expect(delays, [const Duration(seconds: 30)]);
    live.retryNow();
    await until(() => delays.length == 2, reason: 'second failure');
    expect(delays.last, const Duration(seconds: 31));
    expect(live.status, LiveStatus.waiting);

    server.refuse = false;
    final connected = live.connected.first;
    live.retryNow();
    await connected.timeout(const Duration(seconds: 2));
    expect(live.status, LiveStatus.live);
    // Қосылғаннан кейін санақ басынан басталады.
    await server.dropAll();
    await until(() => delays.length == 3, reason: 'third failure');
    expect(delays.last, const Duration(seconds: 30));
  });

  test('4401 (токен қайтарылды) — қайта қосылмайды, unauthorized', () async {
    connect();
    await live.connected.first;
    final rejected = live.unauthorized.first;
    await server.last.close(LiveChannel.unauthorizedCode, 'unauthorized');
    await rejected.timeout(const Duration(seconds: 2));
    expect(live.status, LiveStatus.off);
    await Future<void>.delayed(const Duration(milliseconds: 300));
    expect(server.accepted, 1);
  });

  test('stop: байланыс жабылады, қайта қосылмайды', () async {
    connect();
    await live.connected.first;
    live.stop();
    expect(live.status, LiveStatus.off);
    await Future<void>.delayed(const Duration(milliseconds: 200));
    expect(server.accepted, 1);
    expect(live.status, LiveStatus.off);
  });

  test('disabled: start ештеңе ашпайды', () async {
    final off = LiveChannel.disabled();
    addTearDown(off.dispose);
    off.start(base: server.base, token: 't', device: 'd');
    await Future<void>.delayed(const Duration(milliseconds: 100));
    expect(off.status, LiveStatus.off);
    expect(server.accepted, 0);
  });
}
