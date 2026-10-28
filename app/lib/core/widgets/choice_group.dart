import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// Радио-индикаторы бар таңдау чипі (Figma «Choice chip»): 48 dp, r12.
/// Таңдау тек түспен емес, ішкі нүктемен де көрсетіледі.
class ChoiceTile extends StatelessWidget {
  const ChoiceTile({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final border = BorderRadius.circular(AppRadius.choice);
    return Semantics(
      selected: selected,
      inMutuallyExclusiveGroup: true,
      button: true,
      child: Material(
        color: selected ? colors.secondaryContainer : colors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: border,
          side: BorderSide(color: selected ? colors.primary : colors.outline),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minHeight: AppSpacing.touchTarget,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Row(
                children: [
                  _RadioDot(selected: selected),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      label,
                      style: context.text.labelMedium!.copyWith(
                        color: selected
                            ? colors.onSecondaryContainer
                            : colors.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RadioDot extends StatelessWidget {
  const _RadioDot({required this.selected});
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: colors.surface,
        border: Border.all(
          color: selected ? colors.primary : colors.outline,
          width: selected ? 2 : 1,
        ),
      ),
      alignment: Alignment.center,
      child: selected
          ? Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colors.primary,
              ),
            )
          : null,
    );
  }
}

/// Бір мәнді таңдау тобы. Мәтін үлкейгенде баған саны азаяды.
class ChoiceGroup<T> extends StatelessWidget {
  const ChoiceGroup({
    super.key,
    required this.values,
    required this.selected,
    required this.labelOf,
    required this.onChanged,
    this.columns = 2,
    this.label,
  });

  final List<T> values;
  final T selected;
  final String Function(T) labelOf;
  final ValueChanged<T> onChanged;
  final int columns;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final gap = columns == 2 ? 12.0 : 8.0;
    final textScale = MediaQuery.textScalerOf(context).scale(1);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (label != null) ...[
          Text(
            label!,
            style: context.text.labelMedium!.copyWith(
              color: context.colors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
        ],
        LayoutBuilder(
          builder: (context, constraints) {
            var cols = columns;
            while (cols > 1 &&
                (constraints.maxWidth - gap * (cols - 1)) / cols <
                    100 * textScale) {
              cols--;
            }
            final width = (constraints.maxWidth - gap * (cols - 1)) / cols;
            return Wrap(
              spacing: gap,
              runSpacing: 8,
              children: [
                for (final v in values)
                  SizedBox(
                    width: width,
                    child: ChoiceTile(
                      label: labelOf(v),
                      selected: v == selected,
                      onTap: () => onChanged(v),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}
