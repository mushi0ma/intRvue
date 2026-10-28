import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../local/app_database.dart';
import '../local/db_errors.dart';
import '../local/sync_store.dart';
import '../models/enums.dart';
import '../models/user_profile.dart';
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

/// Бұлттық көшірме: SQLite негізгі қор болып қалады (офлайн толық жұмыс
/// істейді), сервер — қосымша көшірме және басқа құрылғымен ортақтасу.
///
/// Синхрондау: қолмен, кіргенде және деректер өзгергеннен кейін
/// [autoSyncDelay] өткенде. Желі болмаса, үнсіз келесі ретке қалдырылады.
class SyncRepository extends ChangeNotifier {
  SyncRepository({
    required this._prefs,
    required AppDatabase database,
    required AuthRepository auth,
    required this._scoped,
    List<Listenable> watch = const [],
    SyncApi Function(Uri baseUrl)? api,
  }) : _store = SyncStore(database),
       _auth = auth,
       _watch = watch,
       _apiFactory = api ?? ((url) => HttpSyncApi(url)) {
    _userId = auth.user?.id;
    auth.addListener(_onAuthChanged);
    for (final l in watch) {
      l.addListener(_onDataChanged);
    }
  }

  static const autoSyncDelay = Duration(seconds: 20);
  static const _serverKey = 'sync.serverUrl';
  static String _linkKey(int userId) => 'sync.link.$userId';

  final SharedPreferences _prefs;
  final SyncStore _store;
  final AuthRepository _auth;
  final List<UserScoped> _scoped;
  final List<Listenable> _watch;
  final SyncApi Function(Uri) _apiFactory;

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

  SyncApi get _api => _apiFactory(serverUrl);

  Future<void> setServerUrl(Uri url) async {
    await _prefs.setString(_serverKey, url.toString());
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
      final merged = await _api.sync(current.token, body);
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
      return null;
    } on SyncApiException catch (e) {
      // Токен ескірсе — қайта қосу керек.
      if (e.failure == SyncFailure.unauthorized) await _saveLink(uid, null);
      _lastFailure = e.failure;
      return e.failure;
    } on AppException catch (e) {
      debugPrint('Sync: $e');
      _lastFailure = SyncFailure.server;
      return SyncFailure.server;
    } on Object catch (e) {
      debugPrint('Sync: $e');
      _lastFailure = SyncFailure.server;
      return SyncFailure.server;
    }
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
    notifyListeners();
    if (link != null) unawaited(syncNow());
  }

  void _onDataChanged() {
    if (_applying || link == null) return;
    _autoTimer?.cancel();
    _autoTimer = Timer(autoSyncDelay, syncNow);
  }

  static Map<String, Object?> _profileJson(UserProfile u) => {
    'name': u.name,
    'direction': u.direction.name,
    'level': u.level.name,
    'interview_language': u.interviewLanguage.name,
  };

  @override
  void dispose() {
    _autoTimer?.cancel();
    _auth.removeListener(_onAuthChanged);
    for (final l in _watch) {
      l.removeListener(_onDataChanged);
    }
    super.dispose();
  }
}
