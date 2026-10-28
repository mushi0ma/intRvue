import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/constants/app_strings.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_spacing.dart';

/// Төрт негізгі бөлім: Басты бет, Тарих, Прогресс, Баптаулар.
/// Тар экранда — NavigationBar, кең экранда (≥ 600) — NavigationRail.
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  static List<(IconData, IconData, String)> get _destinations => [
    (Icons.grid_view_outlined, Icons.grid_view_rounded, S.navHome),
    (Icons.schedule_outlined, Icons.watch_later, S.navHistory),
    (Icons.bar_chart_outlined, Icons.bar_chart_rounded, S.navProgress),
    (Icons.tune_outlined, Icons.tune_rounded, S.navSettings),
  ];

  void _onSelect(int index) {
    navigationShell.goBranch(
      index,
      // Белсенді бөлімді қайта басқанда — оның бастапқы экранына.
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= AppSpacing.railBreakpoint;

    if (wide) {
      return Scaffold(
        body: Row(
          children: [
            ColoredBox(
              color: context.palette.navigationBar,
              child: SafeArea(
                right: false,
                child: NavigationRail(
                  selectedIndex: navigationShell.currentIndex,
                  onDestinationSelected: _onSelect,
                  groupAlignment: -0.6,
                  destinations: [
                    for (final (icon, selected, label) in _destinations)
                      NavigationRailDestination(
                        icon: Icon(icon),
                        selectedIcon: Icon(selected),
                        label: Text(label),
                      ),
                  ],
                ),
              ),
            ),
            Expanded(child: navigationShell),
          ],
        ),
      );
    }

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: _onSelect,
        destinations: [
          for (final (icon, selected, label) in _destinations)
            NavigationDestination(
              icon: Icon(icon),
              selectedIcon: Icon(selected),
              label: label,
            ),
        ],
      ),
    );
  }
}
