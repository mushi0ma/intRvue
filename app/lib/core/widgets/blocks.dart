import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_icons.dart';
import '../theme/app_spacing.dart';
import 'app_button.dart';
import 'app_page.dart';
import 'review_mark.dart';

enum BannerKind {
  /// Ақпарат: bg/tonal, info белгішесі.
  info,

  /// Ескерту / қате: ревью белгісі мен жиек жолағы, қызыл емес.
  warning,
}

/// Экран еніндегі баннер (Figma `K.banner`): желі жоқ, демо режимі т.б.
class InfoBanner extends StatelessWidget implements FullWidth {
  const InfoBanner({
    super.key,
    required this.title,
    this.body,
    this.kind = BannerKind.warning,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String? body;
  final BannerKind kind;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final ink = context.colors.onSurface;
    final flagged = kind == BannerKind.warning;
    final content = Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.inset,
        vertical: 12,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 12,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: flagged
                ? const ReviewMark(size: 20)
                : Icon(AppIcons.info, size: 20, color: ink),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 4,
              children: [
                Text(title, style: context.text.labelLarge),
                if (body != null) Text(body!, style: context.text.bodyMedium),
                if (actionLabel != null)
                  AppLink(label: actionLabel!, onPressed: onAction),
              ],
            ),
          ),
        ],
      ),
    );
    return Semantics(
      liveRegion: true,
      container: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: flagged ? p.surface : p.tonal,
          border: flagged
              ? Border(bottom: BorderSide(color: p.lineSubtle))
              : null,
        ),
        child: ReviewGutter(flagged: flagged, offset: 0, child: content),
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
    final p = context.palette;
    return Semantics(
      label: '${index + 1} / $count',
      child: Row(
        spacing: 4,
        children: [
          for (var i = 0; i < count; i++)
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: i == index ? 20 : 8,
              height: 3,
              decoration: BoxDecoration(
                color: i == index ? p.ink : p.lineStrong.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(AppRadius.pill),
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

  /// Figma D5: өткендері — сия, ағымдағысы — жасыл (сия жиекпен),
  /// алдағылары — жіңішке сұр.
  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return ExcludeSemantics(
      child: Row(
        spacing: 4,
        children: [
          for (var i = 0; i < total; i++)
            Expanded(
              child: Container(
                height: 4,
                decoration: BoxDecoration(
                  color: i < done - 1
                      ? p.ink
                      : i == done - 1
                      ? p.accent
                      : p.lineStrong.withValues(alpha: 0.45),
                  border: i == done - 1
                      ? Border.all(color: p.ink, width: 0.5)
                      : null,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
              ),
            ),
        ],
      ),
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
