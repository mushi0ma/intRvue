// Әр экранның 412 × 892 скриншоты — Figma макеттерімен салыстыру үшін.
// Жаңарту: flutter test --update-goldens test/screens_golden_test.dart
@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:intrvue/data/models/enums.dart';
import 'package:intrvue/data/repositories/session_repository.dart';

import 'helpers/test_app.dart';

class _Case {
  const _Case(
    this.name,
    this.location, {
    this.loggedIn = true,
    this.prefs = const {},
    this.noFavorites = false,
  });
  final String name;
  final String location;
  final bool noFavorites;
  final bool loggedIn;
  final Map<String, Object> prefs;
}

const _cases = [
  _Case('S00_splash', '/splash', loggedIn: false),
  _Case(
    'O1_onboarding',
    '/onboarding',
    loggedIn: false,
    prefs: {'onboarding.seen': false},
  ),
  _Case('S01_welcome', '/welcome', loggedIn: false),
  _Case('S02_login', '/login', loggedIn: false),
  _Case('S03_register', '/register', loggedIn: false),
  _Case('S04_forgot_password', '/forgot-password', loggedIn: false),
  _Case(
    'S04_reset_sent',
    '/forgot-password/sent?email=aidana@example.com'
        '&at=1792422960000', // 19.10.2026 20:16 (жергілікті уақыт)
    loggedIn: false,
  ),
  _Case('S05_profile_setup', '/profile-setup'),
  _Case('S06_home', '/home'),
  _Case(
    'S08_session_setup',
    '/practice/setup?direction=mobile&topics=dart-basics,flutter-widgets',
  ),
  _Case('S08_consent', '/practice/consent'),
  _Case('S06_active_session', '/practice/active'),
  _Case('S09_interview', '/interview'),
  _Case('S11_summary', '/sessions/s-1019'),
  _Case('S11_incomplete', '/sessions/s-1015'),
  _Case('S12_recommendations', '/sessions/s-1019/recommendations'),
  _Case('S13_history', '/history'),
  _Case('S13_session_answers', '/sessions/s-1019/answers'),
  _Case('S13_saved_answer', '/sessions/s-1019/answers/1'),
  _Case('S10_model_answer', '/sessions/s-1019/answers/1/model'),
  _Case('S10_dispute', '/sessions/s-1019/answers/1/dispute'),
  _Case('S14_progress', '/progress'),
  _Case('S15_appearance', '/settings/appearance'),
  _Case('S15_reminders', '/settings/reminders'),
  _Case('S15_privacy', '/settings/privacy'),
  _Case('S15_delete_account', '/settings/delete-account'),
  _Case('S16_topic_catalog', '/topics'),
  _Case('S17_topic_detail', '/topics/flutter-widgets'),
  _Case('S18_search', '/search'),
  _Case('S19_favorites', '/favorites'),
  _Case('F1_profile', '/profile'),
  _Case('S22_edit_profile', '/profile/edit'),
  _Case('S23_favorites_empty', '/favorites', noFavorites: true),
  _Case('S25_topic_create', '/topics/new'),
];

void main() {
  setUpAll(loadFonts);

  for (final theme in [ThemeMode.light, ThemeMode.dark]) {
    for (final c in _cases) {
      testWidgets('${theme.name} ${c.name}', (tester) async {
        await pumpApp(
          tester,
          location: c.location,
          loggedIn: c.loggedIn,
          prefs: c.prefs,
          noFavorites: c.noFavorites,
          theme: theme,
        );
        await expectLater(
          find.byType(MaterialApp),
          matchesGoldenFile('goldens/${theme.name}/${c.name}.png'),
        );
        // Splash таймері мен анимацияларды аяқтау.
        await tester.pump(const Duration(seconds: 3));
      });
    }

    testWidgets('${theme.name} S10_feedback', (tester) async {
      await pumpApp(tester, location: '/interview', theme: theme);
      await tester.tap(find.text('Жауапты жіберу'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      await tester.pump(const Duration(milliseconds: 500));
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/${theme.name}/S10_feedback.png'),
      );
    });

    testWidgets('${theme.name} S08_preparing', (tester) async {
      await pumpApp(tester, location: '/home', theme: theme);
      repo<SessionRepository>(tester).pending = const PracticeRequest(
        direction: Direction.mobile,
        level: Level.beginner,
        language: InterviewLanguage.kk,
        topicIds: ['dart-basics', 'flutter-widgets'],
        questionCount: 5,
      );
      await tester.runAsync(repo<SessionRepository>(tester).finishActive);
      await tester.pump();
      GoRouter.of(tester.element(find.byType(Scaffold).first))
          .push('/practice/preparing');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/${theme.name}/S08_preparing.png'),
      );
      await tester.pump(const Duration(seconds: 3));
    });

    testWidgets('${theme.name} S02_login_error', (tester) async {
      await pumpApp(tester, location: '/login', loggedIn: false, theme: theme);
      await tester.enterText(
        find.byType(TextFormField).at(0),
        'aidana@example',
      );
      await tester.tap(find.text('Кіру').last);
      await tester.pump(const Duration(milliseconds: 300));
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/${theme.name}/S02_login_validation.png'),
      );
      await tester.enterText(
        find.byType(TextFormField).at(0),
        'aidana@example.com',
      );
      await tester.enterText(find.byType(TextFormField).at(1), 'wrong-pass1');
      await tester.tap(find.text('Кіру').last);
      await tester.pump(const Duration(milliseconds: 600));
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/${theme.name}/S02_login_error.png'),
      );
    });
  }

  // Бейімділік: тар экран (360), кең экран (NavigationRail) және 200% мәтін.
  // Мазмұн сыймай қалса (RenderFlex overflow), тест құлайды.
  const adaptive = [
    ('home', '/home'),
    ('login', '/login'),
    ('interview', '/interview'),
    ('summary', '/sessions/s-1019'),
    ('progress', '/progress'),
    ('profile_setup', '/profile-setup'),
  ];
  for (final (name, location) in adaptive) {
    final loggedIn = location != '/login';
    testWidgets('adaptive 360 text200 $name', (tester) async {
      await pumpApp(
        tester,
        location: location,
        loggedIn: loggedIn,
        size: const Size(360, 800),
        textScale: 2,
      );
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/adaptive/360_text200_$name.png'),
      );
    });
    testWidgets('adaptive 800 $name', (tester) async {
      await pumpApp(
        tester,
        location: location,
        loggedIn: loggedIn,
        size: const Size(800, 1280),
      );
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/adaptive/800_$name.png'),
      );
    });
  }
}
