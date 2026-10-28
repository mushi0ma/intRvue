// Бұлттық синхрондау: екі «құрылғы» (жеке SQLite қорлары) және процесс
// ішінде іске қосылған нақты сервер + PostgreSQL (`docker compose up -d db`).
// PostgreSQL қолжетімсіз болса, e2e тобы өткізіледі.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:intrvue/app/bootstrap.dart';
import 'package:intrvue/data/local/app_database.dart';
import 'package:intrvue/data/models/enums.dart';
import 'package:intrvue/data/models/topic.dart';
import 'package:intrvue/data/remote/sync_api.dart';
import 'package:intrvue/data/services/reminder_scheduler.dart';
import 'package:intrvue_server/intrvue_server.dart';
import 'package:postgres/postgres.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

const _topic = TopicDraft(
  title: 'Docker негіздері',
  summary: 'Image, container, volume',
  description: '',
  direction: Direction.backend,
  level: Level.junior,
  reviewPoints: ['Image мен container айырмашылығы'],
  questions: [
    QuestionDraft(
      text: 'Volume не үшін керек?',
      modelAnswer: 'Контейнер жойылса да деректерді сақтау үшін.',
    ),
  ],
);

Future<bool> _postgresAvailable(String url) async {
  try {
    final c = await Connection.open(
      Endpoint(
        host: Uri.parse(url).host,
        port: Uri.parse(url).port,
        database: 'intrvue_test',
        username: 'intrvue',
        password: 'intrvue_dev',
      ),
      settings: const ConnectionSettings(
        sslMode: SslMode.disable,
        connectTimeout: Duration(seconds: 2),
      ),
    );
    await c.close();
    return true;
  } on Object {
    return false;
  }
}

Future<void> main() async {
  final url =
      Platform.environment['TEST_DATABASE_URL'] ??
      'postgresql://intrvue:intrvue_dev@localhost:5433/intrvue_test?sslmode=disable';
  final available = await _postgresAvailable(url);

  group('e2e: SQLite ↔ сервер ↔ SQLite', skip: available ? false : 'PostgreSQL жоқ', () {
    late Pool db;
    late HttpServer server;
    late Uri base;

    setUpAll(() async {
      db = Pool.withUrl(url);
      await db.execute('DROP SCHEMA public CASCADE');
      await db.execute('CREATE SCHEMA public');
      await Schema.migrate(db);
      server = await io.serve(
        Api(db, passwords: const Passwords(iterations: 1000)).handler,
        '127.0.0.1',
        0,
      );
      base = Uri.parse('http://127.0.0.1:${server.port}');
    });

    tearDownAll(() async {
      await server.close(force: true);
      await db.close();
    });

    Future<AppServices> device() async {
      final s = await AppServices.start(
        factory: databaseFactoryFfiNoIsolate,
        databasePath: inMemoryDatabasePath,
        reminders: const NoopReminderScheduler(),
        syncApi: (_) => HttpSyncApi(base),
      );
      addTearDown(s.dispose);
      return s;
    }

    test(
      'қосу → басқа құрылғыда қалпына келтіру → жою екі жаққа тарайды',
      () async {
        SharedPreferences.setMockInitialValues({});

        // 1-құрылғы: демо аккаунт, өз тақырыбы, таңдаулыға қосылған.
        final a = await device();
        await a.auth.login(AppDatabase.demoEmail, AppDatabase.demoPassword);
        final custom = await a.topics.create(_topic);
        await a.topics.addFavorite(custom.id);
        expect(await a.sync.connect(AppDatabase.demoPassword), isNull);
        expect(a.sync.link?.lastSyncAt, isNotNull);

        final onServer = await db.execute('SELECT count(*) FROM sessions');
        expect(onServer.first.first, a.sessions.history.length + 1);

        // 2-құрылғы: жаңа орнату — демо аккаунт жоқ.
        final b = await device();
        await b.database.db.delete('users');
        await b.auth.logout();
        expect(await b.auth.hasAccount(AppDatabase.demoEmail), isFalse);
        expect(
          await b.sync.restore(AppDatabase.demoEmail, AppDatabase.demoPassword),
          isTrue,
        );
        expect(b.auth.user?.email, AppDatabase.demoEmail);
        expect(b.auth.user?.name, 'Айдана');
        expect(b.topics.tryById(custom.id)?.title, 'Docker негіздері');
        expect(b.topics.questionsFor(custom.id), hasLength(1));
        expect(b.topics.isFavorite(custom.id), isTrue);
        expect(b.sessions.history.length, a.sessions.history.length);
        expect(b.sessions.active?.id, a.sessions.active?.id);
        // Қалпына келтірілген пароль құрылғыда да жұмыс істейді.
        await b.auth.logout();
        expect(
          await b.auth.login(AppDatabase.demoEmail, AppDatabase.demoPassword),
          isNull,
        );

        // 2-құрылғыда жойылды → 1-құрылғыда да жойылады.
        final finished = b.sessions.history.first.id;
        await b.topics.delete(custom.id);
        await b.topics.removeFavorite('flutter-widgets');
        await b.sessions.delete(finished);
        expect(await b.sync.syncNow(), isNull);

        expect(await a.sync.syncNow(), isNull);
        expect(a.topics.tryById(custom.id), isNull);
        expect(a.topics.isFavorite('flutter-widgets'), isFalse);
        expect(a.sessions.byId(finished), isNull);

        // Ескі деректері бар құрылғы оларды қайта тірілтпейді.
        final tombstones = await db.execute('SELECT count(*) FROM tombstones');
        expect(tombstones.first.first, 3);
        final journal = await a.database.db.query('sync_deletions');
        expect(journal, isEmpty);
      },
    );

    test('соңғы өзгеріс жеңеді: тақырыпты екі құрылғыда өзгерту', () async {
      SharedPreferences.setMockInitialValues({});
      final a = await device();
      await a.auth.register(
        name: 'Ерлан',
        email: 'erlan@example.com',
        password: 'qwerty2026',
      );
      final topic = await a.topics.create(_topic);
      expect(await a.sync.connect('qwerty2026'), isNull);

      final b = await device();
      expect(await b.sync.restore('erlan@example.com', 'qwerty2026'), isTrue);
      await b.topics.update(
        topic.id,
        const TopicDraft(
          title: 'Docker: B құрылғысы',
          summary: 'B',
          description: '',
          direction: Direction.backend,
          level: Level.middle,
          reviewPoints: ['Compose'],
          questions: [
            QuestionDraft(
              text: 'Compose не үшін?',
              modelAnswer: 'Бірнеше сервис.',
            ),
          ],
        ),
      );
      expect(await b.sync.syncNow(), isNull);
      expect(await a.sync.syncNow(), isNull);
      final merged = a.topics.byId(topic.id);
      expect(merged.title, 'Docker: B құрылғысы');
      expect(merged.level, Level.middle);
      expect(a.topics.questionsFor(topic.id).single.text, 'Compose не үшін?');
      // Іздеу бағандары қайта есептелді.
      final found = await a.topics.search('compose');
      expect(found.map((t) => t.id), contains(topic.id));
    });

    test('серверде басқа пароль — қосылмайды, деректер өзгермейді', () async {
      SharedPreferences.setMockInitialValues({});
      final a = await device();
      await a.auth.register(
        name: 'Дина',
        email: 'dina@example.com',
        password: 'dina2026pass',
      );
      expect(await a.sync.connect('dina2026pass'), isNull);

      // SharedPreferences тестте ортақ: 2-құрылғыдағы id басқа болсын.
      final b = await device();
      await b.auth.register(
        name: 'Басқа',
        email: 'other@example.com',
        password: 'other2026pass',
      );
      await b.auth.register(
        name: 'Дина',
        email: 'dina@example.com',
        password: 'other2026pass',
      );
      await b.topics.create(_topic);
      expect(
        await b.sync.connect('other2026pass'),
        SyncFailure.invalidCredentials,
      );
      expect(b.sync.link, isNull);
      expect(b.sync.lastFailure, SyncFailure.invalidCredentials);
      // Серверге ештеңе жазылмады, құрылғыда тақырып орнында.
      final topics = await db.execute(
        'SELECT count(*) FROM topics t JOIN accounts a ON a.id = t.account_id '
        "WHERE a.email = 'dina@example.com'",
      );
      expect(topics.first.first, 0);
      expect(b.topics.all.where((t) => t.isCustom), hasLength(1));
    });
  });

  test(
    'сервер қолжетімсіз: қате қайтады, жергілікті деректер сақталады',
    () async {
      SharedPreferences.setMockInitialValues({});
      final s = await AppServices.start(
        factory: databaseFactoryFfiNoIsolate,
        databasePath: inMemoryDatabasePath,
        reminders: const NoopReminderScheduler(),
        // Ешкім тыңдамайтын порт.
        syncApi: (_) => HttpSyncApi(
          Uri.parse('http://127.0.0.1:9'),
          timeout: const Duration(seconds: 2),
        ),
      );
      addTearDown(s.dispose);
      await s.auth.login(AppDatabase.demoEmail, AppDatabase.demoPassword);
      final before = s.sessions.history.length;
      expect(
        await s.sync.connect(AppDatabase.demoPassword),
        SyncFailure.offline,
      );
      expect(s.sync.link, isNull);
      expect(s.sync.lastFailure, SyncFailure.offline);
      expect(await s.sync.restore('ghost@example.com', 'whatever1'), isFalse);
      expect(s.sessions.history.length, before);
    },
  );
}
