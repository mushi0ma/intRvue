import 'dart:io';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../data/local/app_database.dart';
import '../data/repositories/auth_repository.dart';
import '../data/repositories/session_repository.dart';
import '../data/repositories/settings_repository.dart';
import '../data/repositories/topic_repository.dart';
import '../data/services/reminder_scheduler.dart';

/// Қосымшаның барлық тәуелділігі: деректер қоры және репозиторийлер.
class AppServices {
  AppServices._(
    this.prefs,
    this.database,
    this.auth,
    this.settings,
    this.topics,
    this.sessions,
    this.reminders,
  );

  final SharedPreferences prefs;
  final AppDatabase database;
  final AuthRepository auth;
  final SettingsRepository settings;
  final TopicRepository topics;
  final SessionRepository sessions;
  final ReminderScheduler reminders;

  /// Деректер қорын инициализациялап, соңғы кірген пайдаланушының
  /// деректерін жүктейді. Интернет қажет емес.
  static Future<AppServices> start({
    DatabaseFactory? factory,
    String? databasePath,
    ReminderScheduler? reminders,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final database = await AppDatabase.open(
      factory: factory ?? _platformFactory(),
      path: databasePath,
    );
    final topics = TopicRepository(database);
    final sessions = SessionRepository(database, prefs, topics);
    // Реті маңызды: сессиялар тақырыптардың сұрақтарына сілтейді.
    final auth = AuthRepository(database, prefs, scoped: [topics, sessions]);
    await auth.init();
    return AppServices._(
      prefs,
      database,
      auth,
      SettingsRepository(prefs),
      topics,
      sessions,
      reminders ?? await LocalReminderScheduler.create(),
    );
  }

  /// Android/iOS — нативті sqflite, десктоп — FFI арқылы SQLite.
  static DatabaseFactory? _platformFactory() {
    if (Platform.isLinux || Platform.isWindows || Platform.isMacOS) {
      sqfliteFfiInit();
      return databaseFactoryFfi;
    }
    return null;
  }

  Future<void> dispose() => database.close();
}
