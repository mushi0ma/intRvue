import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/log.dart';
import '../local/app_database.dart';
import '../local/db_errors.dart';
import '../local/sync_store.dart';
import '../models/enums.dart';
import '../models/user_profile.dart';
import '../remote/live_channel.dart';
import '../remote/sync_api.dart';
import 'auth_repository.dart';
import 'user_scoped.dart';

/// Құрылғыдағы аккаунттың серверлік аккаунтпен байланысы.
class SyncLink {
  const SyncLink({required this.email, required this.token, this.lastSyncAt});

  factory SyncLink.fromJson(Map<String, Object?> j) => SyncLink(
    email: j['email']! as String,
    token: j['token']! as String,
    lastSyncAt: j['lastSyncAt'] == null
        ? null
        : DateTime.fromMillisecondsSinceEpoch(j['lastSyncAt']! as int),
  );

  final String email;
  final String token;
  final DateTime? lastSyncAt;

  SyncLink synced(DateTime at) =>
      SyncLink(email: email, token: token, lastSyncAt: at);

  Map<String, Object?> toJson() => {
    'email': email,
    'token': token,
    'lastSyncAt': lastSyncAt?.millisecondsSinceEpoch,
  };
}

/// Басқа құрылғыдан келген өзгерістер (снекбар үшін).
class RemoteUpdate {
  const RemoteUpdate({this.sessions = 0, this.topics = 0});
  final int sessions;
  final int topics;
  bool get isEmpty => sessions == 0 && topics == 0;

  /// Жергілікті сурет пен біріктірілген сурет арасындағы жаңа, өзгерген
  /// және басқа құрылғыда жойылған сессиялар мен тақырыптар. Біз жіберген
  /// жазбалар біріктірілген суретте бар, сондықтан жоғалғаны — жойылғаны.
  ///
  /// [ownTopics] — осы құрылғы REST арқылы жіберген тақырыптар: id →
  /// сервер қойған `updated_at` (мс), жойылғаны — null. Сервер уақыты
  /// жергіліктіден жаңа болғанымен, бұл өзгеріс басқа құрылғыдан емес.
  static RemoteUpdate between(
    Map<String, Object?> local,
    Map<String, Object?> merged, {
    Map<String, int?> ownTopics = const {},
  }) {
    int changed(String key, Map<String, int?> own) {
      final before = {
        for (final r in (local[key] as List? ?? const []).cast<Map>())
          r['id']: r['updated_at'],
      };
      final after = (merged[key] as List? ?? const []).cast<Map>();
      final changed = after.where((r) {
        final id = r['id'];
        if (before[id] == r['updated_at']) return false;
        return !(own.containsKey(id) && own[id] == r['updated_at']);
      }).length;
      final kept = {for (final r in after) r['id']};
      final removed = before.keys.where(
        (id) => !kept.contains(id) && !(own.containsKey(id) && own[id] == null),
      );
      return changed + removed.length;
    }

    return RemoteUpdate(
      sessions: changed('sessions', const {}),
      topics: changed('topics', ownTopics),
    );
  }
}

/// Бұлттық көшірме: SQLite негізгі қор болып қалады (офлайн толық жұмыс
/// істейді), сервер — қосымша көшірме және басқа құрылғымен ортақтасу.
///
/// Синхрондау: қолмен, кіргенде және деректер өзгергеннен кейін.
/// Live (WebSocket, практикалық №7) ашық болса — өзгеріс [liveSyncDelay]
/// ішінде сокет арқылы кетеді, басқа құрылғыдағы өзгеріс бірден келеді.
/// Live жоқ болса — HTTP, [autoSyncDelay] кейін. Желі болмаса, үнсіз
/// келесі ретке қалдырылады; live өзі қайта қосылып, қуып жетеді.
class SyncRepository extends ChangeNotifier {
  SyncRepository({
    required this._prefs,
    required AppDatabase database,
    required AuthRepository auth,
    required this._scoped,
    List<Listenable> watch = const [],
    SyncApi Function(Uri baseUrl)? api,
    LiveChannel? live,
    String? deviceId,
  }) : _fixedDevice = deviceId,
       _store = SyncStore(database),
       _auth = auth,
       _watch = watch,
       _apiFactory = api,
       // Басқа транспорт берілсе (тесттер) — live тек анық берілгенде.
       live = live ?? (api == null ? LiveChannel() : LiveChannel.disabled()) {
    _userId = auth.user?.id;
    auth.addListener(_onAuthChanged);
    for (final l in watch) {
      l.addListener(_onDataChanged);
    }
    _liveSubs = [
      this.live.changes.listen((_) => unawaited(syncNow())),
      // (Қайта) қосылды: үзіліс кезіндегі өзгерістерді қуып жету.
      this.live.connected.listen((_) => unawaited(syncNow())),
      // Токен қабылданбады: HTTP 401 байланысты өшіреді («Сеанс ескірді»).
      this.live.unauthorized.listen((_) => unawaited(syncNow())),
    ];
    _updateLive();
  }

  static const autoSyncDelay = Duration(seconds: 20);
  static const liveSyncDelay = Duration(seconds: 1);
  static const _serverKey = 'sync.serverUrl';
  static const _deviceKey = 'sync.deviceId';
  static String _linkKey(int userId) => 'sync.link.$userId';

  final SharedPreferences _prefs;
  final SyncStore _store;
  final AuthRepository _auth;
  final List<UserScoped> _scoped;
  final List<Listenable> _watch;
  final SyncApi Function(Uri)? _apiFactory;

  final String? _fixedDevice;

  /// WebSocket байланысы.
  final LiveChannel live;
  late final List<StreamSubscription<void>> _liveSubs;
  final _remoteUpdates = StreamController<RemoteUpdate>.broadcast();

  /// Басқа құрылғыдан жаңа не өзгерген деректер келді.
  Stream<RemoteUpdate> get remoteUpdates => _remoteUpdates.stream;

  /// Құрылғының тұрақты белгісі: сервер «changed»-ті өзіне қайтармайды.
  String get deviceId {
    if (_fixedDevice != null) return _fixedDevice;
    final saved = _prefs.getString(_deviceKey);
    if (saved != null) return saved;
    final r = Random.secure();
    final id = List.generate(16, (_) => r.nextInt(16).toRadixString(16)).join();
    unawaited(_prefs.setString(_deviceKey, id));
    return id;
  }

  /// REST арқылы осы құрылғыдан жіберілген тақырыптар ([RemoteUpdate.between]).
  final _ownTopics = <String, int?>{};

  /// Тақырыпты осы құрылғы REST арқылы жіберді (не жойды: [serverUpdatedAt]
  /// null). Келесі синхрондауда ол «басқа құрылғыдан келді» деп саналмайды.
  void markOwnTopic(String id, DateTime? serverUpdatedAt) =>
      _ownTopics[id] = serverUpdatedAt?.millisecondsSinceEpoch;

  int? _userId;
  Future<SyncFailure?>? _running;
  Future<SyncFailure?>? _queued;
  Timer? _autoTimer;
  bool _applying = false;
  SyncFailure? _lastFailure;

  bool get syncing => _running != null;
  SyncFailure? get lastFailure => _lastFailure;

  Uri get serverUrl =>
      Uri.parse(_prefs.getString(_serverKey) ?? HttpSyncApi.defaultUrl);

  SyncApi get _api =>
      _apiFactory?.call(serverUrl) ??
      HttpSyncApi(serverUrl, deviceId: deviceId);

  /// Байланыс бар болса — live ашық, жоқ болса — жабық.
  void _updateLive() {
    if (_disposed) return;
    final current = link;
    if (_userId == null || current == null) {
      live.stop();
    } else {
      live.start(base: serverUrl, token: current.token, device: deviceId);
    }
  }

  /// REST клиенті ағымдағы сервер мекенжайымен.
  SyncApi get api => _api;

  /// Сервер токенді қабылдамады (401) — қайта қосу керек.
  Future<void> invalidateLink() async {
    final uid = _userId;
    if (uid == null || link == null) return;
    await _saveLink(uid, null);
    notifyListeners();
  }

  Future<void> setServerUrl(Uri url) async {
    await _prefs.setString(_serverKey, url.toString());
    _updateLive();
    notifyListeners();
  }

  /// Ағымдағы пайдаланушы серверге қосылған болса — байланыс.
  SyncLink? get link {
    final id = _userId;
    final raw = id == null ? null : _prefs.getString(_linkKey(id));
    if (raw == null) return null;
    try {
      return SyncLink.fromJson((jsonDecode(raw) as Map).cast());
    } on Object {
      return null;
    }
  }

  Future<void> _saveLink(int userId, SyncLink? link) async {
    if (link == null) {
      await _prefs.remove(_linkKey(userId));
    } else {
      await _prefs.setString(_linkKey(userId), jsonEncode(link.toJson()));
    }
    _updateLive();
  }

  /// Қосу: серверде аккаунт болмаса — тіркеледі, болса — кіреді.
  Future<SyncFailure?> connect(String password) async {
    final user = _auth.user;
    if (user == null) return SyncFailure.unauthorized;
    final api = _api;
    RemoteSession session;
    try {
      try {
        session = await api.register(
          email: user.email,
          password: password,
          profile: _profileJson(user),
        );
      } on SyncApiException catch (e) {
        if (e.failure != SyncFailure.emailTaken) rethrow;
        session = await api.login(user.email, password);
      }
    } on SyncApiException catch (e) {
      _lastFailure = e.failure;
      notifyListeners();
      return e.failure;
    }
    await _saveLink(
      user.id!,
      SyncLink(email: user.email, token: session.token),
    );
    _lastFailure = null;
    notifyListeners();
    return syncNow();
  }

  /// Қазір синхрондау. Синхрондау жүріп жатса, келесісі кезекке қойылады:
  /// жүріп жатқан сұрау соңғы өзгерістерді көрмеген болуы мүмкін.
  Future<SyncFailure?> syncNow() {
    _autoTimer?.cancel();
    final running = _running;
    if (running != null) {
      return _queued ??= running.then((_) {
        _queued = null;
        return syncNow();
      });
    }
    return _running = _sync().whenComplete(() {
      _running = null;
      notifyListeners();
    });
  }

  Future<SyncFailure?> _sync() async {
    final user = _auth.user;
    final current = link;
    if (user == null || current == null) return null;
    final uid = user.id!;
    notifyListeners();
    final started = DateTime.now();
    try {
      final body = await _store.export(uid);
      body['profile'] = _profileJson(user);
      final merged = await _send(current.token, body);
      // Осы аралықта пайдаланушы ауысса — нәтижені жазбаймыз.
      if (_auth.user?.id != uid) return null;
      _applying = true;
      try {
        await _store.apply(uid, merged);
        await _store.clearDeletions(uid, started.millisecondsSinceEpoch);
        for (final repo in _scoped) {
          await repo.loadFor(user);
        }
      } finally {
        _applying = false;
      }
      await _saveLink(uid, current.synced(DateTime.now()));
      _lastFailure = null;
      final own = Map.of(_ownTopics);
      final update = RemoteUpdate.between(body, merged, ownTopics: own);
      // Суретте көрінген нұсқалар енді керек емес.
      final present = {
        for (final r in (merged['topics'] as List? ?? const []).cast<Map>())
          r['id']: r['updated_at'],
      };
      own.forEach((id, at) {
        final seen = at == null ? !present.containsKey(id) : present[id] == at;
        if (seen) _ownTopics.remove(id);
      });
      if (!update.isEmpty) {
        Log.info(
          'sync',
          'received ${update.sessions} sessions, ${update.topics} topics',
        );
        _remoteUpdates.add(update);
      }
      return null;
    } on SyncApiException catch (e) {
      // Токен ескірсе — қайта қосу керек.
      if (e.failure == SyncFailure.unauthorized) await _saveLink(uid, null);
      _lastFailure = e.failure;
      return e.failure;
    } on AppException catch (e) {
      Log.error('sync', 'failed', e);
      _lastFailure = SyncFailure.server;
      return SyncFailure.server;
    } on Object catch (e) {
      Log.error('sync', 'failed', e);
      _lastFailure = SyncFailure.server;
      return SyncFailure.server;
    }
  }

  /// Live ашық болса — сокет арқылы, әйтпесе (не сокет үзілсе) — HTTP.
  Future<Map<String, Object?>> _send(
    String token,
    Map<String, Object?> body,
  ) async {
    if (live.isLive) {
      try {
        return await live.sync(body);
      } on LiveUnavailable catch (e) {
        Log.warn('sync', 'live unavailable (${e.reason}), using HTTP');
      }
    }
    return _api.sync(token, body);
  }

  /// Ажырату: құрылғыдағы деректер мен сервердегі көшірме қалады.
  Future<void> disconnect() async {
    final current = link;
    final uid = _userId;
    if (current == null || uid == null) return;
    _autoTimer?.cancel();
    await _saveLink(uid, null);
    _lastFailure = null;
    notifyListeners();
    try {
      await _api.logout(current.token);
    } on SyncApiException {
      // Желі жоқ — токен 30 күннен кейін өзі ескіреді.
    }
  }

  /// Жаңа құрылғыда (немесе қайта орнатқаннан кейін) кіру: құрылғыда
  /// аккаунт жоқ, бірақ серверде бар болса — профиль мен деректерді
  /// қалпына келтіреді. Сервер қолжетімсіз болса — false.
  Future<bool> restore(String email, String password) async {
    final RemoteSession session;
    try {
      session = await _api.login(email.trim(), password);
    } on SyncApiException {
      return false;
    }
    final a = session.account;
    final profile = UserProfile(
      name: a['name']! as String,
      email: a['email']! as String,
      direction:
          Direction.values.asNameMap()[a['direction']] ?? Direction.mobile,
      level: Level.values.asNameMap()[a['level']] ?? Level.beginner,
      interviewLanguage:
          InterviewLanguage.values.asNameMap()[a['interview_language']] ??
          InterviewLanguage.kk,
    );
    final user = await _auth.adoptRemote(profile, password);
    await _saveLink(
      user.id!,
      SyncLink(email: user.email, token: session.token),
    );
    notifyListeners();
    await syncNow();
    return true;
  }

  /// Аккаунтты жоярда сервердегі көшірмені де жою.
  Future<SyncFailure?> deleteRemote() async {
    final current = link;
    final uid = _userId;
    if (current == null || uid == null) return null;
    try {
      await _api.deleteAccount(current.token);
    } on SyncApiException catch (e) {
      if (e.failure != SyncFailure.unauthorized) return e.failure;
    }
    await _saveLink(uid, null);
    return null;
  }

  void _onAuthChanged() {
    final id = _auth.user?.id;
    if (id == _userId) return;
    _userId = id;
    _autoTimer?.cancel();
    _lastFailure = null;
    _ownTopics.clear();
    _updateLive();
    notifyListeners();
    if (link != null) unawaited(syncNow());
  }

  void _onDataChanged() {
    if (_applying || link == null) return;
    _autoTimer?.cancel();
    // Live ашық: өзгеріс бірден кетеді (бірнеше жазуды бір рет жібереміз).
    _autoTimer = Timer(live.isLive ? liveSyncDelay : autoSyncDelay, syncNow);
  }

  static Map<String, Object?> _profileJson(UserProfile u) => {
    'name': u.name,
    'direction': u.direction.name,
    'level': u.level.name,
    'interview_language': u.interviewLanguage.name,
  };

  bool _disposed = false;

  /// Сұрау экран жабылғаннан (немесе қосымша тоқтағаннан) кейін аяқталса,
  /// жойылған объектіге хабар жібермейміз.
  @override
  void notifyListeners() {
    if (!_disposed) super.notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _autoTimer?.cancel();
    for (final sub in _liveSubs) {
      unawaited(sub.cancel());
    }
    live.dispose();
    unawaited(_remoteUpdates.close());
    _auth.removeListener(_onAuthChanged);
    for (final l in _watch) {
      l.removeListener(_onDataChanged);
    }
    super.dispose();
  }
}
