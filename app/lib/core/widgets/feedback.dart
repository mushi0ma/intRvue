import 'package:flutter/material.dart';

import '../constants/app_strings.dart';
import '../theme/app_colors.dart';
import '../theme/app_icons.dart';
import '../theme/app_spacing.dart';

/// Растау диалогы (Figma «Dialog / Confirm»). true — растады.
Future<bool> showConfirmDialog(
  BuildContext context, {
  required String title,
  required String body,
  required String confirmLabel,
  String? cancelLabel,
  bool destructive = false,
  Widget? extra,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) {
      final colors = context.colors;
      return AlertDialog(
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              body,
              style: context.text.bodyLarge!.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
            if (extra != null) ...[const SizedBox(height: 16), extra],
          ],
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(cancelLabel ?? S.cancel),
          ),
          // Қауіпті әрекет қызыл емес: сия батырма + белгіше (Figma K.dialog).
          if (destructive)
            FilledButton.icon(
              onPressed: () => Navigator.of(context).pop(true),
              icon: const Icon(AppIcons.delete),
              label: Text(confirmLabel),
            )
          else
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(confirmLabel),
            ),
        ],
      );
    },
  );
  return result ?? false;
}

/// Қысқа хабарлама (Figma «Snackbar / With action»).
void showAppSnackBar(
  BuildContext context,
  String message, {
  String? actionLabel,
  VoidCallback? onAction,
}) {
  final messenger = ScaffoldMessenger.of(context);
  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(
    SnackBar(
      content: Text(message),
      persist: false,
      action: actionLabel == null
          ? null
          : SnackBarAction(label: actionLabel, onPressed: onAction ?? () {}),
    ),
  );
}

/// Сүзгі батырмасы (176 × 48, r12): таңдалған мән және ашылатын мәзір.
class FilterDropdown<T> extends StatelessWidget {
  const FilterDropdown({
    super.key,
    required this.value,
    required this.values,
    required this.labelOf,
    required this.onChanged,
    this.semanticLabel,
    this.expand = true,
    this.icon,
    this.highlighted = false,
  });

  /// true — сүзгі қолданылып тұр: чип сиямен толтырылады (Figma C1).
  final bool highlighted;

  /// Мәннің алдындағы белгіше (мысалы, тіл таңдауында — глобус).
  final IconData? icon;

  /// false — ені мәтінге қарай (Wrap ішінде): тар экранда қысқармайды.
  final bool expand;
  final T value;
  final List<T> values;
  final String Function(T) labelOf;
  final ValueChanged<T> onChanged;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final fg = highlighted ? colors.onPrimary : colors.onSurface;
    return PopupMenuButton<T>(
      tooltip: semanticLabel,
      initialValue: value,
      onSelected: onChanged,
      position: PopupMenuPosition.under,
      itemBuilder: (context) => [
        for (final v in values)
          PopupMenuItem(
            value: v,
            child: Text(labelOf(v), style: context.text.bodyLarge),
          ),
      ],
      // Figma чип-сүзгі: 40 dp, r10, сия жиек; сенсорлық аймақ 48.
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Container(
          constraints: const BoxConstraints(minHeight: 40),
          padding: const EdgeInsets.only(left: 12, right: 6),
          decoration: BoxDecoration(
            color: highlighted ? colors.primary : context.palette.surface,
            border: Border.all(color: context.palette.ink),
            borderRadius: BorderRadius.circular(AppRadius.chip),
          ),
          child: Row(
            mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18, color: fg),
                const SizedBox(width: 6),
              ],
              Flexible(
                fit: expand ? FlexFit.tight : FlexFit.loose,
                child: Text(
                  labelOf(value),
                  style: context.text.labelMedium!.copyWith(color: fg),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(AppIcons.dropdown, color: fg),
            ],
          ),
        ),
      ),
    );
  }
}
