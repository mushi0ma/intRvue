// Flutter accessibility guidelines on every route, light and dark:
// tap targets ≥ 48 dp, labelled tap targets, text contrast.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/contrast_guideline.dart';
import 'helpers/test_app.dart';

const _routes = <(String, bool)>[
  ('/welcome', false),
  ('/login', false),
  ('/register', false),
  ('/forgot-password', false),
  ('/onboarding', false),
  ('/profile-setup', true),
  ('/home', true),
  ('/history', true),
  ('/progress', true),
  ('/settings', true),
  ('/topics', true),
  ('/topics/new', true),
  ('/topics/flutter-widgets', true),
  ('/search', true),
  ('/favorites', true),
  ('/profile', true),
  ('/profile/edit', true),
  ('/practice/topics', true),
  ('/practice/setup?direction=mobile&topics=dart-basics', true),
  ('/practice/consent', true),
  ('/practice/active', true),
  ('/interview', true),
  ('/sessions/s-1019', true),
  ('/sessions/s-1015', true),
  ('/sessions/s-1019/recommendations', true),
  ('/sessions/s-1019/answers', true),
  ('/sessions/s-1019/answers/1', true),
  ('/sessions/s-1019/answers/1/model', true),
  ('/sessions/s-1019/answers/1/dispute', true),
  ('/settings/appearance', true),
  ('/settings/reminders', true),
  ('/settings/privacy', true),
  ('/settings/delete-account', true),
];

void main() {
  setUpAll(loadFonts);

  for (final theme in [ThemeMode.light, ThemeMode.dark]) {
    for (final (route, loggedIn) in _routes) {
      testWidgets('a11y ${theme.name} $route', (tester) async {
        final handle = tester.ensureSemantics();
        await pumpApp(
          tester,
          location: route,
          loggedIn: loggedIn,
          theme: theme,
        );
        await tester.pump(const Duration(milliseconds: 400));
        await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
        await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
        // Flutter-дің textContrastGuideline экранды 1×-те өлшейді — жіңішке
        // Medeo штрихы толық тегістеліп, жалған қате береді. Сол алгоритм,
        // бірақ 3× тығыздықта (helpers/contrast_guideline.dart).
        await expectLater(tester, meetsGuideline(hiDpiTextContrastGuideline));
        handle.dispose();
        await tester.pump(const Duration(seconds: 3));
      });
    }
  }
}
