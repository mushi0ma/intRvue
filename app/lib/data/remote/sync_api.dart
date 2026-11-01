import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'dto.dart';

/// Сервер жауабының түрі — экранда тиісті мәтінге айналады.
enum SyncFailure {
  /// Желі жоқ немесе сервер қосылымды қабылдамады.
  offline,

  /// Сервер [HttpSyncApi.timeout] ішінде жауап бермеді.
  timeout,
  unauthorized,
  invalidCredentials,
  emailTaken,
  weakPassword,
  rateLimited,

  /// 404: жазба серверде жоқ (мысалы, басқа құрылғыда жойылған).
  notFound,

  /// 409: осындай атаулы тақырып серверде бар.
  titleTaken,

  /// 409: осындай id-мен жазба бар.
  conflict,

  /// 400: сервер деректі қабылдамады.
  invalidRequest,

  /// 5xx, бұзылған жауап немесе күтпеген қате.
  server,
}

class SyncApiException implements Exception {
  const SyncApiException(this.failure, [this.detail]);

  final SyncFailure failure;
  final String? detail;

  @override
  String toString() => 'SyncApiException($failure, $detail)';
}

/// Серверде тіркелу немесе кіру нәтижесі.
class RemoteSession {
  const RemoteSession(this.token, this.account);

  final String token;

  /// `{id, email, name, direction, level, interview_language, created_at}`
  final Map<String, Object?> account;
}

/// intRvue серверінің REST API-і (server/ бумасы, PostgreSQL).
abstract interface class SyncApi {
  Uri get baseUrl;

  Future<RemoteSession> register({
    required String email,
    required String password,
    required Map<String, Object?> profile,
  });

  Future<RemoteSession> login(String email, String password);

  /// Суретті жіберіп, біріктірілген толық суретті алады.
  Future<Map<String, Object?>> sync(String token, Map<String, Object?> body);

  Future<void> logout(String token);

  Future<void> deleteAccount(String token);

  // ------------------------------------------------ Ресурстар (практикалық №5)

  /// `GET /v1/account`
  Future<AccountDto> account(String token);

  /// `GET /v1/topics`
  Future<List<TopicDto>> topics(String token);

  /// `GET /v1/topics/{id}`
  Future<TopicDto> topic(String token, String id);

  /// `POST /v1/topics` → 201
  Future<TopicDto> createTopic(String token, TopicDto topic);

  /// `PATCH /v1/topics/{id}`: тек [changes] ішіндегі өрістер.
  Future<TopicDto> updateTopic(
    String token,
    String id,
    Map<String, Object?> changes,
  );

  /// `DELETE /v1/topics/{id}` → 204
  Future<void> deleteTopic(String token, String id);
}

/// HTTP күйі мен сервердің қате коды → [SyncFailure].
SyncFailure failureFor(int status, Object? code) => switch ((status, code)) {
  (401, 'invalid_credentials') => SyncFailure.invalidCredentials,
  (401, _) => SyncFailure.unauthorized,
  (404, _) => SyncFailure.notFound,
  (409, 'email_taken') => SyncFailure.emailTaken,
  (409, 'title_taken') => SyncFailure.titleTaken,
  (409, _) => SyncFailure.conflict,
  (400, 'weak_password') => SyncFailure.weakPassword,
  (400 || 413, _) => SyncFailure.invalidRequest,
  (429, _) => SyncFailure.rateLimited,
  _ => SyncFailure.server,
};

class HttpSyncApi implements SyncApi {
  HttpSyncApi(this.baseUrl, {http.Client? client, this.timeout = _timeout})
    : _client = client ?? http.Client();

  /// Эмулятордан компьютердегі серверге: 10.0.2.2. Басқа мекенжай:
  /// `flutter run --dart-define=INTRVUE_API=http://192.168.1.10:8787`
  static const defaultUrl = String.fromEnvironment(
    'INTRVUE_API',
    defaultValue: 'http://10.0.2.2:8787',
  );
  static const _timeout = Duration(seconds: 8);

  @override
  final Uri baseUrl;
  final Duration timeout;
  final http.Client _client;

  @override
  Future<RemoteSession> register({
    required String email,
    required String password,
    required Map<String, Object?> profile,
  }) async => _session(
    await _send('POST', '/v1/auth/register', {
      ...profile,
      'email': email,
      'password': password,
    }),
  );

  @override
  Future<RemoteSession> login(String email, String password) async => _session(
    await _send('POST', '/v1/auth/login', {
      'email': email,
      'password': password,
    }),
  );

  @override
  Future<Map<String, Object?>> sync(
    String token,
    Map<String, Object?> body,
  ) async => (await _send('POST', '/v1/sync', body, token: token))!;

  @override
  Future<void> logout(String token) =>
      _send('POST', '/v1/auth/logout', null, token: token);

  @override
  Future<void> deleteAccount(String token) =>
      _send('DELETE', '/v1/account', null, token: token);

  @override
  Future<AccountDto> account(String token) async => _parse(
    await _send('GET', '/v1/account', null, token: token),
    AccountDto.fromJson,
  );

  @override
  Future<List<TopicDto>> topics(String token) async =>
      _parse(await _send('GET', '/v1/topics', null, token: token), (json) {
        final list = json['topics'];
        if (list is! List) throw const FormatException('"topics" is missing');
        return [
          for (final t in list)
            TopicDto.fromJson((t as Map).cast<String, Object?>()),
        ];
      });

  @override
  Future<TopicDto> topic(String token, String id) async => _parse(
    await _send('GET', _topicPath(id), null, token: token),
    TopicDto.fromJson,
  );

  @override
  Future<TopicDto> createTopic(String token, TopicDto topic) async => _parse(
    await _send('POST', '/v1/topics', topic.toJson(), token: token),
    TopicDto.fromJson,
  );

  @override
  Future<TopicDto> updateTopic(
    String token,
    String id,
    Map<String, Object?> changes,
  ) async => _parse(
    await _send('PATCH', _topicPath(id), changes, token: token),
    TopicDto.fromJson,
  );

  @override
  Future<void> deleteTopic(String token, String id) =>
      _send('DELETE', _topicPath(id), null, token: token);

  static String _topicPath(String id) =>
      '/v1/topics/${Uri.encodeComponent(id)}';

  /// JSON → модель. Пішімі күткендей болмаса — сервер қатесі.
  static T _parse<T>(
    Map<String, Object?>? json,
    T Function(Map<String, Object?>) fromJson,
  ) {
    if (json == null) {
      throw const SyncApiException(SyncFailure.server, 'empty body');
    }
    try {
      return fromJson(json);
    } on FormatException catch (e) {
      throw SyncApiException(SyncFailure.server, 'bad response: ${e.message}');
    } on TypeError catch (e) {
      throw SyncApiException(SyncFailure.server, 'bad response: $e');
    }
  }

  static RemoteSession _session(Map<String, Object?>? body) => _parse(
    body,
    (json) => RemoteSession(
      json['token']! as String,
      (json['account']! as Map).cast<String, Object?>(),
    ),
  );

  Future<Map<String, Object?>?> _send(
    String method,
    String path,
    Map<String, Object?>? body, {
    String? token,
  }) async {
    final request = http.Request(method, baseUrl.resolve(path))
      ..headers['accept'] = 'application/json';
    if (token != null) request.headers['authorization'] = 'Bearer $token';
    if (body != null) {
      request.headers['content-type'] = 'application/json; charset=utf-8';
      request.body = jsonEncode(body);
    }
    final http.Response response;
    try {
      response = await http.Response.fromStream(
        await _client.send(request).timeout(timeout),
      ).timeout(timeout);
    } on SocketException catch (e) {
      throw SyncApiException(SyncFailure.offline, e.message);
    } on TimeoutException {
      throw SyncApiException(SyncFailure.timeout, '$method $path');
    } on http.ClientException catch (e) {
      throw SyncApiException(SyncFailure.offline, e.message);
    } on IOException catch (e) {
      // TLS, HTTP хаттамасының қателері және т.б.
      throw SyncApiException(SyncFailure.offline, '$e');
    }

    Map<String, Object?>? json;
    try {
      final decoded = response.body.isEmpty ? null : jsonDecode(response.body);
      json = (decoded as Map?)?.cast<String, Object?>();
    } on FormatException {
      throw SyncApiException(SyncFailure.server, 'HTTP ${response.statusCode}');
    }
    if (response.statusCode < 300) return json;
    final code = json?['error'];
    throw SyncApiException(
      failureFor(response.statusCode, code),
      json?['message'] as String?,
    );
  }
}
