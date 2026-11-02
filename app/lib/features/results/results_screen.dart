import 'package:flutter/material.dart';

import '../../core/constants/app_strings.dart';
import '../../core/theme/app_spacing.dart';
import '../history/history_screen.dart';
import '../progress/progress_screen.dart';

enum ResultsTab { history, progress }

/// E1/E4 Нәтижелер — төменгі навигацияның үшінші бөлімі: «Тарих» және
/// «Прогресс» бір экранда, астын сызған қойындылармен.
class ResultsScreen extends StatefulWidget {
  const ResultsScreen({super.key, this.tab = ResultsTab.history});

  final ResultsTab tab;

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen>
    with SingleTickerProviderStateMixin {
  late final _tabs = TabController(
    length: ResultsTab.values.length,
    vsync: this,
    initialIndex: widget.tab.index,
  );

  @override
  void didUpdateWidget(ResultsScreen old) {
    super.didUpdateWidget(old);
    // `/results?tab=progress` сілтемесі ашық экранға келсе.
    if (old.tab != widget.tab) _tabs.animateTo(widget.tab.index);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AppSpacing.maxContentWidth,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.inset,
                    AppSpacing.lg,
                    AppSpacing.inset,
                    AppSpacing.sm,
                  ),
                  child: Semantics(
                    header: true,
                    child: Text(
                      S.resultsTitle,
                      style: Theme.of(context).textTheme.headlineLarge,
                    ),
                  ),
                ),
                TabBar(
                  controller: _tabs,
                  isScrollable: true,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.inset,
                  ),
                  tabs: [
                    Tab(text: S.navHistory),
                    Tab(text: S.navProgress),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    controller: _tabs,
                    children: const [HistoryScreen(), ProgressScreen()],
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
