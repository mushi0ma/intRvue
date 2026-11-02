import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// «Ревью на полях» (Figma `K.mark`): кодқа ревьюдағыдай пікір белгісі.
/// Түсі — рубриканың төменгі жолағы (score/low), қызыл емес.
class ReviewMark extends StatelessWidget {
  const ReviewMark({super.key, this.symbol = '!', this.size = 16});

  final String symbol;
  final double size;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return ExcludeSemantics(
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: p.scoreLow,
          borderRadius: BorderRadius.circular(AppRadius.mark),
        ),
        child: Text(
          symbol,
          textScaler: TextScaler.noScaling,
          style: context.text.bodySmall!.copyWith(
            color: p.onScore,
            fontWeight: FontWeight.w600,
            height: 1,
            fontSize: size * 0.75,
          ),
        ),
      ),
    );
  }
}

/// Белгі + сия мәтін (Figma `K.note`). Өріс астындағы қате, ескерту.
class ReviewNote extends StatelessWidget {
  const ReviewNote(this.message, {super.key, this.symbol = '!'});

  final String message;
  final String symbol;

  @override
  Widget build(BuildContext context) {
    final style = context.text.bodySmall!.copyWith(
      color: context.colors.onSurface,
    );
    final lineHeight = (style.fontSize ?? 12) * (style.height ?? 1.33);
    final scaled = MediaQuery.textScalerOf(context).scale(lineHeight);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(top: ((scaled - 16) / 2).clamp(0, 12)),
          child: ReviewMark(symbol: symbol),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(child: Text(message, style: style)),
      ],
    );
  }
}

/// Блоктың сол жақ шетіндегі 4 dp жолақ — git-gutter сияқты (Figma
/// `K.gutter`). Блокты жылжытпайды: жолақ шеткі 16 dp ішіне салынады.
class ReviewGutter extends StatelessWidget {
  const ReviewGutter({
    super.key,
    required this.flagged,
    required this.child,
    this.offset = 12,
  });

  final bool flagged;
  final Widget child;

  /// Блоктың сол жиегінен жолаққа дейінгі қашықтық.
  final double offset;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        if (flagged)
          PositionedDirectional(
            start: -offset,
            top: 0,
            bottom: 0,
            width: 4,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: context.palette.scoreLow,
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
            ),
          ),
      ],
    );
  }
}
