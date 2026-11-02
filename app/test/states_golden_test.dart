// Экран күйлерінің скриншоттары: валидация, диалогтар, хабарламалар,
// бос нәтижелер. UI/UX аудитінде қарау үшін.
// Жаңарту: flutter test --update-goldens test/states_golden_test.dart
@Tags(['golden'])
library;

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:intrvue/app/routes.dart';
import 'package:intrvue/core/constants/app_strings.dart';
import 'package:intrvue/data/local/app_database.dart';
import 'package:intrvue/data/remote/sync_api.dart';
import 'package:intrvue/data/models/enums.dart';
import 'package:intrvue/data/models/topic.dart';
import 'package:intrvue/data/repositories/session_repository.dart';
import 'package:intrvue/data/repositories/topic_repository.dart';

import 'helpers/fake_sync_api.dart';
import 'helpers/test_app.dart';

Future<void> shot(WidgetTester tester, String name) => expectLater(
  find.byType(MaterialApp),
  matchesGoldenFile('goldens/states/$name.png'),
);

Future<void> tap(WidgetTester tester, String text) async {
  await tester.pump();
  final f = find.text(text).evaluate().isEmpty
      ? find.byTooltip(text).last
      : find.text(text).last;
  await tester.ensureVisible(f);
  await tester.pump();
  await tester.tap(f);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
}

Future<void> type(WidgetTester tester, String text, {int index = 0}) async {
  await tester.enterText(find.byType(EditableText).at(index), text);
  await tester.pump(const Duration(milliseconds: 400));
}

void main() {
  setUpAll(loadFonts);

  testWidgets('onboarding pages', (tester) async {
    await pumpApp(tester, location: '/onboarding', loggedIn: false);
    await tap(tester, S.next);
    await shot(tester, 'O2_onboarding');
    await tap(tester, S.next);
    await shot(tester, 'O3_onboarding');
  });

  testWidgets('register validation', (tester) async {
    await pumpApp(tester, location: '/register', loggedIn: false);
    await tap(tester, S.createAccount);
    await shot(tester, 'S03_register_errors');
  });

  testWidgets('forgot password validation', (tester) async {
    await pumpApp(tester, location: '/forgot-password', loggedIn: false);
    await type(tester, 'aidana@');
    await tap(tester, S.resetSend);
    await shot(tester, 'S04_forgot_error');
  });

  testWidgets('home without active session', (tester) async {
    await pumpApp(tester, location: '/home');
    await tester.runAsync(repo<SessionRepository>(tester).finishActive);
    await tester.pump(const Duration(milliseconds: 300));
    await shot(tester, 'S06_home_no_active');
  });

  testWidgets('search results and none', (tester) async {
    await pumpApp(tester, location: '/search');
    await type(tester, 'flutter');
    await shot(tester, 'S18_search_results');
    await type(tester, 'Kubernetes');
    await shot(tester, 'S24_search_none');
  });

  testWidgets('catalog filtered empty', (tester) async {
    await pumpApp(tester, location: '/topics');
    await tester.pump(const Duration(milliseconds: 300));
    await tap(tester, S.filterMine);
    await shot(tester, 'S16_catalog_mine_empty');
  });

  testWidgets('detail favorite snackbar', (tester) async {
    await pumpApp(tester, location: '/topics/async');
    await tap(tester, S.addFavorite);
    await shot(tester, 'S21_detail_snackbar');
  });

  testWidgets('topic form validation', (tester) async {
    await pumpApp(tester, location: '/topics/new');
    await tap(tester, S.addTopic);
    await shot(tester, 'S25_topic_form_errors');
  });

  testWidgets('custom topic detail and edit', (tester) async {
    await pumpApp(tester, location: '/home');
    final topic = await tester.runAsync(
      () => repo<TopicRepository>(tester).create(
        const TopicDraft(
          title: 'Flutter анимациялары',
          summary: 'Implicit, explicit, Hero',
          description: '',
          direction: Direction.mobile,
          level: Level.junior,
          reviewPoints: ['AnimationController', 'Hero өтуі'],
          questions: [
            QuestionDraft(
              text: 'AnimationController-ді қашан dispose ету керек?',
              modelAnswer: 'State dispose() әдісінде.',
            ),
          ],
        ),
      ),
    );
    GoRouter.of(tester.element(find.byType(Scaffold).first))
        .push('/topics/${topic!.id}');
    await tester.pump(const Duration(milliseconds: 600));
    await shot(tester, 'S26_custom_topic_detail');
    await tap(tester, S.edit);
    await shot(tester, 'S27_topic_edit');
  });

  testWidgets('dialogs', (tester) async {
    await pumpApp(tester, location: '/profile');
    await tap(tester, S.logout);
    await shot(tester, 'D1_logout_dialog');
  });

  testWidgets('history delete dialog and filtered empty', (tester) async {
    await pumpApp(tester, location: '/history');
    await tester.tap(find.byTooltip(S.sessionActions).first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    // Мәзір — ең үстіңгі қабат (басқа бөлімдерде де «Жою» мәтіні бар).
    await tester.tap(find.text(S.delete).last);
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 500));
    await shot(tester, 'D2_delete_session_dialog');
  });

  testWidgets('interview skip dialog and empty answer', (tester) async {
    await pumpApp(tester, location: '/interview');
    await tap(tester, S.skipQuestion);
    await shot(tester, 'D3_skip_dialog');
    await tap(tester, S.cancel);
    await type(tester, '');
    await tap(tester, S.submitAnswer);
    await shot(tester, 'S09_interview_empty_error');
  });

  testWidgets('reminders on', (tester) async {
    await pumpApp(tester, location: '/settings/reminders');
    await tester.tap(find.byType(Switch));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await shot(tester, 'S15_reminders_on');
  });

  testWidgets('progress empty', (tester) async {
    await pumpApp(tester, location: '/progress');
    await tap(tester, Level.beginner.label);
    await tap(tester, Level.middle.label);
    await shot(tester, 'S14_progress_empty');
  });

  // Синхрондау күйлері (F9, F13, F17): қосулы, сервер жауап бермейді.
  final linked = {
    'sync.link.1': jsonEncode({
      'email': AppDatabase.demoEmail,
      'token': 'token-${AppDatabase.demoEmail}',
      'lastSyncAt': 1792422960000,
    }),
  };

  Future<void> realWait(WidgetTester tester, {bool Function()? until}) async {
    for (var i = 0; i < 40 && !(until?.call() ?? i >= 3); i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)),
      );
      await tester.pump();
    }
  }

  testWidgets('sync linked', (tester) async {
    await pumpApp(
      tester,
      location: Routes.sync,
      prefs: linked,
      syncApi: (_) => FakeSyncApi(failure: SyncFailure.offline),
    );
    await realWait(tester);
    await shot(tester, 'F9_sync_linked');
  });

  testWidgets('cloud topics offline', (tester) async {
    await pumpApp(
      tester,
      location: Routes.cloudTopics,
      prefs: linked,
      syncApi: (_) => FakeSyncApi(failure: SyncFailure.timeout),
    );
    await realWait(tester);
    await shot(tester, 'F14_cloud_timeout');
  });

  testWidgets('delete account server unavailable', (tester) async {
    await pumpApp(
      tester,
      location: Routes.deleteAccount,
      prefs: linked,
      syncApi: (_) => FakeSyncApi(failure: SyncFailure.offline),
    );
    await tester.enterText(
      find.byType(TextFormField),
      AppDatabase.demoPassword,
    );
    await tester.tap(find.text(S.deleteAccountAction));
    await realWait(
      tester,
      until: () => find.text(S.deleteRemoteTitle).evaluate().isNotEmpty,
    );
    await tester.pump(const Duration(milliseconds: 400));
    await shot(tester, 'F17_delete_server_unavailable');
  });

  // Орыс тіліндегі интерфейс: негізгі экрандар және ұзын мәтіндердің сыюы.
  for (final (name, route, loggedIn) in const [
    ('ru_welcome', '/welcome', false),
    ('ru_login', '/login', false),
    ('ru_home', '/home', true),
    ('ru_history', '/history', true),
    ('ru_profile', '/profile', true),
    ('ru_interview', '/interview', true),
    ('ru_summary', '/sessions/s-1019', true),
    ('ru_catalog', '/topics', true),
  ]) {
    testWidgets('ru $name', (tester) async {
      await pumpApp(
        tester,
        location: route,
        loggedIn: loggedIn,
        prefs: {'settings.language': 'ru'},
      );
      await tester.pump(const Duration(milliseconds: 300));
      await shot(tester, name);
    });
    testWidgets('ru 360 text200 $name', (tester) async {
      await pumpApp(
        tester,
        location: route,
        loggedIn: loggedIn,
        prefs: {'settings.language': 'ru'},
        size: const Size(360, 800),
        textScale: 2,
      );
      await tester.pump(const Duration(milliseconds: 300));
    });
  }
}
