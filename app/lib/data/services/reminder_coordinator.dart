import 'dart:async';

import '../../core/log.dart';
import '../repositories/auth_repository.dart';
import '../repositories/session_repository.dart';
import '../repositories/settings_repository.dart';
import '../repositories/topic_repository.dart';
import 'reminder_plan.dart';
import 'reminder_scheduler.dart';

/// Еске салуды қосымшаның негізгі логикасымен байланыстырады.
///
/// - Сессия басталса, аяқталса не жойылса, баптау не аккаунт ауысса —
///   хабарлама мәтіні мен кестесі қайта есептеледі ([ReminderPlan]).
/// - Бүгін сессия аяқталған болса, бүгінгі хабарлама өткізіледі.
/// - Аккаунттан шыққанда барлық хабарлама өшіріледі.
/// - Хабарламаны басқанда ашылатын экран сол сәттегі деректерден анықталады.
class ReminderCoordinator {
  ReminderCoordinator({
    required this._auth,
    required this._settings,
    required this._sessions,
    required this._topics,
    required this._scheduler,
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  final AuthRepository _auth;
  final SettingsRepository _settings;
  final SessionRepository _sessions;
  final TopicRepository _topics;
  final ReminderScheduler _scheduler;
  final DateTime Function() _clock;

  bool _dirty = false;
  bool _disposed = false;
  Completer<void>? _running;

  /// Соңғы жоспарланған кесте; `off` — бәрі өшірілген; null — белгісіз.
  String? _scheduled;

  /// Тыңдауды бастап, кестені бірден сәйкестендіреді (қайта іске қосқанда:
  /// сақталған сессия мен деректер бойынша). Ұзақ күтпейміз — қосымша
  /// хабарламасыз да іске қосылуы керек.
  Future<void> start() async {
    _auth.addListener(_changed);
    _settings.addListener(_changed);
    _sessions.addListener(_changed);
    try {
      await refresh().timeout(const Duration(seconds: 2));
    } catch (e) {
      Log.warn('reminders', 'initial schedule skipped: $e');
    }
  }

  // Бір кадрдағы бірнеше өзгеріс (мысалы, сессия + тарих) — бір жаңарту.
  void _changed() {
    if (_dirty) return;
    _dirty = true;
    scheduleMicrotask(() {
      _dirty = false;
      if (!_disposed) _background();
    });
  }

  // Фондағы жаңарту: қате журналға жазылады, келесі өзгерісте қайталанады.
  void _background() => unawaited(
    refresh().catchError(
      (Object e) => Log.error('reminders', 'schedule failed', e),
    ),
  );

  ReminderPlan currentPlan() => ReminderPlan.build(
    active: _sessions.active,
    history: _sessions.history,
    topicById: _topics.tryById,
    now: _clock(),
  );

  /// Кестені деректерге сәйкестендіру. Қатар шақырулар кезекпен орындалады.
  /// [force] — рұқсат жаңа ғана берілді, кесте өзгермесе де қайта жазу.
  /// Қате шақырушыға қайтарылады (экран хабарлама көрсетеді).
  Future<void> refresh({bool force = false}) async {
    if (force) _scheduled = null;
    while (_running != null) {
      await _running!.future;
    }
    final running = _running = Completer<void>();
    try {
      await _apply();
    } catch (_) {
      _scheduled = null;
      rethrow;
    } finally {
      _running = null;
      running.complete();
    }
  }

  Future<void> _apply() async {
    final settings = _settings.reminders;
    if (!_auth.isLoggedIn || !settings.enabled) {
      if (_scheduled != 'off') {
        await _scheduler.cancelAll();
        _scheduled = 'off';
      }
      return;
    }
    // Рұқсат жоқ: сұрауды экран жасайды, мұнда тек күтеміз.
    if (!await _scheduler.isPermitted()) {
      _scheduled = null;
      return;
    }
    final plan = currentPlan();
    final now = _clock();
    final days = settings.days.toList()..sort();
    final signature =
        '${plan.signature()}|$days|${settings.time.hour}:${settings.time.minute}'
        '|${plan.skipToday ? '${now.year}-${now.month}-${now.day}' : ''}';
    if (signature == _scheduled) return;
    await _scheduler.scheduleWeekly(
      days: settings.days,
      time: settings.time,
      title: plan.title,
      body: plan.body,
      notBefore: plan.skipToday
          ? DateTime(now.year, now.month, now.day + 1)
          : null,
    );
    _scheduled = signature;
  }

  /// Ашық қосымшада басылған хабарлама → ашылатын маршрут.
  Stream<String> get openRequests => _scheduler.taps
      .where((_) => _auth.isLoggedIn)
      .map((_) => currentPlan().route);

  /// Қосымшаны хабарлама іске қосса → маршрут (бір рет).
  Future<String?> takeLaunchRoute() async {
    if (!await _scheduler.takeLaunchTap()) return null;
    return _auth.isLoggedIn ? currentPlan().route : null;
  }

  void dispose() {
    _disposed = true;
    _auth.removeListener(_changed);
    _settings.removeListener(_changed);
    _sessions.removeListener(_changed);
  }
}
