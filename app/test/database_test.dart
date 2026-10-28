// Деректер қабаты: SQLite схемасы, CRUD, іздеу/сүзгі/сұрыптау, таңдаулы,
// қателерді өңдеу және қайта іске қосқаннан кейін деректердің сақталуы.
import 'dart:io';

import 'package:flutter/material.dart' show DateTimeRange;
import 'package:flutter_test/flutter_test.dart';
import 'package:intrvue/app/bootstrap.dart';
import 'package:intrvue/core/constants/app_strings.dart';
import 'package:intrvue/data/local/db_errors.dart';
import 'package:intrvue/data/models/enums.dart';
import 'package:intrvue/data/models/interview_session.dart';
import 'package:intrvue/data/models/topic.dart';
import 'package:intrvue/data/repositories/auth_repository.dart';
import 'package:intrvue/data/repositories/session_repository.dart';
import 'package:intrvue/data/services/assessment_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart' show Sqflite;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

const _draft = TopicDraft(
  title: 'Flutter анимациялары',
  summary: 'Implicit, explicit, Hero',
  description: '',
  direction: Direction.mobile,
  level: Level.junior,
  reviewPoints: ['AnimationController өмірлік циклі', 'Hero өтуі'],
  questions: [
    QuestionDraft(
      text: 'AnimationController-ді қашан dispose ету керек?',
      modelAnswer:
          'State dispose() әдісінде, жадтың ағып кетуін болдырмау үшін.',
    ),
  ],
);

Future<AppServices> _start({String? path}) => AppServices.start(
  factory: databaseFactoryFfiNoIsolate,
  databasePath: path ?? inMemoryDatabasePath,
);

Future<AppServices> _loggedIn({String? path}) async {
  final s = await _start(path: path);
  if (!s.auth.isLoggedIn) {
    await s.auth.login(AuthRepository.demoEmail, AuthRepository.demoPassword);
  }
  return s;
}

void main() {
  late AppServices s;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    s = await _loggedIn();
  });
  tearDown(() => s.dispose());

  group('Схема және бастапқы деректер', () {
    test('сегіз кесте және сыртқы кілттер қосулы', () async {
      final tables = await s.database.db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type = 'table' "
        "AND name NOT LIKE 'sqlite_%' AND name != 'android_metadata'",
      );
      expect(tables.map((r) => r['name']).toSet(), {
        'users',
        'topics',
        'questions',
        'sessions',
        'answers',
        'favorites',
        'password_resets',
        'sync_deletions',
      });
      final fk = await s.database.db.rawQuery('PRAGMA foreign_keys');
      expect(fk.first.values.first, 1);
    });

    test('каталог, демо тарих және белсенді сессия жүктелді', () {
      expect(s.topics.all.length, 13);
      expect(s.topics.questionsFor('flutter-widgets').length, 3);
      expect(s.sessions.history.length, 5);
      expect(s.sessions.active?.currentIndex, 1);
      expect(s.topics.isFavorite('flutter-widgets'), isTrue);
    });
  });

  group('Тақырып CRUD', () {
    test('Create → Read → Update → Delete', () async {
      final created = await s.topics.create(_draft);
      expect(created.isCustom, isTrue);
      expect(s.topics.byId(created.id).title, 'Flutter анимациялары');
      expect(s.topics.questionsFor(created.id).single.concepts, isNotEmpty);

      await s.topics.update(
        created.id,
        TopicDraft(
          title: 'Анимациялар',
          summary: _draft.summary,
          description: 'Толық сипаттама',
          direction: Direction.mobile,
          level: Level.middle,
          reviewPoints: _draft.reviewPoints,
          questions: [
            ..._draft.questions.map(
              (q) => QuestionDraft(
                id: s.topics.questionsFor(created.id).first.id,
                text: q.text,
                modelAnswer: q.modelAnswer,
              ),
            ),
            const QuestionDraft(
              text: 'Hero қалай жұмыс істейді?',
              modelAnswer: 'Tag бойынша.',
            ),
          ],
        ),
      );
      final updated = s.topics.byId(created.id);
      expect(updated.title, 'Анимациялар');
      expect(updated.level, Level.middle);
      expect(s.topics.questionsFor(created.id).length, 2);

      await s.topics.delete(created.id);
      expect(s.topics.tryById(created.id), isNull);
      final orphans = await s.database.db.query(
        'questions',
        where: 'topic_id = ?',
        whereArgs: [created.id],
      );
      expect(orphans, isEmpty, reason: 'ON DELETE CASCADE');
    });

    test('атауы қайталанса — түсінікті қате', () async {
      await s.topics.create(_draft);
      expect(
        () => s.topics.create(_draft),
        throwsA(
          isA<AppException>().having(
            (e) => e.message,
            'message',
            S.topicDuplicate,
          ),
        ),
      );
      expect(
        () => s.topics.create(
          TopicDraft(
            title: 'dart НЕГІЗДЕРІ',
            summary: 'x',
            description: '',
            direction: Direction.mobile,
            level: Level.beginner,
            reviewPoints: const [],
            questions: _draft.questions,
          ),
        ),
        throwsA(isA<AppException>()),
        reason: 'кірістірілген тақырыппен атауы бірдей (регистрсіз)',
      );
    });

    test('кірістірілген тақырыпты өзгертуге болмайды', () {
      expect(
        () => s.topics.update('dart-basics', _draft),
        throwsA(
          isA<AppException>().having(
            (e) => e.message,
            'message',
            S.topicReadOnly,
          ),
        ),
      );
    });

    test('сессияда қолданылған тақырыпты жою — FOREIGN KEY қатесі', () async {
      final topic = await s.topics.create(_draft);
      await s.sessions.finishActive();
      s.sessions.pending = PracticeRequest(
        direction: Direction.mobile,
        level: Level.junior,
        language: InterviewLanguage.kk,
        topicIds: [topic.id],
        questionCount: 1,
      );
      final session = await s.sessions.startPending();
      expect(session!.current.question.topicId, topic.id);

      expect(
        () => s.topics.delete(topic.id),
        throwsA(
          isA<AppException>().having((e) => e.message, 'message', S.topicInUse),
        ),
      );
      expect(
        s.topics.tryById(topic.id),
        isNotNull,
        reason: 'деректер сақталды',
      );

      // Сессияны жойғаннан кейін тақырыпты жоюға болады.
      await s.sessions.finishActive();
      await s.sessions.delete(session.id);
      await s.topics.delete(topic.id);
      expect(s.topics.tryById(topic.id), isNull);
    });
  });

  group('Іздеу, сүзгі, сұрыптау', () {
    test('кириллицамен регистрсіз іздеу', () async {
      final r = await s.topics.query(const TopicQuery(search: 'КҮЙДІ'));
      expect(r.map((i) => i.topic.id), contains('state-management'));
      final none = await s.topics.query(const TopicQuery(search: 'Kubernetes'));
      expect(none, isEmpty);
      final twoWords = await s.topics.query(
        const TopicQuery(search: 'future stream'),
      );
      expect(twoWords.single.topic.id, 'async');
    });

    test('бағыт, деңгей, таңдаулы, менікі сүзгілері', () async {
      final mobile = await s.topics.query(
        const TopicQuery(direction: Direction.mobile),
      );
      expect(mobile.length, 4);
      expect(
        mobile.every((i) => i.topic.direction == Direction.mobile),
        isTrue,
      );

      await s.topics.create(_draft);
      final junior = await s.topics.query(
        const TopicQuery(level: Level.junior),
      );
      expect(junior.single.topic.title, _draft.title);

      final fav = await s.topics.query(const TopicQuery(onlyFavorites: true));
      expect(fav.single.topic.id, 'flutter-widgets');

      final mine = await s.topics.query(const TopicQuery(onlyMine: true));
      expect(mine.single.topic.isCustom, isTrue);
    });

    test('атауы, жаңалығы және балы бойынша сұрыптау', () async {
      List<String> titles(List<TopicListItem> l) => [
        for (final i in l) i.topic.title,
      ];

      final asc = await s.topics.query(
        const TopicQuery(direction: Direction.qa),
      );
      final desc = await s.topics.query(
        const TopicQuery(direction: Direction.qa, sort: TopicSort.titleDesc),
      );
      expect(titles(asc), titles(desc).reversed.toList());
      expect(titles(asc).first, 'Баг есебі');

      final created = await s.topics.create(_draft);
      final newest = await s.topics.query(
        const TopicQuery(sort: TopicSort.newest),
      );
      expect(newest.first.topic.id, created.id);

      final weakest = await s.topics.query(
        const TopicQuery(direction: Direction.mobile, sort: TopicSort.weakest),
      );
      final scores = [for (final i in weakest) i.averageScore];
      expect(
        scores.whereType<double>().toList(),
        orderedEquals([...scores.whereType<double>()]..sort()),
      );
      expect(scores.first, isNotNull);
    });

    test('тарихты сүзгілеу және балы бойынша сұрыптау', () {
      final complete = s.sessions.queryHistory(
        complete: true,
        sort: HistorySort.scoreHigh,
      );
      expect(complete.map((x) => x.score!.round()), [80, 73, 67, 60]);
      final incomplete = s.sessions.queryHistory(complete: false);
      expect(incomplete.single.isComplete, isFalse);
      final oldest = s.sessions.queryHistory(sort: HistorySort.oldest);
      expect(oldest.first.startedAt.isBefore(oldest.last.startedAt), isTrue);
    });
  });

  group('Таңдаулы', () {
    test('қосу, алу және бұрынғы орнына қайтару', () async {
      await s.topics.addFavorite('async');
      await s.topics.addFavorite('dart-basics');
      expect(s.topics.favorites.map((t) => t.id), [
        'flutter-widgets',
        'async',
        'dart-basics',
      ]);
      final at = await s.topics.removeFavorite('async');
      expect(s.topics.isFavorite('async'), isFalse);
      await s.topics.addFavorite('async', at: at);
      expect(s.topics.favorites.map((t) => t.id), [
        'flutter-widgets',
        'async',
        'dart-basics',
      ]);
    });
  });

  group('Қателерді өңдеу', () {
    test('жабық деректер қоры — AppException', () async {
      await s.database.close();
      expect(
        () => s.topics.query(const TopicQuery()),
        throwsA(isA<AppException>()),
      );
    });

    test('бұрыннан бар email — emailTaken', () async {
      await s.auth.logout();
      final error = await s.auth.register(
        name: 'Айдана',
        email: 'AIDANA@example.com',
        password: 'qwerty123',
      );
      expect(error, AuthError.emailTaken);
    });
  });

  group('Қайта іске қосу (файлдағы қор)', () {
    late Directory dir;
    setUp(() => dir = Directory.systemTemp.createTempSync('intrvue_db_'));
    tearDown(() => dir.deleteSync(recursive: true));

    test('енгізілген деректер қайта ашқанда сақталады', () async {
      final path = '${dir.path}/intrvue.db';
      SharedPreferences.setMockInitialValues({});
      var app = await _loggedIn(path: path);

      // Жаңа аккаунт, тақырып, таңдаулы, профиль өзгерісі, жауап нобайы.
      await app.auth.logout();
      await app.auth.register(
        name: 'Ерлан',
        email: 'erlan@example.com',
        password: 'erlan2026',
      );
      final topic = await app.topics.create(_draft);
      await app.topics.addFavorite(topic.id);
      await app.auth.updateProfile(
        app.auth.user!.copyWith(level: Level.middle),
      );
      app.sessions.pending = PracticeRequest(
        direction: Direction.mobile,
        level: Level.middle,
        language: InterviewLanguage.kk,
        topicIds: [topic.id],
        questionCount: 1,
      );
      await app.sessions.startPending();
      app.sessions.saveDraft('Нобай мәтіні');
      await app.sessions.flushDraft();
      await app.dispose();

      // «Қайта іске қосу»: жаңа қосылым, сол файл, сол SharedPreferences.
      app = await _start(path: path);
      expect(app.auth.user?.name, 'Ерлан');
      expect(app.auth.user?.level, Level.middle);
      expect(app.topics.tryById(topic.id)?.title, _draft.title);
      expect(app.topics.isFavorite(topic.id), isTrue);
      expect(app.sessions.active?.current.text, 'Нобай мәтіні');
      expect(app.sessions.active?.current.status, AnswerStatus.notAnswered);

      // Жауапты бағалау да сақталады.
      await app.sessions.submitCurrent(
        'AnimationController State dispose әдісінде жойылады.',
      );
      await app.sessions.next();
      await app.dispose();

      app = await _start(path: path);
      final finished = app.sessions.history.first;
      expect(finished.isComplete, isTrue);
      expect(finished.answers.single.assessment, isNotNull);
      await app.dispose();
    });
  });

  test('v1 → v4 миграциясы деректерді сақтайды, пікір сақталады', () async {
    final dir = Directory.systemTemp.createTempSync('intrvue_mig_');
    addTearDown(() => dir.deleteSync(recursive: true));
    final path = '${dir.path}/intrvue.db';
    SharedPreferences.setMockInitialValues({});

    // v1 күйін жасау: жаңа бағандарды алып тастап, нұсқаны 1-ге түсіреміз.
    var app = await _loggedIn(path: path);
    final db = app.database.db;
    final answersBefore = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM answers'),
    );
    await db.execute('ALTER TABLE answers DROP COLUMN dispute_comment');
    await db.execute('ALTER TABLE answers DROP COLUMN dispute_reason');
    await db.execute('DROP TABLE password_resets');
    await db.execute('ALTER TABLE answers DROP COLUMN updated_at');
    await db.execute('ALTER TABLE sessions DROP COLUMN updated_at');
    await db.execute('DROP TABLE sync_deletions');
    await db.setVersion(1);
    await app.dispose();

    app = await _start(path: path);
    final columns = await app.database.db.rawQuery(
      'PRAGMA table_info(answers)',
    );
    expect(
      columns.map((c) => c['name']),
      containsAll(['dispute_reason', 'dispute_comment', 'updated_at']),
    );
    expect(await app.database.db.getVersion(), 4);
    expect(
      Sqflite.firstIntValue(
        await app.database.db.rawQuery('SELECT COUNT(*) FROM answers'),
      ),
      answersBefore,
    );

    // Пікір жазылып, қайта ашқанда оқылады.
    await app.sessions.dispute(
      's-1019',
      1,
      reason: 'Баға қате',
      comment: 'Толықтық төмен',
    );
    await app.dispose();
    app = await _start(path: path);
    final record = app.sessions.byId('s-1019')!.answers[1];
    expect(record.disputed, isTrue);
    expect(record.disputeReason, 'Баға қате');
    expect(record.disputeComment, 'Толықтық төмен');
    await app.dispose();
  });

  group('Парольді қалпына келтіру', () {
    test('сілтеме бір рет жарамды, жаңа пароль жұмыс істейді', () async {
      expect(await s.auth.requestPasswordReset('nobody@example.com'), isNull);
      final link = await s.auth.requestPasswordReset(AuthRepository.demoEmail);
      expect(link!.scheme, 'intrvue');
      expect(link.path, '/reset-password');
      final token = link.queryParameters['token']!;

      expect(await s.auth.resetPassword(token, 'jana2026pass'), isNull);
      expect(
        await s.auth.resetPassword(token, 'tagy2026pass'),
        AuthError.resetLinkInvalid,
        reason: 'бір реттік',
      );
      expect(
        await s.auth.resetPassword('fake', 'x1234567'),
        AuthError.resetLinkInvalid,
      );

      await s.auth.logout();
      expect(
        await s.auth.login(
          AuthRepository.demoEmail,
          AuthRepository.demoPassword,
        ),
        AuthError.wrongCredentials,
      );
      expect(
        await s.auth.login(AuthRepository.demoEmail, 'jana2026pass'),
        isNull,
      );
    });

    test('ескірген сілтеме жарамсыз', () async {
      final link = await s.auth.requestPasswordReset(AuthRepository.demoEmail);
      final token = link!.queryParameters['token']!;
      await s.database.db.update(
        'password_resets',
        {
          'expires_at': DateTime.now()
              .subtract(const Duration(minutes: 1))
              .millisecondsSinceEpoch,
        },
        where: 'token = ?',
        whereArgs: [token],
      );
      expect(
        await s.auth.resetPassword(token, 'jana2026pass'),
        AuthError.resetLinkInvalid,
      );
    });
  });

  test('тарихты кезең бойынша сүзгілеу', () {
    final period = DateTimeRange(
      start: DateTime(2026, 10, 15),
      end: DateTime(2026, 10, 17),
    );
    final found = s.sessions.queryHistory(
      period: period,
      sort: HistorySort.oldest,
    );
    expect(found.map((x) => x.startedAt.day), [15, 17]);
  });

  test('бағалау қызметі интернетсіз жұмыс істейді', () {
    final q = s.topics.questionsFor('flutter-widgets').first;
    final a = const AssessmentService().evaluate(
      q,
      'StatelessWidget өзгермейтін, StatefulWidget State сақтайды, setState мысалы.',
    );
    expect(a.total, greaterThan(9));
  });
}
