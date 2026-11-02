/// Figma «v2 / Size»: 412 × 892 экран, 16 шет, 4 dp қадам.
abstract final class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double smd = 12;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;

  /// Экран шеті (content inset).
  static const double inset = 16;

  /// size/control — батырма мен өріс биіктігі.
  static const double controlHeight = 48;

  /// size/touch — ең кіші сенсорлық аймақ.
  static const double touchTarget = 48;

  /// stroke/hairline.
  static const double hairline = 1;

  /// Кең экранда мазмұн осы еннен аспайды.
  static const double maxContentWidth = 560;

  /// Осы еннен бастап NavigationBar орнына NavigationRail қолданылады.
  static const double railBreakpoint = 600;
}

/// Figma «v2 / Size» radius/*.
abstract final class AppRadius {
  /// Ревью белгісі «!», чекбокс.
  static const double mark = 4;

  /// Тег, бейдж.
  static const double tag = 6;

  /// Рубрика ұяшығы.
  static const double cell = 8;

  /// Чип.
  static const double chip = 10;

  /// Батырма, өріс, сегмент, snackbar, мәзір.
  static const double control = 12;

  /// Карточка, тізім тобы.
  static const double card = 16;

  /// Диалог, төменгі парақ, панельдің жоғарғы бұрыштары.
  static const double sheet = 24;

  static const double pill = 999;

  // Ескі атаулар — экрандар көшкенше.
  static const double field = control;
  static const double snackbar = control;
  static const double choice = control;
  static const double button = control;
  static const double dialog = sheet;
}
