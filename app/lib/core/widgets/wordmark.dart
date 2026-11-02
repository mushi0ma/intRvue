import 'package:flutter/material.dart';

import '../constants/app_strings.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// «intRvue» белгісі (Figma v2): «i» шаршысы + сөз. Логотип ешқашан
/// тасымалданбайды: үлкен мәтін өлшемінде (200%) сыймаса, кішірейеді.
class Wordmark extends StatelessWidget {
  const Wordmark({super.key, this.large = false, this.onPanel = false});

  /// true — splash экранындағы үлкен белгі.
  final bool large;

  /// Қараңғы панельде: шаршы жасыл, сөз ақ.
  final bool onPanel;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final size = large ? 44.0 : 24.0;
    final markColor = onPanel ? p.accent : p.ink;
    final letterColor = onPanel ? p.onAccent : context.colors.surface;
    final textColor = onPanel ? p.onPanel : context.colors.onSurface;
    final word = large
        ? context.text.displayMedium!.copyWith(color: textColor)
        : context.text.titleMedium!.copyWith(color: textColor);
    return Semantics(
      label: S.appName,
      excludeSemantics: true,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: AlignmentDirectional.centerStart,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          spacing: large ? AppSpacing.smd : AppSpacing.sm,
          children: [
            Container(
              width: size,
              height: size,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: markColor,
                borderRadius: BorderRadius.circular(
                  large ? AppRadius.cell : AppRadius.tag,
                ),
              ),
              child: Text(
                'i',
                textScaler: TextScaler.noScaling,
                style: word.copyWith(
                  color: letterColor,
                  fontSize: size * 0.62,
                  height: 1,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Text(
              S.appName,
              maxLines: 1,
              softWrap: false,
              textScaler: TextScaler.noScaling,
              style: word,
            ),
          ],
        ),
      ),
    );
  }
}
