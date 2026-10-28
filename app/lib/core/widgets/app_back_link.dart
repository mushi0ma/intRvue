import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../constants/app_strings.dart';

/// Жоғарғы сол жақтағы «Артқа» мәтіндік сілтемесі.
/// Стек бос болса, басты бетке өтеді — тұйыққа тірелмейді.
class AppBackLink extends StatelessWidget {
  const AppBackLink({super.key, this.label, this.onPressed});

  final String? label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed:
          onPressed ??
          () => context.canPop() ? context.pop() : context.go('/home'),
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 16),
      ),
      child: Text(label ?? S.back),
    );
  }
}
