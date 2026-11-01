import 'dart:async';
import 'dart:io';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../data/local/app_database.dart';
import '../data/repositories/auth_repository.dart';
import '../data/repositories/cloud_topics_repository.dart';
import '../data/repositories/session_repository.dart';
import '../data/remote/live_channel.dart';
import '../data/remote/sync_api.dart';
import '../data/repositories/settings_repository.dart';
import '../data/repositories/sync_repository.dart';
import '../data/repositories/topic_repository.dart';
import '../data/services/reminder_coordinator.dart';
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
    this.sync,
    this.cloud,
    this.reminderCoordinator,
  );

  final SharedPreferences prefs;
  final AppDatabase database;
  final AuthRepository auth;
  final SettingsRepository settings;
  final TopicRepository topics;
  final SessionRepository sessions;
  final ReminderScheduler reminders;
  final SyncRepository sync;
  final CloudTopicsRepository cloud;
  final ReminderCoordinator reminderCoordinator;

  /// Деректер қорын инициализациялап, соңғы кірген пайдаланушының
  /// деректерін жүктейді. Интернет қажет емес.
  static Future<AppServices> start({
    DatabaseFactory? factory,
    String? databasePath,
    ReminderScheduler? reminders,
    SyncApi Function(Uri baseUrl)? syncApi,
    LiveChannel? live,
    String? deviceId,
    DateTime Function()? clock,
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
    final sync = SyncRepository(
      prefs: prefs,
      database: database,
      auth: auth,
      scoped: [topics, sessions],
      watch: [topics, sessions],
      api: syncApi,
      live: live,
      deviceId: deviceId,
    );
    // Желі болмаса үнсіз өтеді — қосымша офлайн іске қосыла береді.
    if (sync.link != null) unawaited(sync.syncNow());
    final settings = SettingsRepository(prefs);
    final scheduler = reminders ?? await LocalReminderScheduler.create();
    // Қайта іске қосылғанда кестені сақталған сессия мен деректерге сәйкестейді.
    final coordinator = ReminderCoordinator(
      auth: auth,
      settings: settings,
      sessions: sessions,
      topics: topics,
      scheduler: scheduler,
      clock: clock,
    );
    await coordinator.start();
    return AppServices._(
      prefs,
      database,
      auth,
      settings,
      topics,
      sessions,
      scheduler,
      sync,
      CloudTopicsRepository(sync: sync, topics: topics),
      coordinator,
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

  Future<void> dispose() async {
    reminderCoordinator.dispose();
    cloud.dispose();
    sync.dispose();
    await database.close();
  }
}
