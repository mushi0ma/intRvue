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
      // Figma «v2 / Color» мәтін/фон жұптары.
      final pairs = <String, (Color, Color)>{
        'text/primary on canvas': (s.onSurface, p.canvas),
        'text/primary on surface': (s.onSurface, p.surface),
        'text/secondary on canvas': (s.onSurfaceVariant, p.canvas),
        'text/secondary on surface': (s.onSurfaceVariant, p.surface),
        'text/secondary on muted': (s.onSurfaceVariant, p.muted),
        'text/secondary on tonal': (s.onSurfaceVariant, p.tonal),
        'on-primary on primary (button)': (s.onPrimary, s.primary),
        'on-accent on accent (CTA, nav indicator)': (p.onAccent, p.accent),
        'text/primary on tonal': (s.onSecondaryContainer, s.secondaryContainer),
        'text/warning on bg/warning': (
          p.onWarningContainer,
          p.warningContainer,
        ),
        'text/warning on canvas': (p.onWarningContainer, p.canvas),
        'text/success on canvas': (p.success, p.canvas),
        'text/success on score/high': (p.success, p.scoreHigh),
        'on-panel on panel (snackbar)': (p.onPanel, p.panel),
        'on-panel-muted on panel': (p.onPanelMuted, p.panel),
        'on-panel-accent on panel (snackbar action)': (
          p.onPanelAccent,
          p.panel,
        ),
        'on-nav on nav': (p.onNav, p.nav),
        'on-nav-active on nav': (p.onNavActive, p.nav),
        'score/on on score/low (review mark)': (p.onScore, p.scoreLow),
        'score/on on score/mid': (p.onScore, p.scoreMid),
        'score/on on score/high': (p.onScore, p.scoreHigh),
      };
      final failures = [
        for (final e in pairs.entries)
          if (contrast(e.value.$1, e.value.$2) < 4.5)
            '${e.key}: ${contrast(e.value.$1, e.value.$2).toStringAsFixed(2)}',
      ];
      expect(failures, isEmpty);
    });

    // WCAG 1.4.11: өріс жиегі, чекбокс, ауыстырғыш — ≥ 3:1.
    test('$name: control outlines ≥ 3:1', () {
      final pairs = <String, (Color, Color)>{
        'line/strong on surface': (p.lineStrong, p.surface),
        'line/strong on canvas': (p.lineStrong, p.canvas),
        'line/ink on surface (focus, error)': (p.ink, p.surface),
        'accent indicator on nav': (p.accent, p.nav),
      };
      final failures = [
        for (final e in pairs.entries)
          if (contrast(e.value.$1, e.value.$2) < 3)
            '${e.key}: ${contrast(e.value.$1, e.value.$2).toStringAsFixed(2)}',
      ];
      expect(failures, isEmpty);
    });
  }
}
