import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/constants/app_strings.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_spacing.dart';
import '../core/widgets/feedback.dart';
import '../data/repositories/sync_repository.dart';

/// Төрт негізгі бөлім: Басты бет, Тарих, Прогресс, Баптаулар.
/// Тар экранда — NavigationBar, кең экранда (≥ 600) — NavigationRail.
/// Басқа құрылғыдан деректер келсе — қысқа хабарлама.
class AppShell extends StatefulWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  StreamSubscription<RemoteUpdate>? _remote;

  StatefulNavigationShell get navigationShell => widget.navigationShell;

  @override
  void initState() {
    super.initState();
    _remote = context.read<SyncRepository>().remoteUpdates.listen((u) {
      if (!mounted) return;
      showAppSnackBar(context, S.syncRemoteUpdate(u.sessions + u.topics));
    });
  }

  @override
  void dispose() {
    _remote?.cancel();
    super.dispose();
  }

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
    // Системный «Артқа» басқа бөлімнен алдымен Басты бетке қайтарады,
    // қосымшадан тек Басты беттен шығады (BUG-8.01).
    return PopScope(
      canPop: navigationShell.currentIndex == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) navigationShell.goBranch(0);
      },
      child: _layout(context),
    );
  }

  Widget _layout(BuildContext context) {
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
