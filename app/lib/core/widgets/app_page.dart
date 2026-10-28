import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import 'app_back_link.dart';

/// Экран енімен созылатын виджет: AppPage оған шет қоспайды.
abstract interface class FullWidth {}

/// Кез келген мазмұнды экран енімен созу.
class FullBleed extends StatelessWidget implements FullWidth {
  const FullBleed({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => child;
}

/// Барлық экранның ортақ қаңқасы (Figma: 412 × 892, шет 24).
///
/// ```
/// [Артқа]                [trailing]
/// Тақырып 30/600
/// Сипаттама 14/400
/// ...children (айналады)...
/// [actions — төменге бекітілген]
/// ```
class AppPage extends StatelessWidget {
  const AppPage({
    super.key,
    this.title,
    this.subtitle,
    this.titleStyle,
    this.subtitleStyle,
    this.showBack = false,
    this.backLabel,
    this.onBack,
    this.leading,
    this.trailing,
    this.body = const [],
    this.actions = const [],
    this.headerGap = AppSpacing.xl,
    this.scrollController,
    this.bottomNavigation = false,
  });

  final String? title;
  final String? subtitle;
  final TextStyle? titleStyle;
  final TextStyle? subtitleStyle;

  /// «Артқа» сілтемесін көрсету.
  final bool showBack;
  final String? backLabel;
  final VoidCallback? onBack;

  /// «Артқа» орнына басқа сол жақ элемент (мысалы, «Үзіліс»).
  final Widget? leading;
  final Widget? trailing;

  final List<Widget> body;

  /// Төменгі батырмалар.
  final List<Widget> actions;

  /// Тақырып блогы мен мазмұн арасындағы қашықтық.
  final double headerGap;
  final ScrollController? scrollController;

  /// Экран NavigationBar ішінде тұр — төменгі жүйелік шетті ол алады.
  final bool bottomNavigation;

  @override
  Widget build(BuildContext context) {
    final hasTopBar = showBack || leading != null || trailing != null;
    const inset = EdgeInsets.symmetric(horizontal: AppSpacing.inset);

    final header = <Widget>[
      if (title != null) ...[
        SizedBox(height: hasTopBar ? AppSpacing.lg : 36),
        Padding(
          padding: inset,
          child: Semantics(
            header: true,
            child: Text(
              title!,
              style: titleStyle ?? context.text.headlineLarge,
            ),
          ),
        ),
      ],
      if (subtitle != null) ...[
        const SizedBox(height: 10),
        Padding(
          padding: inset,
          child: Text(
            subtitle!,
            style: (subtitleStyle ?? context.text.bodyMedium!).copyWith(
              color: context.colors.onSurfaceVariant,
            ),
          ),
        ),
      ],
      if (title != null || subtitle != null) SizedBox(height: headerGap),
    ];

    return Scaffold(
      // Төменгі батырмалар Scaffold-тың төменгі слотында: SnackBar олардың
      // үстінен шығады (жаппайды), пернетақта ашылғанда бірге көтеріледі.
      bottomNavigationBar: actions.isEmpty
          ? null
          : _ActionBar(actions: actions),
      body: SafeArea(
        bottom: !bottomNavigation && actions.isEmpty,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AppSpacing.maxContentWidth,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (hasTopBar)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        minHeight: AppSpacing.touchTarget,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child:
                                leading ??
                                (showBack
                                    ? AppBackLink(
                                        label: backLabel,
                                        onPressed: onBack,
                                      )
                                    : const SizedBox.shrink()),
                          ),
                          if (trailing != null) Flexible(child: trailing!),
                        ],
                      ),
                    ),
                  ),
                Expanded(
                  child: SingleChildScrollView(
                    controller: scrollController,
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        ...header,
                        for (final child in body)
                          child is FullWidth
                              ? child
                              : Padding(padding: inset, child: child),
                        const SizedBox(height: AppSpacing.lg),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ActionBar extends StatelessWidget {
  const _ActionBar({required this.actions});

  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        top: false,
        child: Center(
          heightFactor: 1,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AppSpacing.maxContentWidth,
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.inset,
                AppSpacing.sm,
                AppSpacing.inset,
                AppSpacing.xl,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: AppSpacing.md,
                children: actions,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
