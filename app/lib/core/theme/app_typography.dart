import 'package:flutter/material.dart';

/// Figma «v2/*» мәтін стильдері, Medeo (OFL): Sans, Sans Display, Mono.
///
/// | Figma v2      | Flutter                         |
/// |---------------|---------------------------------|
/// | numeral-xl    | displayLarge  · Display Light 64/64 |
/// | numeral-l     | displayMedium · Display Light 40/44 |
/// | numeral-m     | displaySmall  · Display 28/32   |
/// | title-l       | headlineLarge, headlineMedium · Display 30/36 |
/// | title-m       | headlineSmall, titleLarge · Display 22/28 |
/// | title-s       | titleMedium · Sans Medium 17/24 |
/// | —             | titleSmall · Sans Medium 16/24  |
/// | body          | bodyLarge · 16/24               |
/// | body-s        | bodyMedium · 14/20              |
/// | caption       | bodySmall · 12/16               |
/// | label         | labelLarge, labelMedium · Medium 14/20 |
/// | nav           | labelSmall · Medium 12/16       |
/// | code          | [AppTypography.code] · Mono 14/20 |
///
/// Сандар барлық жерде кесте цифрларымен (tnum): ұпайлар бағанда тураланады.
abstract final class AppTypography {
  static const fontFamily = 'Medeo Sans';
  static const displayFamily = 'Medeo Sans Display';
  static const monoFamily = 'Medeo Mono';

  static const _tnum = [FontFeature.tabularFigures()];

  static TextStyle _style(
    String family,
    double size,
    double lineHeight,
    FontWeight weight, {
    double tracking = 0,
    required Color color,
  }) => TextStyle(
    fontFamily: family,
    fontSize: size,
    height: lineHeight / size,
    fontWeight: weight,
    letterSpacing: tracking,
    fontFeatures: _tnum,
    color: color,
  );

  static TextTheme textTheme(ColorScheme colors) {
    final c = colors.onSurface;
    const light = FontWeight.w300;
    const regular = FontWeight.w400;
    const medium = FontWeight.w500;
    final titleL = _style(
      displayFamily,
      30,
      36,
      regular,
      tracking: -0.3,
      color: c,
    );
    final titleM = _style(
      displayFamily,
      22,
      28,
      regular,
      tracking: -0.1,
      color: c,
    );
    final label = _style(fontFamily, 14, 20, medium, color: c);

    return TextTheme(
      displayLarge: _style(
        displayFamily,
        64,
        64,
        light,
        tracking: -1,
        color: c,
      ),
      displayMedium: _style(
        displayFamily,
        40,
        44,
        light,
        tracking: -0.5,
        color: c,
      ),
      displaySmall: _style(displayFamily, 28, 32, regular, color: c),
      headlineLarge: titleL,
      headlineMedium: titleL,
      headlineSmall: titleM,
      titleLarge: titleM,
      titleMedium: _style(fontFamily, 17, 24, medium, color: c),
      titleSmall: _style(fontFamily, 16, 24, medium, color: c),
      bodyLarge: _style(fontFamily, 16, 24, regular, color: c),
      bodyMedium: _style(fontFamily, 14, 20, regular, color: c),
      bodySmall: _style(fontFamily, 12, 16, regular, tracking: 0.1, color: c),
      labelLarge: label,
      labelMedium: label,
      labelSmall: _style(fontFamily, 12, 16, medium, tracking: 0.1, color: c),
    );
  }

  /// v2/code — үлгі жауап, сұраулар ізі, формула.
  static TextStyle code(Color color) =>
      _style(monoFamily, 14, 20, FontWeight.w400, color: color);
}
