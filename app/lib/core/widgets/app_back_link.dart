import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../constants/app_strings.dart';
import '../theme/app_colors.dart';
import '../theme/app_icons.dart';
import '../theme/app_spacing.dart';

/// Жоғарғы сол жақтағы «Артқа» (Figma `IconButton / arrow_back`): 40 dp
/// шаршы, сия жиек, сенсорлық аймағы 48. [label] берілсе — мәтіндік
/// батырма («Үзіліс», «Сұрақтар тізімі»).
/// Стек бос болса, басты бетке өтеді — тұйыққа тірелмейді.
class AppBackLink extends StatelessWidget {
  const AppBackLink({super.key, this.label, this.onPressed});

  final String? label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final action =
        onPressed ??
        () => context.canPop() ? context.pop() : context.go('/home');
    if (label != null) {
      return TextButton(
        onPressed: action,
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 12),
        ),
        child: Text(label!),
      );
    }
    return IconButton(
      tooltip: S.back,
      onPressed: action,
      style: IconButton.styleFrom(
        fixedSize: const Size.square(40),
        minimumSize: const Size.square(40),
        tapTargetSize: MaterialTapTargetSize.padded,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.control),
        ),
        side: BorderSide(color: context.palette.ink),
      ),
      icon: const Icon(AppIcons.back, size: 20),
    );
  }
}
