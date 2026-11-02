import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';

/// Жаттығу экрандарының жоғарғы жолы (Figma D5/D9):
/// `[⏸] Жаттығу · Mobile · Бастапқы                2 / 5`.
class PracticeBar extends StatelessWidget {
  const PracticeBar({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    required this.label,
    this.counter,
    this.counterSemantics,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final String label;

  /// «2 / 5» — үлкен санауыш; экран оқу құралына [counterSemantics].
  final String? counter;
  final String? counterSemantics;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton.outlined(
          tooltip: tooltip,
          onPressed: onPressed,
          style: IconButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.control),
            ),
            side: BorderSide(color: context.palette.ink),
          ),
          icon: Icon(icon, size: 20),
        ),
        const SizedBox(width: AppSpacing.smd),
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: context.text.bodySmall!.copyWith(
              color: context.colors.onSurfaceVariant,
            ),
          ),
        ),
        if (counter != null)
          Padding(
            padding: const EdgeInsets.only(left: 8, right: 8),
            child: Text(
              counter!,
              semanticsLabel: counterSemantics,
              textScaler: MediaQuery.textScalerOf(context)
                  .clamp(maxScaleFactor: 1.3),
              style: context.text.headlineMedium,
            ),
          ),
      ],
    );
  }
}
