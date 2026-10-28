import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/models/enums.dart';
import '../data/repositories/auth_repository.dart';
import '../features/auth/forgot_password_screen.dart';
import '../features/auth/login_screen.dart';
import '../features/auth/register_screen.dart';
import '../features/auth/welcome_screen.dart';
import '../features/history/history_screen.dart';
import '../features/home/home_screen.dart';
import '../features/interview/active_session_screen.dart';
import '../features/interview/consent_screen.dart';
import '../features/interview/feedback_screen.dart';
import '../features/interview/interview_screen.dart';
import '../features/interview/preparing_screen.dart';
import '../features/interview/session_setup_screen.dart';
import '../features/interview/topic_selection_screen.dart';
import '../features/onboarding/onboarding_screen.dart';
import '../features/profile/edit_profile_screen.dart';
import '../features/profile/profile_screen.dart';
import '../features/profile/profile_setup_screen.dart';
import '../features/progress/progress_screen.dart';
import '../features/results/dispute_screen.dart';
import '../features/results/model_answer_screen.dart';
import '../features/results/recommendations_screen.dart';
import '../features/results/saved_answer_screen.dart';
import '../features/results/session_answers_screen.dart';
import '../features/results/summary_screen.dart';
import '../features/settings/appearance_screen.dart';
import '../features/settings/delete_account_screen.dart';
import '../features/settings/privacy_screen.dart';
import '../features/settings/reminder_status_screens.dart';
import '../features/settings/reminders_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/splash/splash_screen.dart';
import '../features/topics/favorites_screen.dart';
import '../features/topics/search_screen.dart';
import '../features/topics/topic_catalog_screen.dart';
import '../features/topics/topic_detail_screen.dart';
import '../features/topics/topic_form_screen.dart';
import 'app_shell.dart';
import 'routes.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');

/// Барлық экран мен өтулер. Кірмеген пайдаланушы тек ашық
/// маршруттарды көреді, қалғаны «Таныстыру» экранына бағытталады.
GoRouter buildRouter(AuthRepository auth, {String initial = Routes.splash}) {
  GoRoute route(String path, Widget Function(GoRouterState s) build) =>
      GoRoute(path: path, builder: (context, state) => build(state));

  int index(GoRouterState s) => int.parse(s.pathParameters['index']!);
  String id(GoRouterState s) => s.pathParameters['id']!;

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: initial,
    redirect: (context, state) {
      final location = state.matchedLocation;
      final isPublic = Routes.public.contains(location);
      if (!auth.isLoggedIn && !isPublic) return Routes.welcome;
      if (auth.isLoggedIn &&
          (location == Routes.welcome ||
              location == Routes.login ||
              location == Routes.register)) {
        return Routes.home;
      }
      return null;
    },
    routes: [
      route(Routes.splash, (_) => const SplashScreen()),
      route(Routes.onboarding, (_) => const OnboardingScreen()),
      route(Routes.welcome, (_) => const WelcomeScreen()),
      route(Routes.login, (_) => const LoginScreen()),
      route(Routes.register, (_) => const RegisterScreen()),
      route(Routes.forgotPassword, (_) => const ForgotPasswordScreen()),
      route(
        Routes.resetSent,
        (s) => ResetSentScreen(
          email: s.uri.queryParameters['email'] ?? '',
          token: s.uri.queryParameters['token'],
        ),
      ),
      // Сілтеме: intrvue://app/reset-password?token=…
      route(
        Routes.resetPassword,
        (s) => NewPasswordScreen(token: s.uri.queryParameters['token'] ?? ''),
      ),
      route(Routes.profileSetup, (_) => const ProfileSetupScreen()),

      // Төменгі навигациясы бар төрт бөлім. Әр бөлім өз стегін сақтайды.
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => AppShell(navigationShell: shell),
        branches: [
          StatefulShellBranch(
            routes: [route(Routes.home, (_) => const HomeScreen())],
          ),
          StatefulShellBranch(
            routes: [route(Routes.history, (_) => const HistoryScreen())],
          ),
          StatefulShellBranch(
            routes: [route(Routes.progress, (_) => const ProgressScreen())],
          ),
          StatefulShellBranch(
            routes: [route(Routes.settings, (_) => const SettingsScreen())],
          ),
        ],
      ),

      // Толық экранды беттер — навигация жолағын жабады.
      route(Routes.topics, (_) => const TopicCatalogScreen()),
      // Create/Edit: '/topics/new' '/topics/:id'-ден бұрын тұруы керек.
      route(Routes.topicNew, (_) => const TopicFormScreen()),
      route('/topics/:id', (s) => TopicDetailScreen(topicId: id(s))),
      route('/topics/:id/edit', (s) => TopicFormScreen(topicId: id(s))),
      route(Routes.search, (_) => const SearchScreen()),
      route(Routes.favorites, (_) => const FavoritesScreen()),
      route(Routes.profile, (_) => const ProfileScreen()),
      route(Routes.profileEdit, (_) => const EditProfileScreen()),

      route(
        Routes.practiceTopics,
        (s) => TopicSelectionScreen(
          direction: _direction(s.uri.queryParameters['direction']),
        ),
      ),
      route(
        Routes.practiceSetup,
        (s) => SessionSetupScreen(
          direction: _direction(s.uri.queryParameters['direction']),
          topicIds: (s.uri.queryParameters['topics'] ?? '')
              .split(',')
              .where((t) => t.isNotEmpty)
              .toList(),
        ),
      ),
      route(Routes.consent, (_) => const ConsentScreen()),
      route(Routes.preparing, (_) => const PreparingScreen()),
      route(Routes.activeConflict, (_) => const ActiveSessionScreen()),
      route(Routes.interview, (_) => const InterviewScreen()),
      route(Routes.feedback, (_) => const FeedbackScreen()),

      route('/sessions/:id', (s) => SummaryScreen(sessionId: id(s))),
      route(
        '/sessions/:id/recommendations',
        (s) => RecommendationsScreen(sessionId: id(s)),
      ),
      route(
        '/sessions/:id/answers',
        (s) => SessionAnswersScreen(sessionId: id(s)),
      ),
      route(
        '/sessions/:id/answers/:index',
        (s) => SavedAnswerScreen(sessionId: id(s), index: index(s)),
      ),
      route(
        '/sessions/:id/answers/:index/model',
        (s) => ModelAnswerScreen(sessionId: id(s), index: index(s)),
      ),
      route(
        '/sessions/:id/answers/:index/dispute',
        (s) => DisputeScreen(sessionId: id(s), index: index(s)),
      ),

      route(Routes.appearance, (_) => const AppearanceScreen()),
      route(Routes.reminders, (_) => const RemindersScreen()),
      route(Routes.remindersEnabled, (_) => const RemindersEnabledScreen()),
      route(
        Routes.notificationsDenied,
        (_) => const NotificationsDeniedScreen(),
      ),
      route(Routes.privacy, (_) => const PrivacyScreen()),
      route(Routes.deleteAccount, (_) => const DeleteAccountScreen()),
    ],
  );
}

Direction? _direction(String? name) {
  if (name == null) return null;
  for (final d in Direction.values) {
    if (d.name == name) return d;
  }
  return null;
}
