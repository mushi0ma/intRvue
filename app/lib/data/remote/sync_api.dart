import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

/// Сервер жауабының түрі — экранда тиісті мәтінге айналады.
enum SyncFailure {
  offline,
  unauthorized,
  invalidCredentials,
  emailTaken,
  weakPassword,
  rateLimited,
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
}

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

  static RemoteSession _session(Map<String, Object?>? body) => RemoteSession(
    body!['token']! as String,
    (body['account']! as Map).cast<String, Object?>(),
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
      throw const SyncApiException(SyncFailure.offline, 'timeout');
    } on http.ClientException catch (e) {
      throw SyncApiException(SyncFailure.offline, e.message);
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
    throw SyncApiException(switch ((response.statusCode, code)) {
      (401, 'invalid_credentials') => SyncFailure.invalidCredentials,
      (401, _) => SyncFailure.unauthorized,
      (409, _) => SyncFailure.emailTaken,
      (400, 'weak_password') => SyncFailure.weakPassword,
      (429, _) => SyncFailure.rateLimited,
      _ => SyncFailure.server,
    }, json?['message'] as String?);
  }
}
