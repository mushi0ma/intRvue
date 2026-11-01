// Практикалық №5: REST клиенті — JSON → Dart модельдері, қателердің түрлері
// (желі жоқ, timeout, сервер қатесі). Экран күйлері — cloud_topics_screen_test.
// Желі қателері нақты сокетпен тексеріледі (dart:io HttpServer).
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:intrvue/data/models/enums.dart';
import 'package:intrvue/data/remote/dto.dart';
import 'package:intrvue/data/remote/sync_api.dart';

Map<String, Object?> _topicJson() => {
  'id': 'u1-100',
  'title': 'Docker негіздері',
  'summary': 'Image, container',
  'direction': 'backend',
  'level': 'junior',
  'description': 'Сипаттама',
  'review_points': ['Image', 'Volume'],
  'sample_question': 'Volume не үшін керек?',
  'created_at': '2026-10-29T10:00:00.000Z',
  'updated_at': '2026-10-30T12:30:00.123456Z',
  'questions': [
    {
      'id': 'u1-100-q1',
      'position': 0,
      'text': 'Volume не үшін керек?',
      'hint': '',
      'model_answer': 'Деректерді сақтау үшін.',
      'concepts': [
        {
          'label': 'Volume',
          'keywords': ['volume'],
        },
      ],
    },
  ],
};

void main() {
  group('JSON → Dart Model', () {
    test('TopicDto: барлық өріс, ISO уақыт, кірістірілген сұрақтар', () {
      final t = TopicDto.fromJson(_topicJson());
      expect(t.direction, Direction.backend);
      expect(t.level, Level.junior);
      expect(t.reviewPoints, ['Image', 'Volume']);
      expect(t.updatedAt, DateTime.utc(2026, 10, 30, 12, 30, 0, 123, 456));
      expect(t.questions.single.concepts.single.keywords, ['volume']);

      // POST денесі: id сақталады, updated_at жіберілмейді (серверде қойылады).
      final body = t.toJson();
      expect(body['id'], 'u1-100');
      expect(body.containsKey('updated_at'), isFalse);
      expect(body['questions'], hasLength(1));
      expect(t.toPatchJson().containsKey('id'), isFalse);
      // toJson → fromJson айналымы мазмұнды сақтайды.
      final again = TopicDto.fromJson({
        ...body,
        'sample_question': t.sampleQuestion,
        'updated_at': '2026-10-30T12:30:00Z',
      });
      expect(again.title, t.title);
      expect(again.questions.single.modelAnswer, 'Деректерді сақтау үшін.');
    });

    test('AccountDto: created_at миллисекундпен', () {
      final a = AccountDto.fromJson({
        'id': 7,
        'email': 'a@example.com',
        'name': 'Айдана',
        'direction': 'mobile',
        'level': 'beginner',
        'interview_language': 'ru',
        'created_at': 1761700000000,
      });
      expect(a.interviewLanguage, InterviewLanguage.ru);
      expect(a.createdAt.millisecondsSinceEpoch, 1761700000000);
      expect(a.toJson()['interview_language'], 'ru');
    });

    test('бұзылған JSON — FormatException, құламайды', () {
      for (final broken in [
        {..._topicJson(), 'title': null},
        {..._topicJson(), 'level': 'senior'},
        {..._topicJson(), 'review_points': 'Image'},
        {..._topicJson(), 'updated_at': 'кеше'},
        {
          ..._topicJson(),
          'questions': [
            {'id': 'q', 'text': 'x'},
          ],
        },
      ]) {
        expect(
          () => TopicDto.fromJson(broken),
          throwsFormatException,
          reason: '$broken',
        );
      }
    });
  });

  test('HTTP күйі → SyncFailure', () {
    expect(
      failureFor(401, 'invalid_credentials'),
      SyncFailure.invalidCredentials,
    );
    expect(failureFor(401, 'unauthorized'), SyncFailure.unauthorized);
    expect(failureFor(404, 'not_found'), SyncFailure.notFound);
    expect(failureFor(409, 'email_taken'), SyncFailure.emailTaken);
    expect(failureFor(409, 'title_taken'), SyncFailure.titleTaken);
    expect(failureFor(409, 'conflict'), SyncFailure.conflict);
    expect(failureFor(400, 'weak_password'), SyncFailure.weakPassword);
    expect(failureFor(400, 'invalid_request'), SyncFailure.invalidRequest);
    expect(failureFor(429, null), SyncFailure.rateLimited);
    expect(failureFor(500, 'internal'), SyncFailure.server);
    expect(failureFor(503, null), SyncFailure.server);
  });

  group('желі қателері (нақты сокет)', () {
    late HttpServer server;
    late Uri base;
    Future<void> Function(HttpRequest)? handle;

    setUp(() async {
      server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      base = Uri.parse('http://127.0.0.1:${server.port}');
      server.listen((r) => handle!(r));
    });

    tearDown(() => server.close(force: true));

    Matcher fails(SyncFailure f) =>
        throwsA(isA<SyncApiException>().having((e) => e.failure, 'failure', f));

    test('сервер ұзақ жауап берсе — timeout (офлайннан бөлек)', () async {
      handle = (r) async {
        await Future<void>.delayed(const Duration(seconds: 2));
        r.response.close().ignore();
      };
      final api = HttpSyncApi(base, timeout: const Duration(milliseconds: 200));
      final watch = Stopwatch()..start();
      await expectLater(api.topics('t'), fails(SyncFailure.timeout));
      expect(watch.elapsed, lessThan(const Duration(seconds: 2)));
    });

    test('ешкім тыңдамайтын порт — offline', () async {
      final closed = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
      final port = closed.port;
      await closed.close();
      final api = HttpSyncApi(Uri.parse('http://127.0.0.1:$port'));
      await expectLater(api.topics('t'), fails(SyncFailure.offline));
    });

    test('500 және JSON емес жауап — server', () async {
      handle = (r) async {
        r.response.statusCode = r.uri.path.endsWith('topics') ? 500 : 200;
        r.response.write('<html>oops</html>');
        await r.response.close();
      };
      final api = HttpSyncApi(base);
      await expectLater(api.topics('t'), fails(SyncFailure.server));
      await expectLater(api.account('t'), fails(SyncFailure.server));
    });

    test('200, бірақ пішімі басқа JSON — server, exception шықпайды', () async {
      handle = (r) async {
        r.response.headers.contentType = ContentType.json;
        r.response.write(jsonEncode({'topics': 'not a list'}));
        await r.response.close();
      };
      await expectLater(
        HttpSyncApi(base).topics('t'),
        fails(SyncFailure.server),
      );
    });

    test('PATCH денесі мен әдісі серверге дұрыс жетеді', () async {
      late String method;
      late Map<String, Object?> body;
      late String? auth;
      handle = (r) async {
        method = r.method;
        auth = r.headers.value('authorization');
        body = jsonDecode(await utf8.decodeStream(r)) as Map<String, Object?>;
        r.response.headers.contentType = ContentType.json;
        r.response.write(jsonEncode({..._topicJson(), ...body}));
        await r.response.close();
      };
      final updated = await HttpSyncApi(base)
          .updateTopic('secret', 'u1-100', {'title': 'Жаңа атау'});
      expect(method, 'PATCH');
      expect(auth, 'Bearer secret');
      expect(body, {'title': 'Жаңа атау'});
      expect(updated.title, 'Жаңа атау');
    });
  });
}
