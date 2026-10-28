import 'package:intrvue/data/remote/sync_api.dart';

/// Желісіз тесттерге арналған сервер: суретті сол күйінде қайтарады,
/// [accounts] ішіндегі email-дер «серверде бар» деп саналады.
class FakeSyncApi implements SyncApi {
  FakeSyncApi({this.failure, this.accounts = const {}, this.remote});

  /// Берілсе — әр сұрау осы қатемен аяқталады.
  final SyncFailure? failure;

  /// email → пароль.
  final Map<String, String> accounts;

  /// Қалпына келтіргенде сервер қайтаратын сурет.
  final Map<String, Object?>? remote;

  final pushed = <Map<String, Object?>>[];

  @override
  Uri get baseUrl => Uri.parse('http://fake.local');

  void _check() {
    if (failure != null) throw SyncApiException(failure!);
  }

  Map<String, Object?> _account(String email, [Map<String, Object?>? p]) => {
    'id': 1,
    'email': email,
    'name': p?['name'] ?? 'Ерлан',
    'direction': p?['direction'] ?? 'backend',
    'level': p?['level'] ?? 'junior',
    'interview_language': p?['interview_language'] ?? 'kk',
    'created_at': 0,
  };

  @override
  Future<RemoteSession> register({
    required String email,
    required String password,
    required Map<String, Object?> profile,
  }) async {
    _check();
    if (accounts.containsKey(email)) {
      throw const SyncApiException(SyncFailure.emailTaken);
    }
    return RemoteSession('token-$email', _account(email, profile));
  }

  @override
  Future<RemoteSession> login(String email, String password) async {
    _check();
    if (accounts[email.trim()] != password) {
      throw const SyncApiException(SyncFailure.invalidCredentials);
    }
    return RemoteSession('token-$email', _account(email.trim()));
  }

  @override
  Future<Map<String, Object?>> sync(
    String token,
    Map<String, Object?> body,
  ) async {
    _check();
    pushed.add(body);
    final r = remote;
    return {
      'topics': [...?body['topics'] as List?, ...?r?['topics'] as List?],
      'sessions': [...?body['sessions'] as List?, ...?r?['sessions'] as List?],
      'favorites': [
        ...?body['favorites'] as List?,
        ...?r?['favorites'] as List?,
      ],
      'deleted': const [],
    };
  }

  @override
  Future<void> logout(String token) async => _check();

  @override
  Future<void> deleteAccount(String token) async => _check();
}
