// №6: еске салу хабарламасы (күрделі мобильді функция) мен қосымшаның
// негізгі логикасы, рұқсат берілген / берілмеген жағдайлар, хабарламаны
// басу, қорғалған маршруттар және қайта іске қосқанда сессияның сақталуы.
import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:intrvue/app/app.dart';
import 'package:intrvue/app/routes.dart';
import 'package:intrvue/core/constants/app_strings.dart';
import 'package:intrvue/data/models/interview_session.dart';
import 'package:intrvue/data/repositories/settings_repository.dart';
import 'package:intrvue/data/services/reminder_coordinator.dart';
import 'package:intrvue/data/services/reminder_plan.dart';
import 'package:intrvue/data/services/reminder_scheduler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers/test_app.dart';

/// Жоспарлау шақыруларын жазып алатын планировщик.
class FakeScheduler implements ReminderScheduler {
  FakeScheduler({this.permitted = true, this.launchedByTap = false});

  bool permitted;
  bool launchedByTap;
  final scheduled =
      <({Set<int> days, String title, String body, DateTime? notBefore})>[];
  int cancels = 0;
  int requests = 0;
  int settingsOpened = 0;
  final _taps = StreamController<void>.broadcast();

  void tap() => _taps.add(null);

  @override
  Future<bool> isPermitted() async => permitted;

  @override
  Future<bool> requestPermission() async {
    requests++;
    return permitted;
  }

  @override
  Future<void> scheduleWeekly({
    required Set<int> days,
    required TimeOfDay time,
    required String title,
    required String body,
    DateTime? notBefore,
  }) async {
    scheduled.add((days: days, title: title, body: body, notBefore: notBefore));
  }

  @override
  Future<void> cancelAll() async => cancels++;

  @override
  Future<void> openSystemSettings() async => settingsOpened++;

  @override
  Stream<void> get taps => _taps.stream;

  @override
  Future<bool> takeLaunchTap() async {
    final v = launchedByTap;
    launchedByTap = false;
    return v;
  }
}

const _enabled = ReminderSettings(
  enabled: true,
  days: {1, 3, 5},
  time: TimeOfDay(hour: 19, minute: 0),
);

/// Сессиясы жоқ, болашақтағы күн: «бүгін жаттықты» шарты орындалмайды.
final _future = DateTime(2030, 1, 7, 12);

String _location(WidgetTester tester) =>
    GoRouter.of(tester.element(find.byType(Scaffold).last)).state.uri
        .toString();

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({'auth.userId': 1}));

  group('ReminderPlan: мәтін мен экран деректерден', () {
    test('соңғы толық сессиядағы ең әлсіз тақырып', () async {
      final s = await startServices();
      addTearDown(s.dispose);
      final last = s.sessions.lastComplete!;
      final weakest =
          (last.topicScores.entries.toList()
                ..sort((a, b) => a.value.compareTo(b.value)))
              .first;
      final topic = s.topics.byId(weakest.key);

      final plan = ReminderPlan.build(
        active: null,
        history: s.sessions.history,
        topicById: s.topics.tryById,
        now: _future,
      );

      expect(plan.kind, ReminderKind.weakTopic);
      expect(plan.title, S.reminderWeakTitle);
      expect(plan.body, contains(topic.title));
      final route = Uri.parse(plan.route);
      expect(route.path, Routes.practiceSetup);
      expect(route.queryParameters['topics'], topic.id);
      expect(route.queryParameters['direction'], topic.direction.name);
      expect(plan.skipToday, isFalse);
    });

    test('аяқталмаған сессия бірінші: жалғастыру экраны', () async {
      final s = await startServices();
      addTearDown(s.dispose);
      final topic = s.topics.all.first;
      final active = InterviewSession(
        id: 'active',
        direction: topic.direction,
        level: topic.level,
        language: s.auth.user!.interviewLanguage,
        topicIds: [topic.id],
        answers: [
          for (final q in s.topics.questionsFor(topic.id).take(3))
            AnswerRecord(question: q),
        ],
        startedAt: _future,
      )..currentIndex = 1;

      final plan = ReminderPlan.build(
        active: active,
        history: s.sessions.history,
        topicById: s.topics.tryById,
        now: _future,
      );

      expect(plan.kind, ReminderKind.resume);
      expect(plan.route, Routes.interview);
      expect(plan.body, contains(S.progressOf(2, 3)));
    });

    test('тарих бос: жалпы мәтін, тақырып таңдау', () {
      final plan = ReminderPlan.build(
        active: null,
        history: const [],
        topicById: (_) => null,
        now: _future,
      );
      expect(plan.kind, ReminderKind.generic);
      expect(plan.title, S.reminderNotificationTitle);
      expect(plan.route, Routes.practiceTopics);
    });

    test('бүгін сессия аяқталса — бүгінгі еске салу өткізіледі', () async {
      final s = await startServices();
      addTearDown(s.dispose);
      final day = s.sessions.history.first.startedAt;
      ReminderPlan at(DateTime now) => ReminderPlan.build(
        active: null,
        history: s.sessions.history,
        topicById: s.topics.tryById,
        now: now,
      );
      expect(
        at(DateTime(day.year, day.month, day.day, 23, 59)).skipToday,
        isTrue,
      );
      expect(at(_future).skipToday, isFalse);
    });
  });

  group('ReminderCoordinator: кесте деректермен бірге өзгереді', () {
    Future<(ReminderCoordinator, FakeScheduler, dynamic)> setup({
      bool permitted = true,
      DateTime? now,
    }) async {
      final s = await startServices();
      final fake = FakeScheduler(permitted: permitted);
      final c = ReminderCoordinator(
        auth: s.auth,
        settings: s.settings,
        sessions: s.sessions,
        topics: s.topics,
        scheduler: fake,
        clock: () => now ?? _future,
      );
      addTearDown(() async {
        c.dispose();
        await s.dispose();
      });
      return (c, fake, s);
    }

    test(
      'өшірулі → ештеңе жоспарланбайды; қосылса → деректерге сай мәтін',
      () async {
        final (c, fake, s) = await setup();
        await c.refresh();
        expect(fake.scheduled, isEmpty);
        expect(fake.cancels, 1);

        await s.settings.setReminders(_enabled);
        await c.refresh();
        expect(fake.scheduled, hasLength(1));
        // Демо аккаунтта аяқталмаған сессия бар (2 / 5) — соны еске саламыз.
        expect(fake.scheduled.single.title, S.reminderResumeTitle);
        expect(fake.scheduled.single.body, contains(S.progressOf(2, 5)));
        expect(fake.scheduled.single.days, {1, 3, 5});
        expect(fake.scheduled.single.notBefore, isNull);

        // Деректер өзгермесе — қайта жоспарламаймыз.
        await c.refresh();
        expect(fake.scheduled, hasLength(1));
      },
    );

    test(
      'рұқсат жоқ → жоспарланбайды, рұқсат берілгенде → жоспарланады',
      () async {
        final (c, fake, s) = await setup(permitted: false);
        await s.settings.setReminders(_enabled);
        await c.refresh();
        expect(fake.scheduled, isEmpty);

        fake.permitted = true;
        await c.refresh(force: true);
        expect(fake.scheduled, hasLength(1));
      },
    );

    test('сессия аяқталса не жойылса → мәтін қайта есептеледі', () async {
      final (c, fake, s) = await setup();
      await s.settings.setReminders(_enabled);
      await c.refresh();
      expect(fake.scheduled.last.title, S.reminderResumeTitle);

      // Аяқталмаған сессия тоқтатылды → енді әлсіз тақырып.
      await s.sessions.finishActive();
      await c.refresh();
      expect(fake.scheduled, hasLength(2));
      expect(fake.scheduled.last.title, S.reminderWeakTitle);

      // Бүкіл тарих жойылды → жалпы мәтін.
      for (final session in [...s.sessions.history]) {
        await s.sessions.delete(session.id);
      }
      await c.refresh();
      expect(fake.scheduled, hasLength(3));
      expect(fake.scheduled.last.title, S.reminderNotificationTitle);
    });

    test('бүгін жаттықса → ертеңнен бастап', () async {
      SharedPreferences.setMockInitialValues({'auth.userId': 1});
      final probe = await startServices();
      final day = probe.sessions.history.first.startedAt;
      await probe.dispose();

      final (c, fake, s) = await setup(
        now: DateTime(day.year, day.month, day.day, 20),
      );
      await s.settings.setReminders(_enabled);
      await c.refresh();
      expect(
        fake.scheduled.single.notBefore,
        DateTime(day.year, day.month, day.day + 1),
      );
    });

    test('аккаунттан шыққанда → барлық хабарлама өшіріледі', () async {
      final (c, fake, s) = await setup();
      await s.settings.setReminders(_enabled);
      await c.refresh();
      final cancels = fake.cancels;
      await s.auth.logout();
      await c.refresh();
      expect(fake.cancels, cancels + 1);
      // Кірмеген пайдаланушыға басу ештеңе ашпайды.
      expect(await c.takeLaunchRoute(), isNull);
    });
  });

  group('Хабарламаны басу', () {
    testWidgets('ашық қосымшада → аяқталмаған сессия ашылады', (tester) async {
      final fake = FakeScheduler();
      await pumpApp(tester, location: Routes.home, reminders: fake);
      fake.tap();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
      expect(_location(tester), Routes.interview);
    });

    testWidgets('хабарлама қосымшаны іске қосса → Splash → Home → экран', (
      tester,
    ) async {
      final fake = FakeScheduler(launchedByTap: true);
      await pumpApp(tester, location: Routes.splash, reminders: fake);
      await tester.pump(const Duration(seconds: 2));
      await tester.pump(const Duration(milliseconds: 600));
      expect(_location(tester), Routes.interview);
      // Астында — басты бет: артқа шыққанда сонда ораламыз.
      final router = GoRouter.of(tester.element(find.byType(Scaffold).last));
      expect(router.canPop(), isTrue);
    });
  });

  group('Рұқсат', () {
    testWidgets('берілді → кесте жоспарланды, «Еске салу қосулы»', (
      tester,
    ) async {
      final fake = FakeScheduler(permitted: false)..permitted = true;
      await pumpApp(tester, location: Routes.reminders, reminders: fake);
      await tester.tap(find.byType(Switch));
      await tester.pump();
      await tester.tap(find.text(S.remindersSave));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
      expect(find.text(S.remindersEnabledTitle), findsOneWidget);
      expect(fake.scheduled, isNotEmpty);
      expect(fake.scheduled.last.title, isNot(isEmpty));
    });

    testWidgets(
      'берілмеді → «рұқсат жоқ»; баптаудан рұқсатпен оралса → қосулы',
      (tester) async {
        final fake = FakeScheduler(permitted: false);
        await pumpApp(tester, location: Routes.reminders, reminders: fake);
        await tester.tap(find.byType(Switch));
        await tester.pump();
        await tester.tap(find.text(S.remindersSave));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 600));
        expect(fake.requests, 1);
        expect(fake.scheduled, isEmpty);
        expect(find.text(S.notificationsOffTitle), findsOneWidget);

        await tester.tap(find.text(S.openAndroidSettings));
        await tester.pump();
        expect(fake.settingsOpened, 1);

        // Пайдаланушы Android баптауында рұқсат беріп, қосымшаға оралды.
        fake.permitted = true;
        tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.inactive,
        );
        tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
        tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
        tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
        tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.inactive,
        );
        tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.resumed,
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 600));
        expect(find.text(S.remindersEnabledTitle), findsOneWidget);
        expect(fake.scheduled, isNotEmpty);
      },
    );
  });

  group('Экрандарға қолжетімділік', () {
    // Кірмеген пайдаланушы үшін жабық маршруттар (параметрлілері — мысалмен).
    const protected = [
      Routes.home,
      Routes.history,
      Routes.progress,
      Routes.settings,
      Routes.topics,
      Routes.topicNew,
      '/topics/dart-basics',
      '/topics/dart-basics/edit',
      Routes.search,
      Routes.favorites,
      Routes.profile,
      Routes.profileEdit,
      Routes.profileSetup,
      Routes.practiceTopics,
      Routes.practiceSetup,
      Routes.consent,
      Routes.preparing,
      Routes.activeConflict,
      Routes.interview,
      Routes.feedback,
      '/sessions/s1',
      '/sessions/s1/answers',
      Routes.appearance,
      Routes.reminders,
      Routes.notificationsDenied,
      Routes.privacy,
      Routes.sync,
      Routes.cloudTopics,
      Routes.deleteAccount,
    ];

    testWidgets('кірмеген → әр жабық маршрут «Таныстыру» экранына', (
      tester,
    ) async {
      for (final path in protected) {
        await tester.pumpWidget(const SizedBox()); // жаңа роутер
        await pumpApp(tester, location: path, loggedIn: false);
        expect(_location(tester), Routes.welcome, reason: path);
      }
    });

    testWidgets('кірмеген → ашық маршруттар ашылады', (tester) async {
      for (final path in [
        Routes.login,
        Routes.register,
        Routes.forgotPassword,
      ]) {
        await tester.pumpWidget(const SizedBox()); // жаңа роутер
        await pumpApp(tester, location: path, loggedIn: false);
        expect(_location(tester), path);
      }
    });

    testWidgets('кірген → кіру/тіркелу/таныстыру басты бетке', (tester) async {
      for (final path in [Routes.welcome, Routes.login, Routes.register]) {
        await tester.pumpWidget(const SizedBox()); // жаңа роутер
        await pumpApp(tester, location: path);
        expect(_location(tester), Routes.home, reason: path);
      }
    });
  });

  testWidgets('қайта іске қосу: кіру сақталады → Splash-тан бірден Home', (
    tester,
  ) async {
    final dir = Directory.systemTemp.createTempSync('intrvue_restart');
    addTearDown(() => dir.deleteSync(recursive: true));
    final path = '${dir.path}/app.db';
    SharedPreferences.setMockInitialValues({'onboarding.seen': true});

    // 1-іске қосу: кіру.
    final first = (await tester.runAsync(() => startServices(path: path)))!;
    expect(first.auth.isLoggedIn, isFalse);
    final error = await tester.runAsync(
      () => first.auth.login('aidana@example.com', 'intrvue2026'),
    );
    expect(error, isNull);
    await tester.runAsync(first.dispose);

    // 2-іске қосу: сол SharedPreferences және сол файл.
    final second = (await tester.runAsync(() => startServices(path: path)))!;
    addTearDown(() => tester.runAsync(second.dispose));
    expect(second.auth.isLoggedIn, isTrue);
    expect(second.auth.user!.email, 'aidana@example.com');

    await tester.pumpWidget(IntRvueApp(services: second));
    await tester.pump(const Duration(seconds: 2));
    await tester.pump(const Duration(milliseconds: 600));
    expect(_location(tester), Routes.home);
    expect(find.text(S.greeting('Айдана')), findsOneWidget);
  });
}
