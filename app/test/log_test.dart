// Журнал (практикалық №7): құпия деректер жасырылады, соңғы жазбалар
// шектеулі санмен сақталады. RemoteUpdate: келген өзгерістерді санау.
import 'package:flutter_test/flutter_test.dart';
import 'package:intrvue/core/log.dart';
import 'package:intrvue/data/repositories/sync_repository.dart';

void main() {
  group('Log.redact', () {
    test('Bearer токен жасырылады', () {
      expect(
        Log.redact('GET /v1/sync authorization: Bearer abc.DEF-123_x'),
        'GET /v1/sync authorization: Bearer ***',
      );
    });

    test('JSON және form өрістеріндегі пароль/токен жасырылады', () {
      expect(
        Log.redact('{"email_ok":1,"password":"qwerty2026","token": "t0k"}'),
        '{"email_ok":1,"password":"***","token": "***"}',
      );
      expect(Log.redact('secret=s3cr3t&x=1'), 'secret=***&x=1');
    });

    test('email: бірінші әріп пен домен қалады', () {
      expect(
        Log.redact('login failed for aidana@example.com'),
        'login failed for a***@example.com',
      );
    });

    test('құпиясы жоқ мәтін өзгермейді', () {
      const text = 'sync: received 2 sessions, 1 topics';
      expect(Log.redact(text), text);
    });
  });

  group('Log жазбалары', () {
    late void Function(String) saved;
    final printed = <String>[];

    setUp(() {
      saved = Log.output;
      Log.output = printed.add;
      printed.clear();
      Log.clear();
    });

    tearDown(() => Log.output = saved);

    test('деңгей, тег және жасырылған мәтін', () {
      Log.error('sync', 'failed for a@b.kz', 'Bearer xyz');
      final e = Log.recent.single;
      expect(e.level, LogLevel.error);
      expect(e.tag, 'sync');
      expect(e.message, 'failed for a***@b.kz: Bearer ***');
      expect(printed.single, '[intRvue] ERROR sync: ${e.message}');
    });

    test('тек соңғы ${Log.keep} жазба сақталады', () {
      for (var i = 0; i < Log.keep + 25; i++) {
        Log.info('t', 'n$i');
      }
      expect(Log.recent, hasLength(Log.keep));
      expect(Log.recent.first.message, 'n25');
      expect(Log.recent.last.message, 'n${Log.keep + 24}');
    });
  });

  group('RemoteUpdate.between', () {
    Map<String, Object?> snap(List<(String, int)> s, List<(String, int)> t) => {
      'sessions': [
        for (final (id, at) in s) {'id': id, 'updated_at': at},
      ],
      'topics': [
        for (final (id, at) in t) {'id': id, 'updated_at': at},
      ],
    };

    test('өз деректеріміз қайтса — өзгеріс жоқ', () {
      final local = snap([('s1', 1)], [('t1', 5)]);
      expect(RemoteUpdate.between(local, local).isEmpty, isTrue);
    });

    test('жаңа және жаңартылған жазбалар саналады', () {
      final local = snap([('s1', 1)], [('t1', 5)]);
      final merged = snap([('s1', 2), ('s2', 3)], [('t1', 5), ('t2', 9)]);
      final u = RemoteUpdate.between(local, merged);
      expect(u.sessions, 2);
      expect(u.topics, 1);
    });

    test('басқа құрылғыда жойылған жазба да өзгеріс', () {
      final local = snap([('s1', 1), ('s2', 2)], [('t1', 5)]);
      final merged = snap([('s1', 1)], []);
      final u = RemoteUpdate.between(local, merged);
      expect(u.sessions, 1);
      expect(u.topics, 1);
    });
  });
}
