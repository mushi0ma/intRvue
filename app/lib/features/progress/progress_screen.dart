import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../app/routes.dart';
import '../../core/constants/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/widgets.dart';
import '../../data/models/enums.dart';
import '../../data/models/interview_session.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/session_repository.dart';

/// S14 Прогресс: тек бір бағыт пен деңгейдегі толық сессиялар.
class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  static const _maxBars = 4;

  late final _user = context.read<AuthRepository>().user;
  late Direction _direction = _user?.direction ?? Direction.mobile;
  late Level _level = _user?.level ?? Level.beginner;

  @override
  Widget build(BuildContext context) {
    final all = context.watch<SessionRepository>().completeSessions(
      _direction,
      _level,
    );
    final recent = all.length > _maxBars
        ? all.sublist(all.length - _maxBars)
        : all;
    final colors = context.colors;
    final muted = context.text.bodyMedium!.copyWith(
      color: colors.onSurfaceVariant,
    );

    final filters = Row(
      spacing: 12,
      children: [
        Expanded(
          child: FilterDropdown<Direction>(
            value: _direction,
            values: Direction.values,
            labelOf: (d) => d.label,
            semanticLabel: S.fieldDirection,
            onChanged: (d) => setState(() => _direction = d),
          ),
        ),
        Expanded(
          child: FilterDropdown<Level>(
            value: _level,
            values: Level.values,
            labelOf: (l) => l.label,
            semanticLabel: S.fieldLevel,
            onChanged: (l) => setState(() => _level = l),
          ),
        ),
      ],
    );

    if (all.isEmpty) {
      return AppPage(
        bottomNavigation: true,
        title: S.progressTitle,
        subtitle: S.progressSubtitle,
        headerGap: 28,
        body: [
          filters,
          EmptyState(title: S.progressEmptyTitle, body: S.progressEmptyBody),
          const SectionDivider(vertical: 28),
          Text(S.progressEmptyHint, style: muted),
          const SizedBox(height: 24),
          AppButton(
            label: S.progressEmptyAction,
            onPressed: () => context.push(
              Uri(
                path: Routes.practiceTopics,
                queryParameters: {'direction': _direction.name},
              ).toString(),
            ),
          ),
        ],
      );
    }

    final average =
        all.map((s) => s.score!).reduce((a, b) => a + b) / all.length;

    return AppPage(
      bottomNavigation: true,
      title: S.progressTitle,
      subtitle: S.progressSubtitle,
      headerGap: 28,
      body: [
        filters,
        const SizedBox(height: 32),
        Text(S.lastSessions(recent.length), style: context.text.titleLarge),
        const SizedBox(height: 12),
        Text(S.scoreAxis, style: muted),
        const SizedBox(height: 20),
        _ScoreChart(sessions: recent),
        const SectionDivider(vertical: 28),
        Text(S.completeSessions(all.length), style: context.text.titleLarge),
        const SizedBox(height: 12),
        Text(
          S.averageScore(Fmt.score(average)),
          style: context.text.titleSmall!.copyWith(color: colors.primary),
        ),
        const SizedBox(height: 12),
        Text(S.incompleteExcluded, style: muted),
        const SizedBox(height: 24),
        Text(
          S.sampleData,
          style: context.text.bodySmall!.copyWith(
            color: colors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

/// Бағаналы диаграмма: 0–100 шкала, соңғы сессия primary түспен.
class _ScoreChart extends StatelessWidget {
  const _ScoreChart({required this.sessions});

  final List<InterviewSession> sessions;

  static const _height = 180.0;
  static const _axisWidth = 38.0;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final palette = context.palette;
    final axis = context.text.bodySmall!.copyWith(
      color: colors.onSurfaceVariant,
    );
    final description = sessions
        .map((s) => '${Fmt.shortDate(s.startedAt)}: ${Fmt.score(s.score!)}')
        .join(', ');

    return Semantics(
      label: '${S.scoreAxis}. $description',
      excludeSemantics: true,
      child: Column(
        children: [
          SizedBox(
            // Ең биік бағананың үстіндегі мәнге орын (мәтін масштабымен).
            height: _height + MediaQuery.textScalerOf(context).scale(18) + 8,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                for (final mark in const [0, 50, 75, 100])
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: _height * mark / 100 - 8,
                    child: Row(
                      children: [
                        SizedBox(
                          width: _axisWidth,
                          child: Text('$mark', style: axis),
                        ),
                        Expanded(
                          child: Container(
                            height: 1,
                            color: colors.outlineVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                Positioned.fill(
                  left: _axisWidth,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      for (var i = 0; i < sessions.length; i++)
                        _Bar(
                          value: sessions[i].score!,
                          maxHeight: _height,
                          color: i == sessions.length - 1
                              ? colors.primary
                              : palette.chartMuted,
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(left: _axisWidth),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                for (final s in sessions)
                  SizedBox(
                    width: 48,
                    child: Text(
                      Fmt.shortDate(s.startedAt),
                      style: axis,
                      textAlign: TextAlign.center,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({
    required this.value,
    required this.maxHeight,
    required this.color,
  });

  final double value;
  final double maxHeight;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 48,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            Fmt.score(value).replaceAll(',0', ''),
            style: context.text.labelMedium!.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            width: 44,
            height: maxHeight * value / 100,
            decoration: BoxDecoration(
              color: color,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(4),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
