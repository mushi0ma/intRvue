/// Маршрут атаулары бір жерде — экрандар жолдарды қолмен жазбайды.
abstract final class Routes {
  static const splash = '/splash';
  static const onboarding = '/onboarding';
  static const welcome = '/welcome';
  static const login = '/login';
  static const register = '/register';
  static const forgotPassword = '/forgot-password';
  static const resetSent = '/forgot-password/sent';
  static const resetPassword = '/reset-password';
  static const profileSetup = '/profile-setup';

  // Төменгі навигация (StatefulShellRoute): Басты бет, Тақырыптар,
  // Нәтижелер (Тарих | Прогресс), Профиль (баптаулар ішінде).
  static const home = '/home';
  static const topics = '/topics';
  static const results = '/results';
  static const history = '/results?tab=history';
  static const progress = '/results?tab=progress';
  static const profile = '/profile';

  /// Ескі жолдар (хабарландыру, сілтеме) — [results], [profile]-ге бағытталады.
  static const legacyHistory = '/history';
  static const legacyProgress = '/progress';
  static const settings = '/settings';

  // Тақырыптар: Detail, Search, Favorites
  static const topicNew = '/topics/new';
  static String topic(String id) => '/topics/$id';
  static String topicEdit(String id) => '/topics/$id/edit';
  static const search = '/search';
  static const favorites = '/favorites';

  // Профиль: Edit
  static const profileEdit = '/profile/edit';

  // Жаттығу сценарийі
  static const practiceTopics = '/practice/topics';
  static const practiceSetup = '/practice/setup';
  static const consent = '/practice/consent';
  static const preparing = '/practice/preparing';
  static const activeConflict = '/practice/active';
  static const interview = '/interview';
  static const feedback = '/interview-feedback';

  // Аяқталған сессия
  static String summary(String id) => '/sessions/$id';
  static String recommendations(String id) => '/sessions/$id/recommendations';
  static String answers(String id) => '/sessions/$id/answers';
  static String answer(String id, int index) => '/sessions/$id/answers/$index';
  static String modelAnswer(String id, int index) =>
      '/sessions/$id/answers/$index/model';
  static String dispute(String id, int index) =>
      '/sessions/$id/answers/$index/dispute';

  // Баптаулар
  static const appearance = '/settings/appearance';
  static const reminders = '/settings/reminders';
  static const remindersEnabled = '/settings/reminders/enabled';
  static const notificationsDenied = '/settings/notifications-denied';
  static const privacy = '/settings/privacy';
  static const sync = '/settings/sync';
  static const cloudTopics = '/settings/sync/topics';
  static const deleteAccount = '/settings/delete-account';

  /// Кірмеген пайдаланушыға ашық маршруттар.
  static const public = {
    splash,
    onboarding,
    welcome,
    login,
    register,
    forgotPassword,
    resetSent,
    resetPassword,
  };
}
