/// Figma өлшемдері: 412 × 892 экран, 24 шет, 8 dp қадам.
abstract final class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;

  /// Экран шеті (content inset).
  static const double inset = 24;

  /// Батырма мен өріс биіктігі.
  static const double controlHeight = 56;

  /// Таңдау чипінің биіктігі, ең кіші сенсорлық аймақ.
  static const double touchTarget = 48;

  /// Кең экранда мазмұн осы еннен аспайды.
  static const double maxContentWidth = 560;

  /// Осы еннен бастап NavigationBar орнына NavigationRail қолданылады.
  static const double railBreakpoint = 600;
}

abstract final class AppRadius {
  static const double field = 4;
  static const double snackbar = 4;
  static const double chip = 8;
  static const double choice = 12;
  static const double card = 16;
  static const double button = 28;
  static const double dialog = 28;
}
