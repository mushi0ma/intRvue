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
import '../../data/models/interview_session.dart';
import '../../data/repositories/session_repository.dart';

/// Сессия жауаптары: бағаланған, өткізілген және күтілетін сұрақтар
/// мәтінмен ажыратылады.
class SessionAnswersScreen extends StatelessWidget {
  const SessionAnswersScreen({super.key, required this.sessionId});

  final String sessionId;

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionRepository>().byId(sessionId);
    if (session == null) {
      return AppPage(showBack: true, title: S.sessionAnswers);
    }
    final colors = context.colors;

    final secondary = colors.onSurfaceVariant;
    return AppPage(
      showBack: true,
      header: Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
        child: Text(
          '${Fmt.day(session.startedAt)} · ${session.trackLabel}',
          style: context.text.bodySmall!.copyWith(color: secondary),
        ),
      ),
      title: S.sessionAnswers,
      subtitle: [
        S.questionsCount(session.questionCount),
        '${session.pointsEarned} / ${session.pointsMax} ${S.pointsWord}',
        if (session.score != null) Fmt.score(session.score!),
      ].join(' · '),
      body: [
        // E6: толық енді тізім; әр жолда үш өлшемнің ұяшықтары.
        FullBleed(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Divider(),
              for (var i = 0; i < session.answers.length; i++) ...[
                _row(context, session, i),
                const Divider(),
              ],
            ],
          ),
        ),
      ],
      actions: [
        AppButton.tonal(
          label: S.backToSummary,
          onPressed: () => context.canPop()
              ? context.pop()
              : context.go(Routes.summary(sessionId)),
        ),
      ],
    );
  }

  Widget _row(BuildContext context, InterviewSession session, int i) {
    final record = session.answers[i];
    final p = context.palette;
    final a = record.assessment;
    final (status, openable) = switch (record.status) {
      AnswerStatus.assessed => (record.disputed ? S.disputedMark : null, true),
      AnswerStatus.pending => (S.pendingPoints, true),
      AnswerStatus.skipped => (S.skippedPoints, false),
      AnswerStatus.notAnswered => (S.notAnswered, false),
    };
    final cells = switch (record.status) {
      AnswerStatus.assessed => [
        for (final v in [a!.correctness, a.completeness, a.clarity])
          ScoreCell(text: '$v', band: bandOf(v), width: 32, height: 32),
      ],
      AnswerStatus.pending => [
        for (var k = 0; k < 3; k++)
          const ScoreCell(
            text: '…',
            band: ScoreBand.pending,
            width: 32,
            height: 32,
          ),
      ],
      _ => [
        for (var k = 0; k < 3; k++)
          const ScoreCell(
            text: '—',
            band: ScoreBand.skipped,
            width: 32,
            height: 32,
          ),
      ],
    };
    final label = [
      '${i + 1}. ${record.question.text}',
      if (a != null) S.assessedPoints(a.total),
      ?status,
    ].join('. ');
    return Material(
      color: record.disputed ? p.warningContainer : Colors.transparent,
      child: InkWell(
        onTap: openable
            ? () => context.push(Routes.answer(session.id, i))
            : null,
        child: Semantics(
          button: openable,
          label: label,
          excludeSemantics: true,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 8, 10),
            child: Row(
              children: [
                SizedBox(
                  width: 20,
                  child: Text('${i + 1}', style: context.text.bodySmall),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        record.question.text,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.text.bodyMedium,
                      ),
                      if (status != null)
                        Text(
                          status,
                          style: context.text.bodySmall!.copyWith(
                            color:
                                record.status == AnswerStatus.pending ||
                                    record.disputed
                                ? p.onWarningContainer
                                : context.colors.onSurfaceVariant,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                ...[
                  for (final c in cells)
                    Padding(padding: const EdgeInsets.only(left: 4), child: c),
                ],
                SizedBox(
                  width: 28,
                  child: openable
                      ? Icon(
                          AppIcons.chevronRight,
                          size: 20,
                          color: context.colors.onSurfaceVariant,
                        )
                      : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
