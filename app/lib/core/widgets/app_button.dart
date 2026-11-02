import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_icons.dart';
import '../theme/app_spacing.dart';

enum AppButtonVariant {
  /// Негізгі әрекет — сия фон (Figma kind=primary).
  filled,

  /// Қосымша әрекет — сия жиек (kind=outline).
  tonal,

  /// Мәтіндік батырма (kind=text).
  text,

  /// Қайтарылмайтын әрекет. Қызыл емес: сия фон + белгіше, қауіпті
  /// мазмұн (diff, мерзім) көрсетеді.
  danger,

  /// Экрандағы басты CTA — жасыл акцент, жазу солда, көрсеткі оңда
  /// (kind=accent).
  accent,
}

/// Экран еніндегі 48 dp батырма (Figma «v2 · Components / Button»).
class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = AppButtonVariant.filled,
    this.loading = false,
    this.icon,
  });

  const AppButton.tonal({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
    this.icon,
  }) : variant = AppButtonVariant.tonal;

  const AppButton.text({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
    this.icon,
  }) : variant = AppButtonVariant.text;

  const AppButton.danger({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
    this.icon = AppIcons.delete,
  }) : variant = AppButtonVariant.danger;

  const AppButton.accent({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
    this.icon = AppIcons.forward,
  }) : variant = AppButtonVariant.accent;

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;

  /// Сұрау орындалып жатқанда батырма бұғатталып, индикатор көрсетіледі.
  final bool loading;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final palette = context.palette;
    final action = loading ? null : onPressed;
    final onInk =
        variant == AppButtonVariant.filled ||
        variant == AppButtonVariant.danger;
    final accent = variant == AppButtonVariant.accent;
    final child = loading
        ? SizedBox.square(
            dimension: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: onInk
                  ? colors.onPrimary
                  : accent
                  ? palette.onAccent
                  : colors.primary,
            ),
          )
        : accent
        ? Row(
            children: [
              Expanded(child: Text(label)),
              if (icon != null) ...[
                const SizedBox(width: 8),
                Icon(icon, size: 20),
              ],
            ],
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 20),
                const SizedBox(width: 8),
              ],
              Flexible(child: Text(label, textAlign: TextAlign.center)),
            ],
          );

    const minSize = Size(double.infinity, AppSpacing.controlHeight);
    final button = switch (variant) {
      AppButtonVariant.filled || AppButtonVariant.danger => FilledButton(
        onPressed: action,
        style: FilledButton.styleFrom(minimumSize: minSize),
        child: child,
      ),
      AppButtonVariant.tonal => OutlinedButton(
        onPressed: action,
        style: OutlinedButton.styleFrom(minimumSize: minSize),
        child: child,
      ),
      AppButtonVariant.text => TextButton(
        onPressed: action,
        style: TextButton.styleFrom(minimumSize: minSize),
        child: child,
      ),
      AppButtonVariant.accent => FilledButton(
        onPressed: action,
        style: FilledButton.styleFrom(
          minimumSize: minSize,
          backgroundColor: palette.accent,
          foregroundColor: palette.onAccent,
        ),
        child: child,
      ),
    };

    return Semantics(
      button: true,
      enabled: action != null,
      label: loading ? label : null,
      excludeSemantics: loading,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: AppSpacing.controlHeight),
        child: button,
      ),
    );
  }
}

/// Мәтін ішіндегі сілтеме-батырма: «Парольді ұмыттыңыз ба?».
/// Сенсорлық аймағы кемінде 48 × 48.
class AppLink extends StatelessWidget {
  const AppLink({
    super.key,
    required this.label,
    required this.onPressed,
    this.color,
    this.alignment = Alignment.centerLeft,
  });

  final String label;
  final VoidCallback? onPressed;
  final Color? color;
  final AlignmentGeometry alignment;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          foregroundColor: color ?? context.palette.ink,
          padding: EdgeInsets.zero,
          shape: const RoundedRectangleBorder(),
          textStyle: context.text.labelLarge!.copyWith(
            decoration: TextDecoration.underline,
          ),
          minimumSize: const Size(
            AppSpacing.touchTarget,
            AppSpacing.touchTarget,
          ),
          tapTargetSize: MaterialTapTargetSize.padded,
        ),
        child: Text(label),
      ),
    );
  }
}
