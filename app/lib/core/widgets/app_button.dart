import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

enum AppButtonVariant {
  /// Негізгі әрекет — primary фон.
  filled,

  /// Қосымша әрекет — secondaryContainer фон.
  tonal,

  /// Мәтіндік батырма.
  text,

  /// Қайтарылмайтын әрекет — error фон.
  danger,
}

/// Экран еніндегі 56 dp батырма (Figma «Component / Button / …»).
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
    this.icon,
  }) : variant = AppButtonVariant.danger;

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;

  /// Сұрау орындалып жатқанда батырма бұғатталып, индикатор көрсетіледі.
  final bool loading;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final action = loading ? null : onPressed;
    final child = loading
        ? SizedBox.square(
            dimension: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color:
                  variant == AppButtonVariant.filled ||
                      variant == AppButtonVariant.danger
                  ? colors.onPrimary
                  : colors.primary,
            ),
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
      AppButtonVariant.filled => FilledButton(onPressed: action, child: child),
      AppButtonVariant.tonal => FilledButton.tonal(
        onPressed: action,
        style: FilledButton.styleFrom(
          backgroundColor: colors.secondaryContainer,
          foregroundColor: colors.primary,
        ),
        child: child,
      ),
      AppButtonVariant.text => TextButton(
        onPressed: action,
        style: TextButton.styleFrom(minimumSize: minSize),
        child: child,
      ),
      AppButtonVariant.danger => FilledButton(
        onPressed: action,
        style: FilledButton.styleFrom(
          backgroundColor: colors.error,
          foregroundColor: colors.onError,
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
          foregroundColor: color ?? context.colors.primary,
          padding: EdgeInsets.zero,
          shape: const RoundedRectangleBorder(),
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
