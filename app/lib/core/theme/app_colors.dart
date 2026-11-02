import 'package:flutter/material.dart';

/// Figma «v2 / Color» айнымалылары (Light / Dark) — Northpoint негізіндегі
/// сия-көк (ink), жасыл акцент және рубрика жолақтары.
///
/// Material рөлдері осылай сәйкестендірілген:
///
/// | v2                  | ColorScheme                  |
/// |---------------------|------------------------------|
/// | bg/canvas           | surface (экран фоны)         |
/// | bg/surface          | surfaceContainerLowest/Low   |
/// | bg/muted            | surfaceContainer/High        |
/// | bg/tonal            | secondaryContainer, Highest  |
/// | bg/primary          | primary (сия)                |
/// | bg/accent           | primaryContainer             |
/// | bg/panel            | inverseSurface               |
/// | bg/warning          | tertiaryContainer            |
/// | text/primary        | onSurface                    |
/// | text/secondary      | onSurfaceVariant, secondary  |
/// | line/strong, subtle | outline, outlineVariant      |
///
/// Қалған рөлдер (навигация, рубрика жолақтары, сызықтар) — [AppPalette].
abstract final class AppColors {
  static const ColorScheme light = ColorScheme(
    brightness: Brightness.light,
    primary: Color(0xFF00262B),
    onPrimary: Color(0xFFFFFFFF),
    primaryContainer: Color(0xFFABFFAE),
    onPrimaryContainer: Color(0xFF00262B),
    secondary: Color(0xFF4A5F62),
    onSecondary: Color(0xFFFFFFFF),
    secondaryContainer: Color(0xFFCDE3E6),
    onSecondaryContainer: Color(0xFF00262B),
    tertiary: Color(0xFF6E4E00),
    onTertiary: Color(0xFFFFFFFF),
    tertiaryContainer: Color(0xFFF5EACB),
    onTertiaryContainer: Color(0xFF6E4E00),
    error: Color(0xFFA8201A),
    onError: Color(0xFFFFFFFF),
    errorContainer: Color(0xFFF8E4E1),
    onErrorContainer: Color(0xFF00262B),
    surface: Color(0xFFF1F3F2),
    onSurface: Color(0xFF00262B),
    surfaceDim: Color(0xFFE6EBEB),
    surfaceBright: Color(0xFFFFFFFF),
    surfaceContainerLowest: Color(0xFFFFFFFF),
    surfaceContainerLow: Color(0xFFFFFFFF),
    surfaceContainer: Color(0xFFE6EBEB),
    surfaceContainerHigh: Color(0xFFE6EBEB),
    surfaceContainerHighest: Color(0xFFCDE3E6),
    onSurfaceVariant: Color(0xFF4A5F62),
    outline: Color(0xFF6B7F82),
    outlineVariant: Color(0xFFD2DADB),
    inverseSurface: Color(0xFF00262B),
    onInverseSurface: Color(0xFFFFFFFF),
    inversePrimary: Color(0xFFABFFAE),
    shadow: Color(0xFF000000),
    scrim: Color(0xFF00262B),
    surfaceTint: Colors.transparent,
  );

  static const ColorScheme dark = ColorScheme(
    brightness: Brightness.dark,
    primary: Color(0xFFE6F0F1),
    onPrimary: Color(0xFF00262B),
    primaryContainer: Color(0xFFABFFAE),
    onPrimaryContainer: Color(0xFF00262B),
    secondary: Color(0xFFA3B8BB),
    onSecondary: Color(0xFF001A1E),
    secondaryContainer: Color(0xFF1C454B),
    onSecondaryContainer: Color(0xFFE6F0F1),
    tertiary: Color(0xFFF2CC6B),
    onTertiary: Color(0xFF001A1E),
    tertiaryContainer: Color(0xFF3A2E0C),
    onTertiaryContainer: Color(0xFFF2CC6B),
    error: Color(0xFFFFB4AB),
    onError: Color(0xFF001A1E),
    errorContainer: Color(0xFF4A1512),
    onErrorContainer: Color(0xFFE6F0F1),
    surface: Color(0xFF001A1E),
    onSurface: Color(0xFFE6F0F1),
    surfaceDim: Color(0xFF001A1E),
    surfaceBright: Color(0xFF0B353B),
    surfaceContainerLowest: Color(0xFF04292E),
    surfaceContainerLow: Color(0xFF04292E),
    surfaceContainer: Color(0xFF0B353B),
    surfaceContainerHigh: Color(0xFF0B353B),
    surfaceContainerHighest: Color(0xFF1C454B),
    onSurfaceVariant: Color(0xFFA3B8BB),
    outline: Color(0xFF7E9599),
    outlineVariant: Color(0xFF1E4A50),
    inverseSurface: Color(0xFF0F3E45),
    onInverseSurface: Color(0xFFFFFFFF),
    inversePrimary: Color(0xFFABFFAE),
    shadow: Color(0xFF000000),
    scrim: Color(0xFF000000),
    surfaceTint: Colors.transparent,
  );
}

/// ColorScheme-де жоқ v2 рөлдері. Атаулары Figma айнымалыларына сәйкес:
/// `bg/nav` → [nav], `score/low` → [scoreLow] т.с.с.
@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.canvas,
    required this.surface,
    required this.muted,
    required this.tonal,
    required this.accent,
    required this.onAccent,
    required this.panel,
    required this.onPanel,
    required this.onPanelMuted,
    required this.onPanelAccent,
    required this.nav,
    required this.onNav,
    required this.onNavActive,
    required this.warningContainer,
    required this.onWarningContainer,
    required this.success,
    required this.lineStrong,
    required this.lineSubtle,
    required this.ink,
    required this.scoreLow,
    required this.scoreMid,
    required this.scoreHigh,
    required this.onScore,
    required this.disabledContainer,
    required this.onDisabled,
    required this.scrim,
  });

  /// bg/canvas — экран фоны.
  final Color canvas;

  /// bg/surface — карточка, өріс, тізім тобы.
  final Color surface;

  /// bg/muted — бейтарап тег, бос ұяшық.
  final Color muted;

  /// bg/tonal — таңдалған жол, ақпараттық баннер.
  final Color tonal;

  /// bg/accent — жасыл акцент: негізгі CTA, навигация индикаторы.
  final Color accent;
  final Color onAccent;

  /// bg/panel — қараңғы панель (нәтиже, snackbar, диалог фоны).
  final Color panel;
  final Color onPanel;
  final Color onPanelMuted;
  final Color onPanelAccent;

  /// bg/nav — төменгі навигация.
  final Color nav;
  final Color onNav;
  final Color onNavActive;

  /// bg/warning, text/warning.
  final Color warningContainer;
  final Color onWarningContainer;

  /// text/success.
  final Color success;

  /// line/strong, line/subtle, line/ink.
  final Color lineStrong;
  final Color lineSubtle;
  final Color ink;

  /// Рубрика жолақтары: 0–2 / 3 / 4–5. «Ревью белгісі» де [scoreLow].
  final Color scoreLow;
  final Color scoreMid;
  final Color scoreHigh;
  final Color onScore;

  final Color disabledContainer;
  final Color onDisabled;
  final Color scrim;

  /// Ескі атау: навигация фоны.
  Color get navigationBar => nav;

  /// Диаграмманың бұлыңғыр бағандары.
  Color get chartMuted => lineStrong;

  static const light = AppPalette(
    canvas: Color(0xFFF1F3F2),
    surface: Color(0xFFFFFFFF),
    muted: Color(0xFFE6EBEB),
    tonal: Color(0xFFCDE3E6),
    accent: Color(0xFFABFFAE),
    onAccent: Color(0xFF00262B),
    panel: Color(0xFF00262B),
    onPanel: Color(0xFFFFFFFF),
    onPanelMuted: Color(0xFF9DB3B6),
    onPanelAccent: Color(0xFFABFFAE),
    nav: Color(0xFF00262B),
    onNav: Color(0xFF9DB3B6),
    onNavActive: Color(0xFFABFFAE),
    warningContainer: Color(0xFFF5EACB),
    onWarningContainer: Color(0xFF6E4E00),
    success: Color(0xFF17663A),
    lineStrong: Color(0xFF6B7F82),
    lineSubtle: Color(0xFFD2DADB),
    ink: Color(0xFF00262B),
    scoreLow: Color(0xFFF6D77A),
    scoreMid: Color(0xFFCDE3E6),
    scoreHigh: Color(0xFFD6F2D2),
    onScore: Color(0xFF00262B),
    disabledContainer: Color(0xFFE6EBEB),
    onDisabled: Color(0xFF8A9A9C),
    scrim: Color(0x9900262B),
  );

  static const dark = AppPalette(
    canvas: Color(0xFF001A1E),
    surface: Color(0xFF04292E),
    muted: Color(0xFF0B353B),
    tonal: Color(0xFF1C454B),
    accent: Color(0xFFABFFAE),
    onAccent: Color(0xFF00262B),
    panel: Color(0xFF0F3E45),
    onPanel: Color(0xFFFFFFFF),
    onPanelMuted: Color(0xFFA3B8BB),
    onPanelAccent: Color(0xFFABFFAE),
    nav: Color(0xFF00262B),
    onNav: Color(0xFF9DB3B6),
    onNavActive: Color(0xFFABFFAE),
    warningContainer: Color(0xFF3A2E0C),
    onWarningContainer: Color(0xFFF2CC6B),
    success: Color(0xFF8BE39A),
    lineStrong: Color(0xFF7E9599),
    lineSubtle: Color(0xFF1E4A50),
    ink: Color(0xFFE6F0F1),
    scoreLow: Color(0xFF7A5F12),
    scoreMid: Color(0xFF2E5A61),
    scoreHigh: Color(0xFF2F5E3A),
    onScore: Color(0xFFE6F0F1),
    disabledContainer: Color(0xFF0B353B),
    onDisabled: Color(0xFF5F777B),
    scrim: Color(0x99000000),
  );

  /// Material You: беттер мен навигация жүйелік түстерден, рубрика
  /// жолақтары мен ескерту — intRvue мағыналық түстері болып қалады.
  AppPalette fromScheme(ColorScheme s) {
    final dark = s.brightness == Brightness.dark;
    return copyWith(
      canvas: s.surface,
      surface: s.surfaceContainerLowest,
      muted: s.surfaceContainerHigh,
      tonal: s.secondaryContainer,
      accent: s.primaryContainer,
      onAccent: s.onPrimaryContainer,
      panel: dark ? s.surfaceContainerHighest : s.inverseSurface,
      onPanel: dark ? s.onSurface : s.onInverseSurface,
      onPanelMuted: dark ? s.onSurfaceVariant : s.outlineVariant,
      onPanelAccent: dark ? s.primary : s.inversePrimary,
      nav: s.surfaceContainer,
      onNav: s.onSurfaceVariant,
      onNavActive: s.onSurface,
      lineStrong: s.outline,
      lineSubtle: s.outlineVariant,
      ink: s.onSurface,
      disabledContainer: s.surfaceContainerHigh,
    );
  }

  @override
  AppPalette copyWith({
    Color? canvas,
    Color? surface,
    Color? muted,
    Color? tonal,
    Color? accent,
    Color? onAccent,
    Color? panel,
    Color? onPanel,
    Color? onPanelMuted,
    Color? onPanelAccent,
    Color? nav,
    Color? onNav,
    Color? onNavActive,
    Color? warningContainer,
    Color? onWarningContainer,
    Color? success,
    Color? lineStrong,
    Color? lineSubtle,
    Color? ink,
    Color? scoreLow,
    Color? scoreMid,
    Color? scoreHigh,
    Color? onScore,
    Color? disabledContainer,
    Color? onDisabled,
    Color? scrim,
  }) {
    return AppPalette(
      canvas: canvas ?? this.canvas,
      surface: surface ?? this.surface,
      muted: muted ?? this.muted,
      tonal: tonal ?? this.tonal,
      accent: accent ?? this.accent,
      onAccent: onAccent ?? this.onAccent,
      panel: panel ?? this.panel,
      onPanel: onPanel ?? this.onPanel,
      onPanelMuted: onPanelMuted ?? this.onPanelMuted,
      onPanelAccent: onPanelAccent ?? this.onPanelAccent,
      nav: nav ?? this.nav,
      onNav: onNav ?? this.onNav,
      onNavActive: onNavActive ?? this.onNavActive,
      warningContainer: warningContainer ?? this.warningContainer,
      onWarningContainer: onWarningContainer ?? this.onWarningContainer,
      success: success ?? this.success,
      lineStrong: lineStrong ?? this.lineStrong,
      lineSubtle: lineSubtle ?? this.lineSubtle,
      ink: ink ?? this.ink,
      scoreLow: scoreLow ?? this.scoreLow,
      scoreMid: scoreMid ?? this.scoreMid,
      scoreHigh: scoreHigh ?? this.scoreHigh,
      onScore: onScore ?? this.onScore,
      disabledContainer: disabledContainer ?? this.disabledContainer,
      onDisabled: onDisabled ?? this.onDisabled,
      scrim: scrim ?? this.scrim,
    );
  }

  @override
  AppPalette lerp(AppPalette? other, double t) {
    if (other == null) return this;
    Color l(Color a, Color b) => Color.lerp(a, b, t)!;
    return AppPalette(
      canvas: l(canvas, other.canvas),
      surface: l(surface, other.surface),
      muted: l(muted, other.muted),
      tonal: l(tonal, other.tonal),
      accent: l(accent, other.accent),
      onAccent: l(onAccent, other.onAccent),
      panel: l(panel, other.panel),
      onPanel: l(onPanel, other.onPanel),
      onPanelMuted: l(onPanelMuted, other.onPanelMuted),
      onPanelAccent: l(onPanelAccent, other.onPanelAccent),
      nav: l(nav, other.nav),
      onNav: l(onNav, other.onNav),
      onNavActive: l(onNavActive, other.onNavActive),
      warningContainer: l(warningContainer, other.warningContainer),
      onWarningContainer: l(onWarningContainer, other.onWarningContainer),
      success: l(success, other.success),
      lineStrong: l(lineStrong, other.lineStrong),
      lineSubtle: l(lineSubtle, other.lineSubtle),
      ink: l(ink, other.ink),
      scoreLow: l(scoreLow, other.scoreLow),
      scoreMid: l(scoreMid, other.scoreMid),
      scoreHigh: l(scoreHigh, other.scoreHigh),
      onScore: l(onScore, other.onScore),
      disabledContainer: l(disabledContainer, other.disabledContainer),
      onDisabled: l(onDisabled, other.onDisabled),
      scrim: l(scrim, other.scrim),
    );
  }
}

extension AppThemeX on BuildContext {
  ColorScheme get colors => Theme.of(this).colorScheme;
  TextTheme get text => Theme.of(this).textTheme;
  AppPalette get palette => Theme.of(this).extension<AppPalette>()!;
}
