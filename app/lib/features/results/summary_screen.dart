import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../app/routes.dart';
import '../../core/constants/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/widgets.dart';
import '../../data/models/interview_session.dart';
import '../../data/repositories/session_repository.dart';
import '../../data/repositories/topic_repository.dart';

/// S11 Қорытынды және «Нәтиже толық емес» күйі.
class SummaryScreen extends StatefulWidget {
  const SummaryScreen({super.key, required this.sessionId});

  final String sessionId;

  @override
  State<SummaryScreen> createState() => _SummaryScreenState();
}

class _SummaryScreenState extends State<SummaryScreen> {
  bool _retrying = false;

  Future<void> _retry() async {
    setState(() => _retrying = true);
    await context.read<SessionRepository>().retryPending(widget.sessionId);
    if (mounted) setState(() => _retrying = false);
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionRepository>().byId(widget.sessionId);
    if (session == null) {
      return AppPage(showBack: true, title: S.historyEmptyTitle);
    }
    final canPop = context.canPop();
    final page = session.isComplete
        ? _complete(context, session, canPop)
        : _incomplete(context, session, canPop);

    return PopScope(
      canPop: canPop,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) context.go(Routes.home);
      },
      child: page,
    );
  }

  Widget _complete(BuildContext context, InterviewSession s, bool canPop) {
    final colors = context.colors;
    final topics = context.read<TopicRepository>();
    final muted = context.text.bodyMedium!.copyWith(
      color: colors.onSurfaceVariant,
    );
    final score = Fmt.score(s.score!);

    return AppPage(
      showBack: canPop,
      title: S.summaryTitle,
      subtitle: '${s.trackLabel} · ${Fmt.day(s.startedAt)}',
      headerGap: 40,
      body: [
        StatusChip(label: S.statusComplete),
        const SizedBox(height: 24),
        Semantics(
          label: '$score / 100',
          excludeSemantics: true,
          child: Wrap(
            crossAxisAlignment: WrapCrossAlignment.end,
            spacing: 16,
            children: [
              Text(
                score,
                style: context.text.displayLarge!.copyWith(
                  color: colors.primary,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  S.outOf100,
                  style: context.text.titleLarge!.copyWith(
                    fontWeight: FontWeight.w400,
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Text(
          S.summaryCounts(s.answeredCount, s.skippedCount, s.assessedCount),
          style: muted,
        ),
        const SectionDivider(vertical: 28),
        Text(S.byTopic, style: context.text.titleLarge),
        const SizedBox(height: 24),
        for (final entry in s.topicScores.entries) ...[
          ScoreBar(
            label: topics.tryById(entry.key)?.title ?? entry.key,
            score: entry.value,
            valueText: Fmt.score(entry.value),
          ),
          const SizedBox(height: 28),
        ],
        Text(
          '${S.aiDisclaimer}\n'
          '${S.summaryFormula(s.pointsEarned, s.pointsMax, score)}',
          style: muted,
        ),
      ],
      actions: [
        AppButton(
          label: S.whatToReview,
          onPressed: () => context.push(Routes.recommendations(s.id)),
        ),
        AppLink(
          label: S.reviewAnswers,
          alignment: Alignment.center,
          onPressed: () => context.push(Routes.answers(s.id)),
        ),
      ],
    );
  }

  Widget _incomplete(BuildContext context, InterviewSession s, bool canPop) {
    final colors = context.colors;
    final muted = context.text.bodyLarge!.copyWith(
      color: colors.onSurfaceVariant,
    );
    final pending = s.pendingCount > 0;

    return AppPage(
      showBack: canPop,
      title: S.summaryIncompleteTitle,
      subtitle:
          '${s.trackLabel} · ${S.questionsCount(s.questionCount)}'
          ' · ${Fmt.day(s.startedAt)}',
      headerGap: 32,
      body: [
        StatusChip(
          label: pending ? S.statusPending : S.statusIncomplete,
          complete: false,
        ),
        const SizedBox(height: 40),
        Text(S.scoreNotReady, style: context.text.titleLarge),
        const SizedBox(height: 16),
        Text(
          S.incompleteCounts(
            s.answeredCount,
            s.skippedCount,
            s.assessedCount,
            s.pendingCount,
          ),
          style: muted,
        ),
        const SectionDivider(vertical: 32),
        Text(S.unassessedNotZero, style: context.text.titleMedium),
        const SizedBox(height: 16),
        Text(S.incompleteBody, style: muted),
      ],
      actions: [
        if (pending)
          AppButton(
            label: S.retryAssessment,
            loading: _retrying,
            onPressed: _retry,
          ),
        AppButton.tonal(
          label: S.reviewAnswers,
          onPressed: () => context.push(Routes.answers(s.id)),
        ),
        if (!pending)
          AppButton(
            label: S.toHistory,
            onPressed: () => context.go(Routes.history),
          ),
      ],
    );
  }
}
