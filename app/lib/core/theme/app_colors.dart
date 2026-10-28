import 'package:flutter/material.dart';

/// Figma «Design system & components» (16:400) түс рөлдері.
/// Material 3 тональды палитрасы, seed — жасыл.
abstract final class AppColors {
  static const ColorScheme light = ColorScheme(
    brightness: Brightness.light,
    primary: Color(0xFF006C4C),
    onPrimary: Color(0xFFFFFFFF),
    primaryContainer: Color(0xFF89F8C6),
    onPrimaryContainer: Color(0xFF002114),
    secondary: Color(0xFF4D6357),
    onSecondary: Color(0xFFFFFFFF),
    secondaryContainer: Color(0xFFCFE9D9),
    onSecondaryContainer: Color(0xFF0A1F16),
    tertiary: Color(0xFF795219),
    onTertiary: Color(0xFFFFFFFF),
    tertiaryContainer: Color(0xFFF3E9D3),
    onTertiaryContainer: Color(0xFF795219),
    error: Color(0xFFBA1A1A),
    onError: Color(0xFFFFFFFF),
    errorContainer: Color(0xFFFFDAD6),
    onErrorContainer: Color(0xFF410002),
    surface: Color(0xFFFBFDF9),
    onSurface: Color(0xFF191C1A),
    surfaceContainerLowest: Color(0xFFFFFFFF),
    surfaceContainerLow: Color(0xFFF5F7F3),
    surfaceContainer: Color(0xFFEFF1ED),
    surfaceContainerHigh: Color(0xFFE9EBE7),
    surfaceContainerHighest: Color(0xFFDBE5DD),
    onSurfaceVariant: Color(0xFF404943),
    outline: Color(0xFF707973),
    outlineVariant: Color(0xFFBFC9C2),
    inverseSurface: Color(0xFF2E312F),
    onInverseSurface: Color(0xFFEFF1ED),
    inversePrimary: Color(0xFF6CDBAB),
    shadow: Color(0xFF000000),
    scrim: Color(0xFF000000),
  );

  static const ColorScheme dark = ColorScheme(
    brightness: Brightness.dark,
    primary: Color(0xFF6CDBAB),
    onPrimary: Color(0xFF003826),
    primaryContainer: Color(0xFF005138),
    onPrimaryContainer: Color(0xFF89F8C6),
    secondary: Color(0xFFB3CCBE),
    onSecondary: Color(0xFF1F352A),
    secondaryContainer: Color(0xFF354B40),
    onSecondaryContainer: Color(0xFFCFE9D9),
    tertiary: Color(0xFFF2BD7A),
    onTertiary: Color(0xFF452B00),
    tertiaryContainer: Color(0xFF633F05),
    onTertiaryContainer: Color(0xFFFFDDB6),
    error: Color(0xFFFFB4AB),
    onError: Color(0xFF690005),
    errorContainer: Color(0xFF93000A),
    onErrorContainer: Color(0xFFFFDAD6),
    surface: Color(0xFF191C1A),
    onSurface: Color(0xFFE1E3DF),
    surfaceContainerLowest: Color(0xFF0F1110),
    surfaceContainerLow: Color(0xFF191C1A),
    surfaceContainer: Color(0xFF1D201E),
    surfaceContainerHigh: Color(0xFF2B2F2C),
    surfaceContainerHighest: Color(0xFF404943),
    onSurfaceVariant: Color(0xFFBFC9C2),
    outline: Color(0xFF8A938C),
    outlineVariant: Color(0xFF404943),
    inverseSurface: Color(0xFFE1E3DF),
    onInverseSurface: Color(0xFF2E312F),
    inversePrimary: Color(0xFF006C4C),
    shadow: Color(0xFF000000),
    scrim: Color(0xFF000000),
  );
}

/// ColorScheme-де жоқ қосымша рөлдер: ескерту, диаграмма, навигация фоны.
@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.warningContainer,
    required this.onWarningContainer,
    required this.chartMuted,
    required this.navigationBar,
    required this.disabledContainer,
    required this.onDisabled,
    required this.scrim,
  });

  final Color warningContainer;
  final Color onWarningContainer;
  final Color chartMuted;
  final Color navigationBar;
  final Color disabledContainer;
  final Color onDisabled;
  final Color scrim;

  static const light = AppPalette(
    warningContainer: Color(0xFFF3E9D3),
    onWarningContainer: Color(0xFF795219),
    chartMuted: Color(0xFF4D6357),
    navigationBar: Color(0xFFDBE5DD),
    disabledContainer: Color(0xFFE0E2DE),
    onDisabled: Color(0xFFA5A8A4),
    scrim: Color(0x80191C1A),
  );

  static const dark = AppPalette(
    warningContainer: Color(0xFF633F05),
    onWarningContainer: Color(0xFFFFDDB6),
    chartMuted: Color(0xFF8A938C),
    navigationBar: Color(0xFF404943),
    disabledContainer: Color(0xFF313431),
    onDisabled: Color(0xFF656866),
    scrim: Color(0x99000000),
  );

  @override
  AppPalette copyWith({
    Color? warningContainer,
    Color? onWarningContainer,
    Color? chartMuted,
    Color? navigationBar,
    Color? disabledContainer,
    Color? onDisabled,
    Color? scrim,
  }) {
    return AppPalette(
      warningContainer: warningContainer ?? this.warningContainer,
      onWarningContainer: onWarningContainer ?? this.onWarningContainer,
      chartMuted: chartMuted ?? this.chartMuted,
      navigationBar: navigationBar ?? this.navigationBar,
      disabledContainer: disabledContainer ?? this.disabledContainer,
      onDisabled: onDisabled ?? this.onDisabled,
      scrim: scrim ?? this.scrim,
    );
  }

  @override
  AppPalette lerp(AppPalette? other, double t) {
    if (other == null) return this;
    return AppPalette(
      warningContainer: Color.lerp(
        warningContainer,
        other.warningContainer,
        t,
      )!,
      onWarningContainer: Color.lerp(
        onWarningContainer,
        other.onWarningContainer,
        t,
      )!,
      chartMuted: Color.lerp(chartMuted, other.chartMuted, t)!,
      navigationBar: Color.lerp(navigationBar, other.navigationBar, t)!,
      disabledContainer: Color.lerp(
        disabledContainer,
        other.disabledContainer,
        t,
      )!,
      onDisabled: Color.lerp(onDisabled, other.onDisabled, t)!,
      scrim: Color.lerp(scrim, other.scrim, t)!,
    );
  }
}

extension AppThemeX on BuildContext {
  ColorScheme get colors => Theme.of(this).colorScheme;
  TextTheme get text => Theme.of(this).textTheme;
  AppPalette get palette => Theme.of(this).extension<AppPalette>()!;
}
