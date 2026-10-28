import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../mock/mock_questions.dart';
import '../mock/mock_sessions.dart';
import '../mock/mock_topics.dart';
import '../models/interview_session.dart';
import '../models/user_profile.dart';
import 'db_schema.dart';
import 'mappers.dart';
import 'password_hasher.dart';

/// Құрылғыдағы SQLite деректер қоры. Интернетсіз толық жұмыс істейді.
class AppDatabase {
  AppDatabase._(this.db);

  final Database db;

  /// Деректер қорын ашады; алғаш ашқанда кестелерді құрып, демо деректерді
  /// толтырады. Тесттерде [factory] мен [path] ауыстырылады.
  static Future<AppDatabase> open({
    DatabaseFactory? factory,
    String? path,
    bool seed = true,
  }) async {
    final f = factory ?? databaseFactory;
    final location =
        path ?? p.join(await f.getDatabasesPath(), DbSchema.fileName);
    final db = await f.openDatabase(
      location,
      options: OpenDatabaseOptions(
        version: DbSchema.version,
        singleInstance: path != inMemoryDatabasePath,
        // Сыртқы кілттер SQLite-та әдепкіде өшірулі.
        onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
        onCreate: (db, version) async {
          final batch = db.batch();
          for (final statement in DbSchema.create) {
            batch.execute(statement);
          }
          await batch.commit(noResult: true);
          if (seed) await _seed(db);
        },
        // Деректерді жоғалтпай схеманы жаңарту: v1 → v2 → …
        onUpgrade: (db, from, to) async {
          for (var v = from + 1; v <= to; v++) {
            for (final statement
                in DbSchema.migrations[v] ?? const <String>[]) {
              await db.execute(statement);
            }
          }
        },
      ),
    );
    return AppDatabase._(db);
  }

  Future<void> close() => db.close();

  /// Сессияны жауаптарымен бірге бір транзакцияда жазу.
  static Future<void> insertSession(
    DatabaseExecutor db,
    InterviewSession session,
    int userId,
  ) async {
    await db.insert(DbSchema.sessions, Mappers.sessionRow(session, userId));
    for (var i = 0; i < session.answers.length; i++) {
      await db.insert(
        DbSchema.answers,
        Mappers.answerRow(session.id, i, session.answers[i]),
      );
    }
  }

  /// Кірістірілген каталог және «Айдана» демо аккаунтының тарихы.
  static Future<void> _seed(Database db) async {
    await db.transaction((txn) async {
      final created = DateTime(2026, 10, 1);
      for (final topic in mockTopics) {
        final row = Mappers.topicRow(topic)
          ..['created_at'] = Mappers.ms(created)
          ..['updated_at'] = Mappers.ms(created);
        await txn.insert(DbSchema.topics, row);
        final questions = mockQuestions.where((q) => q.topicId == topic.id);
        var position = 0;
        for (final q in questions) {
          await txn.insert(
            DbSchema.questions,
            Mappers.questionRow(q, position++),
          );
        }
      }

      final salt = PasswordHasher.newSalt();
      final userId = await txn.insert(DbSchema.users, {
        ...Mappers.userProfileRow(
          const UserProfile(name: 'Айдана', email: demoEmail),
        ),
        'password_hash': PasswordHasher.hash(demoPassword, salt),
        'password_salt': salt,
        'created_at': Mappers.ms(created),
      });

      for (final session in [...buildMockHistory(), buildMockActiveSession()]) {
        await insertSession(txn, session, userId);
      }
      await txn.insert(DbSchema.favorites, {
        'user_id': userId,
        'topic_id': 'flutter-widgets',
        'created_at': Mappers.ms(created),
      });
    });
  }

  /// Демо аккаунт: дизайндағы «Айдана».
  static const demoEmail = 'aidana@example.com';
  static const demoPassword = 'intrvue2026';
}
