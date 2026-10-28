import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:intrvue_server/intrvue_server.dart';
import 'package:postgres/postgres.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:test/test.dart';

/// Интеграциялық тесттер нақты PostgreSQL-пен: `docker compose up -d db`.
/// Басқа дерекқор: TEST_DATABASE_URL=postgresql://… dart test
void main() {
  final url =
      Platform.environment['TEST_DATABASE_URL'] ??
      'postgresql://intrvue:intrvue_dev@localhost:5433/intrvue_test?sslmode=disable';
  late Pool db;
  late HttpServer server;
  late Uri base;

  setUpAll(() async {
    db = Pool.withUrl(url);
    await db.execute('DROP SCHEMA public CASCADE');
    await db.execute('CREATE SCHEMA public');
    await Schema.migrate(db);
    final api = Api(
      db,
      // Тесттер жылдам болуы үшін итерация аз.
      passwords: const Passwords(iterations: 1000),
      limiter: LoginLimiter(maxFailures: 3),
    );
    server = await io.serve(api.handler, '127.0.0.1', 0);
    base = Uri.parse('http://127.0.0.1:${server.port}');
  });

  tearDownAll(() async {
    await server.close(force: true);
    await db.close();
  });

  setUp(() => db.execute('TRUNCATE accounts CASCADE'));

  Future<(int, Map<String, Object?>)> call(
    String method,
    String path, {
    Object? body,
    String? token,
  }) async {
    final request = http.Request(method, base.resolve(path))
      ..headers['content-type'] = 'application/json';
    if (token != null) request.headers['authorization'] = 'Bearer $token';
    if (body != null) request.body = jsonEncode(body);
    final response = await http.Response.fromStream(await request.send());
    final decoded = response.body.isEmpty ? null : jsonDecode(response.body);
    return (
      response.statusCode,
      (decoded as Map?)?.cast<String, Object?>() ?? {},
    );
  }

  Map<String, Object?> profile(String email) => {
    'name': 'Айдана',
    'email': email,
    'password': 'intrvue2026',
    'direction': 'mobile',
    'level': 'junior',
    'interview_language': 'kk',
  };

  Future<String> register(String email) async {
    final (status, body) = await call(
      'POST',
      '/v1/auth/register',
      body: profile(email),
    );
    expect(status, 201, reason: '$body');
    return body['token']! as String;
  }

  const t0 = 1761700000000; // 2025-10-29

  Map<String, Object?> topic(
    String id,
    int updated, {
    String title = 'Docker',
  }) => {
    'id': id,
    'title': title,
    'summary': 'Контейнерлер',
    'direction': 'backend',
    'level': 'junior',
    'description': 'Сипаттама',
    'review_points': jsonEncode(['Image', 'Volume']),
    'sample_question': 'Image деген не?',
    'created_at': t0,
    'updated_at': updated,
    'questions': [
      {
        'id': '$id-q1',
        'position': 0,
        'text': 'Image мен container айырмашылығы?',
        'hint': '',
        'model_answer': 'Image — үлгі, container — іске қосылған данасы.',
        'concepts': jsonEncode([
          {
            'label': 'Image',
            'keywords': ['image'],
          },
        ]),
      },
    ],
  };

  Map<String, Object?> session(String id, int updated, {int index = 0}) => {
    'id': id,
    'direction': 'backend',
    'level': 'junior',
    'language': 'kk',
    'topic_ids': jsonEncode(['custom-1']),
    'started_at': t0,
    'current_index': index,
    'finished': 0,
    'updated_at': updated,
    'answers': [
      {
        'position': 0,
        'question_id': 'custom-1-q1',
        'text': 'Image — үлгі',
        'status': 'assessed',
        'correctness': 4,
        'completeness': 3,
        'clarity': 5,
        'headline': 'Жақсы',
        'advice': null,
        'evidence': null,
        'missing': jsonEncode(['Layer']),
        'disputed': 0,
        'dispute_reason': null,
        'dispute_comment': null,
        'updated_at': updated,
      },
    ],
  };

  test('health checks PostgreSQL', () async {
    final (status, body) = await call('GET', '/health');
    expect(status, 200);
    expect(body['status'], 'ok');
  });

  group('auth', () {
    test('register, duplicate email, validation', () async {
      await register('aidana@example.com');
      final (dup, dupBody) = await call(
        'POST',
        '/v1/auth/register',
        body: profile('AIDANA@example.com'),
      );
      expect(dup, 409);
      expect(dupBody['error'], 'email_taken');

      final (weak, weakBody) = await call(
        'POST',
        '/v1/auth/register',
        body: {...profile('b@example.com'), 'password': 'short'},
      );
      expect(weak, 400);
      expect(weakBody['error'], 'weak_password');

      final (bad, _) = await call(
        'POST',
        '/v1/auth/register',
        body: {...profile('not-an-email'), 'level': 'senior'},
      );
      expect(bad, 400);
    });

    test('passwords are stored as PBKDF2 hashes', () async {
      await register('aidana@example.com');
      final rows = await db.execute('SELECT password_hash FROM accounts');
      final hash = rows.first.first! as String;
      expect(hash, startsWith(r'pbkdf2-sha256$1000$'));
      expect(hash, isNot(contains('intrvue2026')));
    });

    test('login: same answer for wrong password and unknown email', () async {
      await register('aidana@example.com');
      final (ok, okBody) = await call(
        'POST',
        '/v1/auth/login',
        body: {'email': ' Aidana@Example.com ', 'password': 'intrvue2026'},
      );
      expect(ok, 200);
      expect((okBody['account']! as Map)['email'], 'aidana@example.com');

      final (wrong, wrongBody) = await call(
        'POST',
        '/v1/auth/login',
        body: {'email': 'aidana@example.com', 'password': 'nope12345'},
      );
      final (unknown, unknownBody) = await call(
        'POST',
        '/v1/auth/login',
        body: {'email': 'ghost@example.com', 'password': 'nope12345'},
      );
      expect(wrong, 401);
      expect(unknown, 401);
      expect(wrongBody, unknownBody);
    });

    test('login is rate limited after repeated failures', () async {
      await register('limit@example.com');
      final wrong = {'email': 'limit@example.com', 'password': 'wrong1234'};
      for (var i = 0; i < 3; i++) {
        expect((await call('POST', '/v1/auth/login', body: wrong)).$1, 401);
      }
      final (status, body) = await call('POST', '/v1/auth/login', body: wrong);
      expect(status, 429);
      expect(body['error'], 'too_many_requests');
    });

    test('token is required, logout revokes it', () async {
      expect((await call('POST', '/v1/sync', body: {})).$1, 401);
      expect((await call('GET', '/v1/account', token: 'forged')).$1, 401);

      final token = await register('aidana@example.com');
      expect((await call('GET', '/v1/account', token: token)).$1, 200);
      expect((await call('POST', '/v1/auth/logout', token: token)).$1, 204);
      expect((await call('GET', '/v1/account', token: token)).$1, 401);
    });
  });

  group('sync', () {
    test('push returns the merged snapshot in client row format', () async {
      final token = await register('aidana@example.com');
      final (status, body) = await call(
        'POST',
        '/v1/sync',
        token: token,
        body: {
          'topics': [topic('custom-1', t0)],
          'sessions': [session('s1', t0)],
          'favorites': [
            {'topic_id': 'custom-1', 'created_at': t0},
          ],
        },
      );
      expect(status, 200, reason: '$body');
      final topics = body['topics']! as List;
      expect(topics, hasLength(1));
      final t = topics.first as Map;
      expect(t['updated_at'], t0);
      expect(jsonDecode(t['review_points']! as String), ['Image', 'Volume']);
      expect((t['questions']! as List).single['id'], 'custom-1-q1');

      final s = (body['sessions']! as List).single as Map;
      expect(s['finished'], 0);
      final answer = (s['answers']! as List).single as Map;
      expect(answer['correctness'], 4);
      expect(jsonDecode(answer['missing']! as String), ['Layer']);
      expect((body['favorites']! as List).single['topic_id'], 'custom-1');
      expect(body['server_time'], isA<int>());
    });

    test('newer edit wins, stale edit is ignored', () async {
      final token = await register('aidana@example.com');
      await call(
        'POST',
        '/v1/sync',
        token: token,
        body: {
          'topics': [topic('custom-1', t0 + 2000, title: 'Docker v2')],
        },
      );
      final (_, stale) = await call(
        'POST',
        '/v1/sync',
        token: token,
        body: {
          'topics': [topic('custom-1', t0 + 1000, title: 'Docker v1')],
          'sessions': [session('s1', t0 + 5000, index: 2)],
        },
      );
      expect(((stale['topics']! as List).single as Map)['title'], 'Docker v2');

      final (_, older) = await call(
        'POST',
        '/v1/sync',
        token: token,
        body: {
          'sessions': [session('s1', t0 + 1000, index: 0)],
        },
      );
      final s = (older['sessions']! as List).single as Map;
      expect(s['current_index'], 2);
    });

    test(
      'deletions propagate and are not resurrected by stale devices',
      () async {
        final token = await register('aidana@example.com');
        await call(
          'POST',
          '/v1/sync',
          token: token,
          body: {
            'topics': [topic('custom-1', t0)],
            'sessions': [session('s1', t0)],
            'favorites': [
              {'topic_id': 'custom-1', 'created_at': t0},
            ],
          },
        );
        // Бірінші құрылғы жойды.
        final (_, afterDelete) = await call(
          'POST',
          '/v1/sync',
          token: token,
          body: {
            'deleted': [
              {'entity': 'topic', 'id': 'custom-1', 'deleted_at': t0 + 1000},
              {'entity': 'session', 'id': 's1', 'deleted_at': t0 + 1000},
              {'entity': 'favorite', 'id': 'custom-1', 'deleted_at': t0 + 1000},
            ],
          },
        );
        expect(afterDelete['topics'], isEmpty);
        expect(afterDelete['sessions'], isEmpty);
        expect(afterDelete['favorites'], isEmpty);
        expect(afterDelete['deleted'], hasLength(3));

        // Ескі деректері бар екінші құрылғы.
        final (_, stale) = await call(
          'POST',
          '/v1/sync',
          token: token,
          body: {
            'topics': [topic('custom-1', t0)],
            'sessions': [session('s1', t0 + 9000)],
            'favorites': [
              {'topic_id': 'custom-1', 'created_at': t0},
            ],
          },
        );
        expect(stale['topics'], isEmpty);
        expect(stale['sessions'], isEmpty);
        expect(stale['favorites'], isEmpty);

        // Таңдаулыны жойғаннан кейін қайта қосуға болады.
        final (_, readded) = await call(
          'POST',
          '/v1/sync',
          token: token,
          body: {
            'favorites': [
              {'topic_id': 'custom-1', 'created_at': t0 + 2000},
            ],
          },
        );
        expect(readded['favorites'], hasLength(1));
      },
    );

    test('invalid payload is rejected without partial writes', () async {
      final token = await register('aidana@example.com');
      final broken = topic('custom-2', t0)..['review_points'] = 'not json';
      final (status, body) = await call(
        'POST',
        '/v1/sync',
        token: token,
        body: {
          'topics': [topic('custom-1', t0), broken],
        },
      );
      expect(status, 400);
      expect(body['error'], 'invalid_request');
      final rows = await db.execute('SELECT count(*) FROM topics');
      expect(rows.first.first, 0);
    });

    test('accounts are isolated, deleting an account cascades', () async {
      final a = await register('a@example.com');
      final b = await register('b@example.com');
      await call(
        'POST',
        '/v1/sync',
        token: a,
        body: {
          'topics': [topic('custom-1', t0)],
          'sessions': [session('s1', t0)],
        },
      );
      final (_, other) = await call('POST', '/v1/sync', token: b, body: {});
      expect(other['topics'], isEmpty);
      expect(other['sessions'], isEmpty);

      expect((await call('DELETE', '/v1/account', token: a)).$1, 204);
      for (final table in [
        'topics',
        'questions',
        'sessions',
        'answers',
        'auth_tokens',
      ]) {
        final rows = await db.execute(
          'SELECT count(*) FROM $table t JOIN accounts a ON a.id = t.account_id '
          "WHERE a.email = 'a@example.com'",
        );
        expect(rows.first.first, 0, reason: table);
      }
      final left = await db.execute('SELECT count(*) FROM questions');
      expect(left.first.first, 0);
      expect((await call('GET', '/v1/account', token: a)).$1, 401);
    });
  });

  test('unknown routes and malformed JSON', () async {
    expect((await call('GET', '/v2/nothing')).$1, 404);
    final response = await http.post(
      base.resolve('/v1/auth/login'),
      body: '{oops',
    );
    expect(response.statusCode, 400);
  });
}
