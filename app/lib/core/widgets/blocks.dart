import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import 'app_page.dart';

/// Экран еніндегі жасыл жаттығу блогы (primaryContainer).
/// Басты беттегі «Жаттығуды жалғастырайық» пен ұсынымдарда.
class TrainingBlock extends StatelessWidget implements FullWidth {
  const TrainingBlock({
    super.key,
    required this.children,
    this.padding = const EdgeInsets.fromLTRB(24, 24, 24, 24),
  });

  final List<Widget> children;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return ColoredBox(
      color: colors.primaryContainer,
      child: Padding(
        padding: padding,
        child: DefaultTextStyle.merge(
          style: TextStyle(color: colors.onPrimaryContainer),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: children,
          ),
        ),
      ),
    );
  }
}

/// Ескерту жолағы (Figma «Banner / Offline»): желі жоқ, шектеулі әрекет.
class InfoBanner extends StatelessWidget implements FullWidth {
  const InfoBanner({super.key, required this.title, this.body});

  final String title;
  final String? body;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Semantics(
      liveRegion: true,
      child: ColoredBox(
        color: palette.warningContainer,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 8,
            children: [
              Text(
                title,
                style: context.text.titleSmall!.copyWith(
                  color: palette.onWarningContainer,
                ),
              ),
              if (body != null)
                Text(
                  body!,
                  style: context.text.bodyMedium!.copyWith(
                    color: palette.onWarningContainer,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Күй белгісі: «✓ Толық», «Бағалау күтілуде».
class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.label, this.complete = true});

  final String label;
  final bool complete;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final palette = context.palette;
    final bg = complete ? colors.secondaryContainer : palette.warningContainer;
    final fg = complete
        ? colors.onSecondaryContainer
        : palette.onWarningContainer;
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(minHeight: 32),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(AppRadius.chip),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (complete) ...[
              Icon(Icons.check, size: 16, color: colors.primary),
              const SizedBox(width: 6),
            ],
            Text(label, style: context.text.labelMedium!.copyWith(color: fg)),
          ],
        ),
      ),
    );
  }
}

/// Онбординг беттерінің индикаторы: белсенді нүкте 24 dp.
class PageIndicator extends StatelessWidget {
  const PageIndicator({super.key, required this.count, required this.index});

  final int count;
  final int index;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Semantics(
      label: '${index + 1} / $count',
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        spacing: 8,
        children: [
          for (var i = 0; i < count; i++)
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: i == index ? 24 : 8,
              height: 8,
              decoration: BoxDecoration(
                color: i == index ? colors.primary : colors.outlineVariant,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
        ],
      ),
    );
  }
}

/// Сессия ішіндегі сұрақтар прогресі: 5 сегмент.
class QuestionProgress extends StatelessWidget {
  const QuestionProgress({super.key, required this.total, required this.done});

  final int total;

  /// Белсенді сұрақты қоса есептегенде.
  final int done;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Row(
      spacing: 6,
      children: [
        for (var i = 0; i < total; i++)
          Expanded(
            child: Container(
              height: 5,
              decoration: BoxDecoration(
                color: i < done ? colors.primary : colors.secondaryContainer,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
      ],
    );
  }
}

class AppAvatar extends StatelessWidget {
  const AppAvatar({super.key, required this.initial, this.size = 40});

  final String initial;
  final double size;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: colors.primaryContainer,
        shape: BoxShape.circle,
      ),
      child: Text(
        initial,
        style: context.text.titleSmall!.copyWith(
          color: colors.onPrimaryContainer,
          fontSize: size * 0.4,
        ),
      ),
    );
  }
}

/// Тізім жолы: тақырып 18/600, сипаттама 14, астында бөлгіш.
class ListRow extends StatelessWidget {
  const ListRow({
    super.key,
    required this.title,
    this.subtitle,
    this.meta,
    this.trailing,
    this.onTap,
    this.subtitleColor,
    this.divider = true,
    this.titleStyle,
  });

  final String title;
  final String? subtitle;

  /// Тақырыптың үстіндегі шағын жол: «19 қазан · 18:42».
  final String? meta;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Color? subtitleColor;
  final bool divider;
  final TextStyle? titleStyle;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final muted = context.text.bodyMedium!.copyWith(
      color: colors.onSurfaceVariant,
    );
    final content = Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (meta != null) ...[
                  Text(meta!, style: muted),
                  const SizedBox(height: 6),
                ],
                Text(title, style: titleStyle ?? context.text.titleMedium),
                if (subtitle != null) ...[
                  const SizedBox(height: 8),
                  Text(subtitle!, style: muted.copyWith(color: subtitleColor)),
                ],
              ],
            ),
          ),
          if (trailing != null) ...[const SizedBox(width: 12), trailing!],
        ],
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (onTap == null)
          content
        else
          InkWell(
            onTap: onTap,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 72),
              child: content,
            ),
          ),
        if (divider) const Divider(),
      ],
    );
  }
}

/// Тақырып + түсіндірме мәтін (құпиялылық, келісім, бос күйлер).
class InfoSection extends StatelessWidget {
  const InfoSection({
    super.key,
    required this.title,
    required this.body,
    this.titleStyle,
    this.bodyColor,
  });

  final String title;
  final String body;
  final TextStyle? titleStyle;
  final Color? bodyColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(title, style: titleStyle ?? context.text.titleLarge),
        const SizedBox(height: 12),
        Text(
          body,
          style: context.text.bodyLarge!.copyWith(
            color: bodyColor ?? context.colors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

/// Бөлім бөлгіші, жоғары-төмен шегінісімен.
class SectionDivider extends StatelessWidget {
  const SectionDivider({super.key, this.vertical = 28});
  final double vertical;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.symmetric(vertical: vertical),
    child: const Divider(),
  );
}

/// Баптаулар жолы: атауы 16/500 және мәні 14.
class SettingsRow extends StatelessWidget {
  const SettingsRow({
    super.key,
    required this.title,
    required this.value,
    required this.onTap,
  });

  final String title;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 64),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      spacing: 6,
                      children: [
                        Text(
                          title,
                          style: context.text.bodyLarge!.copyWith(
                            fontWeight: FontWeight.w500,
                            height: 1.2,
                          ),
                        ),
                        Text(
                          value,
                          style: context.text.bodyMedium!.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right, color: colors.onSurfaceVariant),
                ],
              ),
            ),
          ),
        ),
        const Divider(),
      ],
    );
  }
}

/// Тақырып таңдау жолы: шаршы белгі, атауы, сипаттамасы.
class CheckRow extends StatelessWidget {
  const CheckRow({
    super.key,
    required this.title,
    required this.subtitle,
    required this.checked,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final bool checked;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          checked: checked,
          label: title,
          excludeSemantics: true,
          onTap: () => onChanged(!checked),
          child: InkWell(
            onTap: () => onChanged(!checked),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 72),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 40,
                      height: 24,
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Checkbox(
                          value: checked,
                          onChanged: (v) => onChanged(v ?? false),
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        spacing: 8,
                        children: [
                          Text(title, style: context.text.titleMedium),
                          Text(
                            subtitle,
                            style: context.text.bodyMedium!.copyWith(
                              color: colors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const Divider(),
      ],
    );
  }
}

/// Бос күй: тақырып және түсіндірме.
class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xl),
      child: InfoSection(title: title, body: body),
    );
  }
}
