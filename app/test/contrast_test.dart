// WCAG 2.2 контрасты: барлық «мәтін / фон» рөл жұптары ≥ 4.5:1,
// жарық және қараңғы тақырыпта.
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intrvue/core/theme/app_colors.dart';

double _luminance(Color c) {
  double ch(double v) =>
      v <= 0.03928 ? v / 12.92 : pow((v + 0.055) / 1.055, 2.4).toDouble();
  return 0.2126 * ch(c.r) + 0.7152 * ch(c.g) + 0.0722 * ch(c.b);
}

double contrast(Color a, Color b) {
  final x = _luminance(a), y = _luminance(b);
  return (max(x, y) + 0.05) / (min(x, y) + 0.05);
}

void main() {
  for (final (name, s, p) in [
    ('light', AppColors.light, AppPalette.light),
    ('dark', AppColors.dark, AppPalette.dark),
  ]) {
    test('$name: text/background pairs ≥ 4.5:1', () {
      final pairs = <String, (Color, Color)>{
        'onSurface/surface': (s.onSurface, s.surface),
        'onSurfaceVariant/surface': (s.onSurfaceVariant, s.surface),
        'primary/surface (links)': (s.primary, s.surface),
        'error/surface': (s.error, s.surface),
        'onPrimary/primary (filled button)': (s.onPrimary, s.primary),
        'onError/error (danger button)': (s.onError, s.error),
        'primary/secondaryContainer (tonal button)': (
          s.primary,
          s.secondaryContainer,
        ),
        'onSecondaryContainer/secondaryContainer': (
          s.onSecondaryContainer,
          s.secondaryContainer,
        ),
        'onPrimaryContainer/primaryContainer (training block)': (
          s.onPrimaryContainer,
          s.primaryContainer,
        ),
        'onWarningContainer/warningContainer': (
          p.onWarningContainer,
          p.warningContainer,
        ),
        'onWarningContainer/surface (incomplete label)': (
          p.onWarningContainer,
          s.surface,
        ),
        'onSurface/navigationBar': (s.onSurface, p.navigationBar),
        'onSurfaceVariant/navigationBar': (s.onSurfaceVariant, p.navigationBar),
        'onInverseSurface/inverseSurface (snackbar)': (
          s.onInverseSurface,
          s.inverseSurface,
        ),
        'inversePrimary/inverseSurface (snackbar action)': (
          s.inversePrimary,
          s.inverseSurface,
        ),
        'onSurfaceVariant/surfaceContainerHigh (dialog)': (
          s.onSurfaceVariant,
          s.surfaceContainerHigh,
        ),
      };
      final failures = [
        for (final e in pairs.entries)
          if (contrast(e.value.$1, e.value.$2) < 4.5)
            '${e.key}: ${contrast(e.value.$1, e.value.$2).toStringAsFixed(2)}',
      ];
      expect(failures, isEmpty);
    });
  }
}
