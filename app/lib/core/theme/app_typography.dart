import 'package:flutter/material.dart';

/// Figma «Типографика · Inter» шкаласы.
///
/// | Figma            | Flutter          |
/// |------------------|------------------|
/// | Display 68/600   | displayLarge     |
/// | Hero 38/600      | displayMedium    |
/// | Headline 30/600  | headlineLarge    |
/// | Card title 28/600| headlineMedium   |
/// | Question 26/600  | headlineSmall    |
/// | Title 22/600     | titleLarge       |
/// | Item 18/600      | titleMedium      |
/// | Body 16/400·24   | bodyLarge        |
/// | Body small 14/400| bodyMedium       |
/// | Caption 12/400   | bodySmall        |
/// | Label 16/600     | labelLarge       |
/// | Label medium 14/500 | labelMedium   |
/// | Navigation 12/500| labelSmall       |
abstract final class AppTypography {
  static const fontFamily = 'Inter';

  static TextTheme textTheme(ColorScheme colors) {
    TextStyle style(double size, FontWeight weight, double height) => TextStyle(
      fontFamily: fontFamily,
      fontSize: size,
      fontWeight: weight,
      height: height,
      letterSpacing: 0,
      color: colors.onSurface,
    );

    return TextTheme(
      displayLarge: style(68, FontWeight.w600, 1.1),
      displayMedium: style(38, FontWeight.w600, 1.2),
      displaySmall: style(34, FontWeight.w600, 1.2),
      headlineLarge: style(30, FontWeight.w600, 1.2),
      headlineMedium: style(28, FontWeight.w600, 1.2),
      headlineSmall: style(26, FontWeight.w600, 1.2),
      titleLarge: style(22, FontWeight.w600, 1.25),
      titleMedium: style(18, FontWeight.w600, 1.25),
      titleSmall: style(16, FontWeight.w600, 1.25),
      bodyLarge: style(16, FontWeight.w400, 1.5),
      bodyMedium: style(14, FontWeight.w400, 1.4),
      bodySmall: style(12, FontWeight.w400, 1.35),
      labelLarge: style(16, FontWeight.w600, 1.2),
      labelMedium: style(14, FontWeight.w500, 1.2),
      labelSmall: style(12, FontWeight.w500, 1.25),
    );
  }
}
