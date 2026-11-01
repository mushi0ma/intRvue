import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:postgres/postgres.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:shelf_web_socket/shelf_web_socket.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'auth_service.dart';
import 'errors.dart';
import 'live_hub.dart';
import 'passwords.dart';
import 'sync_service.dart';
import 'topics_service.dart';

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
/// | GET    | /v1/topics        | пайдаланушы тақырыптарының тізімі |
/// | GET    | /v1/topics/{id}   | бір тақырып сұрақтарымен          |
/// | POST   | /v1/topics        | жаңа тақырып → 201 + Location     |
/// | PATCH  | /v1/topics/{id}   | тақырыпты ішінара өзгерту         |
/// | DELETE | /v1/topics/{id}   | тақырыпты жою → 204               |
/// | GET    | /v1/live          | WebSocket: синхрондау + «changed» |
///
/// `X-Intrvue-Device` тақырыбы құрылғыны атайды: деректер өзгергенде
/// `changed` хабарламасы өзгерісті жіберген құрылғыға қайтарылмайды.
class Api {
  Api(this._db, {Passwords? passwords, LoginLimiter? limiter, LiveHub? live})
    : _auth = AuthService(_db, passwords: passwords),
      _sync = SyncService(_db),
      _topics = TopicsService(_db),
      _limiter = limiter ?? LoginLimiter(),
      live = live ?? LiveHub();

  final Pool _db;
  final AuthService _auth;
  final SyncService _sync;
  final TopicsService _topics;
  final LoginLimiter _limiter;
  final LiveHub live;

  static const deviceHeader = 'x-intrvue-device';
  static const livePing = Duration(seconds: 20);

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
      final token = r.headers['authorization']!.substring(7).trim();
      await _auth.logout(token);
      final hash = AuthService.hashToken(token);
      live.closeWhere((c) => c.tokenHash == hash);
      return Response(204);
    })
    ..get('/v1/account', (Request r) async {
      final id = await _auth.authenticate(r.headers['authorization']);
      return _json(200, await _auth.account(id));
    })
    ..delete('/v1/account', (Request r) async {
      final id = await _auth.authenticate(r.headers['authorization']);
      await _auth.deleteAccount(id);
      live
        ..closeWhere((c) => c.account == id)
        ..forget(id);
      return Response(204);
    })
    ..post('/v1/sync', (Request r) async {
      final id = await _auth.authenticate(r.headers['authorization']);
      final snapshot = await _sync.sync(id, await _body(r));
      live.publish(
        id,
        LiveHub.fingerprint(snapshot),
        except: r.headers[deviceHeader],
      );
      return _json(200, snapshot);
    })
    ..get('/v1/live', (Request r) async {
      // Токен upgrade-ке дейін тексеріледі: жарамсыз болса — кәдімгі 401.
      final header = r.headers['authorization'];
      final id = await _auth.authenticate(header);
      final device = r.headers[deviceHeader];
      final tokenHash = AuthService.hashToken(header!.substring(7).trim());
      return webSocketHandler(
        (WebSocketChannel channel, _) => _serveLive(
          LiveClient(
            account: id,
            device: device,
            tokenHash: tokenHash,
            channel: channel,
          ),
        ),
        pingInterval: livePing,
      )(r);
    })
    ..get('/v1/topics', (Request r) async {
      final id = await _auth.authenticate(r.headers['authorization']);
      return _json(200, {'topics': await _topics.list(id)});
    })
    ..get('/v1/topics/<topic>', (Request r, String topic) async {
      final id = await _auth.authenticate(r.headers['authorization']);
      return _json(200, await _topics.get(id, topic));
    })
    ..post('/v1/topics', (Request r) async {
      final id = await _auth.authenticate(r.headers['authorization']);
      final created = await _topics.create(id, await _body(r));
      await _changed(id, r);
      return _json(
        201,
        created,
        headers: {
          'location': '/v1/topics/${Uri.encodeComponent('${created['id']}')}',
        },
      );
    })
    ..patch('/v1/topics/<topic>', (Request r, String topic) async {
      final id = await _auth.authenticate(r.headers['authorization']);
      final updated = await _topics.update(id, topic, await _body(r));
      await _changed(id, r);
      return _json(200, updated);
    })
    ..delete('/v1/topics/<topic>', (Request r, String topic) async {
      final id = await _auth.authenticate(r.headers['authorization']);
      await _topics.delete(id, topic);
      await _changed(id, r);
      return Response(204);
    })
    ..all('/<ignored|.*>', (Request r) {
      throw const ApiError(404, 'not_found', 'Unknown endpoint.');
    });

  /// REST арқылы өзгергеннен кейін басқа құрылғыларға хабарлау.
  Future<void> _changed(int account, Request r) async {
    final snapshot = await _db.runTx((tx) => _sync.snapshot(tx, account));
    live.publish(
      account,
      LiveHub.fingerprint(snapshot),
      except: r.headers[deviceHeader],
    );
  }

  /// Бір WebSocket байланысы. Клиент → сервер:
  ///   {"type":"ping"}                         → {"type":"pong"}
  ///   {"type":"sync","id":n,"body":{…}}       → {"type":"synced","id":n,"snapshot":{…}}
  /// Сервер → клиент: {"type":"ready"}, {"type":"changed"},
  ///   {"type":"error","id":n,"error":"…","message":"…"}.
  void _serveLive(LiveClient client) {
    live.add(client);
    stdout.writeln(
      'live: account ${client.account} connected '
      '(${live.connections(client.account)} open)',
    );
    client.send({'type': 'ready'});
    client.channel.stream.listen(
      (raw) => _onLiveMessage(client, raw),
      onDone: () {
        live.remove(client);
        stdout.writeln('live: account ${client.account} disconnected');
      },
      onError: (Object e) => live.remove(client),
      cancelOnError: true,
    );
  }

  Future<void> _onLiveMessage(LiveClient client, Object? raw) async {
    Object? id;
    try {
      final message = raw is String ? jsonDecode(raw) : null;
      if (message is! Map<String, Object?>) {
        throw const ApiError.badRequest('Message must be a JSON object.');
      }
      id = message['id'];
      switch (message['type']) {
        case 'ping':
          client.send({'type': 'pong'});
        case 'sync':
          final body = message['body'];
          if (body is! Map<String, Object?>) {
            throw const ApiError.badRequest('"body" must be an object.');
          }
          final snapshot = await _sync.sync(client.account, body);
          client.send({'type': 'synced', 'id': id, 'snapshot': snapshot});
          live.publish(
            client.account,
            LiveHub.fingerprint(snapshot),
            except: client.device,
          );
        default:
          throw const ApiError.badRequest('Unknown message type.');
      }
    } on ApiError catch (e) {
      // status — HTTP-дегідей: клиент қатені бір кесте бойынша түсіндіреді.
      client.send({
        'type': 'error',
        'id': id,
        'status': e.status,
        ...e.toJson(),
      });
    } on FormatException {
      client.send({
        'type': 'error',
        'id': id,
        'status': 400,
        'error': 'invalid_request',
        'message': 'Invalid JSON.',
      });
    } catch (e, stack) {
      stderr.writeln('live: $e\n$stack');
      client.send({
        'type': 'error',
        'id': id,
        'status': 500,
        'error': 'internal',
        'message': 'Server error.',
      });
    }
  }

  static Handler _errors(Handler inner) => (request) async {
    try {
      return await inner(request);
    } on HijackException {
      // WebSocket upgrade: байланысты shelf_web_socket өзі басқарады.
      rethrow;
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

  static Response _json(
    int status,
    Object body, {
    Map<String, String> headers = const {},
  }) => Response(
    status,
    body: jsonEncode(body),
    headers: {'content-type': 'application/json; charset=utf-8', ...headers},
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
