import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../app/routes.dart';
import '../../core/constants/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_icons.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/widgets.dart';
import '../../data/models/enums.dart';
import '../../data/models/interview_session.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/session_repository.dart';
import '../../data/repositories/topic_repository.dart';

/// S14 Прогресс: тек бір бағыт пен деңгейдегі толық сессиялар.
class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  /// Динамика терезесі: соңғы 5 толық сессия (Figma E4).
  static const _window = 5;

  late final _user = context.read<AuthRepository>().user;
  late Direction _direction = _user?.direction ?? Direction.mobile;
  late Level _level = _user?.level ?? Level.beginner;

  @override
  Widget build(BuildContext context) {
    final all = context.watch<SessionRepository>().completeSessions(
      _direction,
      _level,
    );
    final recent = all.length > _window
        ? all.sublist(all.length - _window)
        : all;
    final colors = context.colors;
    final small = context.text.bodySmall!.copyWith(
      color: colors.onSurfaceVariant,
    );

    final filters = FullBleed(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.inset),
        child: Row(
          spacing: AppSpacing.sm,
          children: [
            FilterDropdown<Direction>(
              expand: false,
              value: _direction,
              values: Direction.values,
              labelOf: (d) => d.label,
              semanticLabel: S.fieldDirection,
              onChanged: (d) => setState(() => _direction = d),
            ),
            FilterDropdown<Level>(
              expand: false,
              value: _level,
              values: Level.values,
              labelOf: (l) => l.label,
              semanticLabel: S.fieldLevel,
              onChanged: (l) => setState(() => _level = l),
            ),
          ],
        ),
      ),
    );

    if (all.isEmpty) {
      // E5: бос күй — белгіше, түсініктеме, бір әрекет.
      return AppPage(
        bottomNavigation: true,
        body: [
          const SizedBox(height: AppSpacing.md),
          filters,
          const SizedBox(height: AppSpacing.xxl),
          Center(
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                border: Border.all(color: context.palette.ink),
                borderRadius: BorderRadius.circular(AppRadius.control),
              ),
              child: const Icon(AppIcons.results),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            S.progressEmptyTitle,
            textAlign: TextAlign.center,
            style: context.text.titleLarge,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '${_direction.label} · ${_level.label}. ${S.progressEmptyBody}',
            textAlign: TextAlign.center,
            style: small,
          ),
          const SizedBox(height: AppSpacing.lg),
          Center(
            child: FilledButton(
              onPressed: () => context.push(
                Uri(
                  path: Routes.practiceTopics,
                  queryParameters: {
                    'direction': _direction.name,
                    'level': _level.name,
                  },
                ).toString(),
              ),
              style: FilledButton.styleFrom(
                minimumSize: const Size(0, AppSpacing.controlHeight),
                padding: const EdgeInsets.symmetric(horizontal: 20),
              ),
              child: Text(S.progressEmptyAction),
            ),
          ),
        ],
      );
    }

    final average =
        recent.map((s) => s.score!).reduce((a, b) => a + b) / recent.length;
    final delta = recent.length > 1
        ? recent.last.score! - recent.first.score!
        : null;
    final weak = _weakTopics(recent);
    final topics = context.read<TopicRepository>();

    return AppPage(
      bottomNavigation: true,
      body: [
        const SizedBox(height: AppSpacing.md),
        filters,
        const SizedBox(height: AppSpacing.md),
        Semantics(
          label: [
            S.averageScore(Fmt.score(average)),
            S.lastSessions(recent.length),
            if (delta != null)
              '${delta >= 0 ? '+' : '−'}${Fmt.score(delta.abs())}',
          ].join(', '),
          excludeSemantics: true,
          // Wrap: үлкен мәтінде түсініктеме санның астына түседі,
          // тар бағанда буынға бөлінбейді.
          child: Wrap(
            crossAxisAlignment: WrapCrossAlignment.end,
            spacing: AppSpacing.sm,
            children: [
              Text(
                Fmt.score(average),
                textScaler: MediaQuery.textScalerOf(context)
                    .clamp(maxScaleFactor: 1.3),
                style: context.text.displayLarge,
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  '${S.progressAverageLast} ${recent.length}',
                  style: small,
                ),
              ),
              if (delta != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    '${delta >= 0 ? '+' : '−'}${Fmt.score(delta.abs())}',
                    style: context.text.labelLarge!.copyWith(
                      color: delta >= 0 ? context.palette.success : null,
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        for (final (label, of) in <(String, int Function(AnswerRecord))>[
          (S.correctness, (a) => a.assessment?.correctness ?? 0),
          (S.completeness, (a) => a.assessment?.completeness ?? 0),
          (S.clarity, (a) => a.assessment?.clarity ?? 0),
        ])
          _CriterionStrip(
            label: label,
            values: [for (final s in recent) _criterionAverage(s, of)],
          ),
        const SizedBox(height: AppSpacing.sm),
        Text('${_dates(recent)} — ${S.progressLegendTail}', style: small),
        if (weak.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          GroupHeader(title: S.progressWeakTitle),
          ListGroup(
            children: [
              for (final (id, score, at) in weak)
                if (topics.tryById(id) case final topic?)
                  ItemRow(
                    title: topic.title,
                    meta: Fmt.day(at),
                    onTap: () => context.push(Routes.topic(id)),
                    trailing: Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        spacing: AppSpacing.sm,
                        children: [
                          Text(
                            '${score.round()}',
                            style: context.text.bodyLarge,
                          ),
                          const Icon(AppIcons.forward, size: 18),
                        ],
                      ),
                    ),
                  ),
            ],
          ),
        ],
        const SizedBox(height: AppSpacing.md),
        Text(S.sampleData, style: small),
      ],
    );
  }

  /// «9 · 12 · 17 · 19 қазан»; терезе екі айға созылса — әр күн айымен.
  static String _dates(List<InterviewSession> sessions) {
    final first = sessions.first.startedAt;
    final last = sessions.last.startedAt;
    if (first.year == last.year && first.month == last.month) {
      return '${sessions.map((s) => '${s.startedAt.day}').join(' · ')} '
          '${Fmt.month(last)}';
    }
    return sessions.map((s) => Fmt.day(s.startedAt)).join(' · ');
  }

  /// Бір сессиядағы өлшемнің орташасы (өткізілген — 0).
  static double _criterionAverage(
    InterviewSession s,
    int Function(AnswerRecord) of,
  ) => s.answers.map(of).fold(0, (a, b) => a + b) / s.answers.length;

  /// Терезедегі тақырыптар: орташа балл бойынша өсу ретімен, ең көбі 3.
  static List<(String, double, DateTime)> _weakTopics(
    List<InterviewSession> sessions,
  ) {
    final sum = <String, double>{};
    final count = <String, int>{};
    final last = <String, DateTime>{};
    for (final s in sessions) {
      s.topicScores.forEach((id, v) {
        sum[id] = (sum[id] ?? 0) + v;
        count[id] = (count[id] ?? 0) + 1;
        last[id] = s.startedAt;
      });
    }
    final out = [
      for (final id in sum.keys) (id, sum[id]! / count[id]!, last[id]!),
    ]..sort((a, b) => a.$2.compareTo(b.$2));
    return out.take(SessionRepository.maxRecommendations).toList();
  }
}

/// Өлшем жолағы (Figma E4): әр толық сессия — бір «таблетка», биіктігі
/// баллға пропорционал; соңғысы сиямен толтырылған.
class _CriterionStrip extends StatelessWidget {
  const _CriterionStrip({required this.label, required this.values});

  final String label;
  final List<double> values;

  static const _height = 40.0;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final avg = values.reduce((a, b) => a + b) / values.length;
    final text = '${Fmt.score(avg)} / 5';
    return Semantics(
      label: '$label: $text. ${values.map((v) => Fmt.score(v)).join(', ')}',
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: AppSpacing.sm,
          children: [
            Row(
              children: [
                Expanded(child: Text(label, style: context.text.bodyMedium)),
                Text(text, style: context.text.labelLarge),
              ],
            ),
            SizedBox(
              height: _height,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                spacing: 6,
                children: [
                  for (var i = 0; i < values.length; i++)
                    Expanded(
                      child: Container(
                        height: (values[i] / 5 * _height).clamp(10, _height),
                        decoration: BoxDecoration(
                          color: i == values.length - 1 ? p.ink : p.tonal,
                          borderRadius: BorderRadius.circular(AppRadius.chip),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
