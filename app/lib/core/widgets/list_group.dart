import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_icons.dart';
import '../theme/app_spacing.dart';

/// Топ тақырыбы: белгіше + атау (+ оң жақта мета). Figma `GroupHeader`.
class GroupHeader extends StatelessWidget {
  const GroupHeader({super.key, required this.title, this.icon, this.meta});

  final String title;
  final IconData? icon;
  final String? meta;

  @override
  Widget build(BuildContext context) {
    final secondary = context.colors.onSurfaceVariant;
    return Semantics(
      header: true,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(4, 20, 4, 8),
        child: Row(
          children: [
            if (icon != null) ...[
              Icon(icon, size: 18, color: context.colors.onSurface),
              const SizedBox(width: AppSpacing.sm),
            ],
            Expanded(child: Text(title, style: context.text.labelLarge)),
            if (meta != null)
              Text(
                meta!,
                style: context.text.bodySmall!.copyWith(color: secondary),
              ),
          ],
        ),
      ),
    );
  }
}

/// Жолдар тобы — дөңгелектелген карточка, жолдар арасы жіңішке сызық
/// (Figma `K.groupLists`).
class ListGroup extends StatelessWidget {
  const ListGroup({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: p.lineSubtle),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.card - 1),
        child: Material(
          type: MaterialType.transparency,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < children.length; i++) ...[
                if (i > 0) const Divider(),
                children[i],
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Топ ішіндегі жол: атау, түсініктеме, оң жақта мән және белгіше.
class GroupRow extends StatelessWidget {
  const GroupRow({
    super.key,
    required this.title,
    this.subtitle,
    this.value,
    this.valueLeading,
    this.leading,
    this.trailing = AppIcons.chevronRight,
    this.onTap,
  });

  final String title;
  final String? subtitle;
  final String? value;

  /// Мәннің алдындағы шағын белгі (мысалы, «Live» нүктесі).
  final Widget? valueLeading;
  final Widget? leading;

  /// null — белгішесіз.
  final IconData? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final secondary = context.colors.onSurfaceVariant;
    return InkWell(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 52),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              if (leading != null) ...[
                leading!,
                const SizedBox(width: AppSpacing.smd),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  spacing: 2,
                  children: [
                    Text(title, style: context.text.bodyLarge),
                    if (subtitle != null)
                      Text(
                        subtitle!,
                        style: context.text.bodySmall!.copyWith(
                          color: secondary,
                        ),
                      ),
                  ],
                ),
              ),
              if (value != null) ...[
                const SizedBox(width: AppSpacing.smd),
                if (valueLeading != null) ...[
                  valueLeading!,
                  const SizedBox(width: 6),
                ],
                // Мән жолдың жартысынан аспайды — атау бір жолда қалады.
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.sizeOf(context).width * 0.4,
                  ),
                  child: Text(
                    value!,
                    textAlign: TextAlign.end,
                    style: context.text.bodyMedium!.copyWith(color: secondary),
                  ),
                ),
              ],
              if (trailing != null) ...[
                const SizedBox(width: AppSpacing.sm),
                Icon(trailing, size: 20, color: secondary),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Монограмма: шаршы, сия жиек (Figma `K.monogram`).
class Monogram extends StatelessWidget {
  const Monogram({super.key, required this.initial, this.size = 56});

  final String initial;
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
          color: p.surface,
          borderRadius: BorderRadius.circular(AppRadius.control),
          border: Border.all(color: p.ink),
        ),
        child: Text(
          initial,
          textScaler: TextScaler.noScaling,
          style: context.text.titleLarge!.copyWith(fontSize: size * 0.4),
        ),
      ),
    );
  }
}

/// Карточкалы тізім жолы (Figma C1/C4/E1): надзаголовок, атау, мета,
/// оң жақта әрекет (бетбелгі, ⋮). [ListGroup] ішінде қолданылады.
class ItemRow extends StatelessWidget {
  const ItemRow({
    super.key,
    required this.title,
    this.overline,
    this.meta,
    this.metaTrailing,
    this.trailing,
    this.onTap,
  });

  final String title;
  final String? overline;
  final String? meta;

  /// Метаның жанындағы шағын белгі (мысалы, «Толық емес» тегі).
  final Widget? metaTrailing;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final small = context.text.bodySmall!.copyWith(
      color: context.colors.onSurfaceVariant,
    );
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, 12, trailing == null ? 16 : 4, 12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 2,
                children: [
                  if (overline != null) Text(overline!, style: small),
                  Text(title, style: context.text.titleSmall),
                  if (meta != null || metaTrailing != null)
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        if (meta != null) Text(meta!, style: small),
                        ?metaTrailing,
                      ],
                    ),
                ],
              ),
            ),
            ?trailing,
          ],
        ),
      ),
    );
  }
}
