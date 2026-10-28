import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Бір бағалау өлшемі: атауы, «4 / 5» мәні және 7 dp жолақ.
/// Мән саны мен мәтін бірге көрсетіледі — мағына тек түске сүйенбейді.
class AssessmentBar extends StatelessWidget {
  const AssessmentBar({
    super.key,
    required this.label,
    required this.value,
    this.max = 5,
    this.onBlock = false,
  });

  final String label;
  final int value;
  final int max;

  /// Жасыл жаттығу блогының ішінде тұр.
  final bool onBlock;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textColor = onBlock ? colors.onPrimaryContainer : colors.onSurface;
    final valueColor = onBlock ? colors.onPrimaryContainer : colors.primary;
    return Semantics(
      label: '$label: $value / $max',
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: context.text.bodyMedium!.copyWith(color: textColor),
                ),
              ),
              Text(
                '$value / $max',
                style: context.text.labelLarge!.copyWith(color: valueColor),
              ),
            ],
          ),
          const SizedBox(height: 9),
          _Bar(
            fraction: value / max,
            height: 7,
            track: colors.secondaryContainer,
            fill: colors.primary,
          ),
        ],
      ),
    );
  }
}

/// Үш өлшем бірге (Дұрыстық, Толықтық, Анықтық).
class AssessmentScales extends StatelessWidget {
  const AssessmentScales({
    super.key,
    required this.correctness,
    required this.completeness,
    required this.clarity,
    required this.labels,
    this.onBlock = false,
    this.spacing = 23,
  });

  final int correctness;
  final int completeness;
  final int clarity;
  final (String, String, String) labels;
  final bool onBlock;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: spacing,
      children: [
        AssessmentBar(label: labels.$1, value: correctness, onBlock: onBlock),
        AssessmentBar(label: labels.$2, value: completeness, onBlock: onBlock),
        AssessmentBar(label: labels.$3, value: clarity, onBlock: onBlock),
      ],
    );
  }
}

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
