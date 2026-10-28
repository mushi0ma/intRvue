import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:postgres/postgres.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import 'auth_service.dart';
import 'errors.dart';
import 'passwords.dart';
import 'sync_service.dart';

/// REST API. Барлық жауап — JSON, қате — `{"error", "message"}`.
///
/// | Әдіс   | Жол               | Сипаттама                         |
/// |--------|-------------------|-----------------------------------|
/// | GET    | /health           | сервер мен PostgreSQL күйі        |
/// | POST   | /v1/auth/register | тіркелу → токен                   |
/// | POST   | /v1/auth/login    | кіру → токен                      |
/// | POST   | /v1/auth/logout   | токенді қайтарып алу              |
/// | GET    | /v1/account       | профиль                           |
/// | DELETE | /v1/account       | аккаунт пен барлық деректі жою    |
/// | POST   | /v1/sync          | суретті біріктіру → толық сурет   |
class Api {
  Api(this._db, {Passwords? passwords, LoginLimiter? limiter})
    : _auth = AuthService(_db, passwords: passwords),
      _sync = SyncService(_db),
      _limiter = limiter ?? LoginLimiter();

  final Pool _db;
  final AuthService _auth;
  final SyncService _sync;
  final LoginLimiter _limiter;

  static const maxBodyBytes = 4 * 1024 * 1024;

  Handler get handler =>
      const Pipeline().addMiddleware(_errors).addHandler(_router.call);

  Router get _router => Router()
    ..get('/health', (Request r) async {
      await _db.execute('SELECT 1');
      return _json(200, {'status': 'ok'});
    })
    ..post('/v1/auth/register', (Request r) async {
      return _json(201, await _auth.register(await _body(r)));
    })
    ..post('/v1/auth/login', (Request r) async {
      final body = await _body(r);
      final key = '${_clientIp(r)}|${body['email']}'.toLowerCase();
      _limiter.check(key);
      try {
        final result = await _auth.login(body);
        _limiter.reset(key);
        return _json(200, result);
      } on ApiError catch (e) {
        if (e.code == 'invalid_credentials') _limiter.fail(key);
        rethrow;
      }
    })
    ..post('/v1/auth/logout', (Request r) async {
      await _auth.authenticate(r.headers['authorization']);
      await _auth.logout(r.headers['authorization']!.substring(7).trim());
      return Response(204);
    })
    ..get('/v1/account', (Request r) async {
      final id = await _auth.authenticate(r.headers['authorization']);
      return _json(200, await _auth.account(id));
    })
    ..delete('/v1/account', (Request r) async {
      final id = await _auth.authenticate(r.headers['authorization']);
      await _auth.deleteAccount(id);
      return Response(204);
    })
    ..post('/v1/sync', (Request r) async {
      final id = await _auth.authenticate(r.headers['authorization']);
      return _json(200, await _sync.sync(id, await _body(r)));
    })
    ..all('/<ignored|.*>', (Request r) {
      throw const ApiError(404, 'not_found', 'Unknown endpoint.');
    });

  static Handler _errors(Handler inner) => (request) async {
    try {
      return await inner(request);
    } on ApiError catch (e) {
      return _json(e.status, e.toJson());
    } on ServerException catch (e) {
      stderr.writeln('PostgreSQL: ${e.message}');
      return _json(500, {'error': 'internal', 'message': 'Database error.'});
    } catch (e, stack) {
      stderr.writeln('Unhandled: $e\n$stack');
      return _json(500, {'error': 'internal', 'message': 'Server error.'});
    }
  };

  static Future<Map<String, Object?>> _body(Request r) async {
    final length = r.contentLength;
    if (length != null && length > maxBodyBytes) {
      throw const ApiError(413, 'payload_too_large', 'Body is too large.');
    }
    final bytes = <int>[];
    await for (final chunk in r.read()) {
      bytes.addAll(chunk);
      if (bytes.length > maxBodyBytes) {
        throw const ApiError(413, 'payload_too_large', 'Body is too large.');
      }
    }
    try {
      final decoded = jsonDecode(utf8.decode(bytes));
      if (decoded is Map<String, Object?>) return decoded;
    } on FormatException {
      // төменде
    }
    throw const ApiError.badRequest('Body must be a JSON object.');
  }

  static String _clientIp(Request r) {
    final info = r.context['shelf.io.connection_info'];
    return info is HttpConnectionInfo ? info.remoteAddress.address : 'local';
  }

  static Response _json(int status, Object body) => Response(
    status,
    body: jsonEncode(body),
    headers: {'content-type': 'application/json; charset=utf-8'},
  );
}

/// Пароль таңдауынан қорғау: бір IP + email үшін 15 минутта 10 сәтсіз кіру.
class LoginLimiter {
  LoginLimiter({
    this.maxFailures = 10,
    this.window = const Duration(minutes: 15),
  });

  final int maxFailures;
  final Duration window;
  final _failures = <String, List<DateTime>>{};

  void check(String key) {
    final now = DateTime.now();
    final recent = (_failures[key] ?? [])
      ..removeWhere((t) => now.difference(t) > window);
    if (recent.length >= maxFailures) {
      throw const ApiError(
        429,
        'too_many_requests',
        'Too many failed logins. Try again later.',
      );
    }
  }

  void fail(String key) => (_failures[key] ??= []).add(DateTime.now());

  void reset(String key) => _failures.remove(key);
}
