import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Тақырып балы: «Dart негіздері  86,7» және 8 dp жолақ.
class ScoreBar extends StatelessWidget {
  const ScoreBar({
    super.key,
    required this.label,
    required this.score,
    required this.valueText,
  });

  final String label;

  /// 0–100
  final double score;
  final String valueText;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Semantics(
      label: '$label: $valueText / 100',
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: Text(label, style: context.text.bodyLarge)),
              Text(
                valueText,
                style: context.text.labelLarge!.copyWith(color: colors.primary),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _Bar(
            fraction: score / 100,
            height: 8,
            track: colors.secondaryContainer,
            fill: colors.primary,
          ),
        ],
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({
    required this.fraction,
    required this.height,
    required this.track,
    required this.fill,
  });

  final double fraction;
  final double height;
  final Color track;
  final Color fill;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(height / 2);
    return Container(
      height: height,
      decoration: BoxDecoration(color: track, borderRadius: radius),
      alignment: Alignment.centerLeft,
      child: FractionallySizedBox(
        widthFactor: fraction.clamp(0, 1),
        child: Container(
          decoration: BoxDecoration(color: fill, borderRadius: radius),
        ),
      ),
    );
  }
}
