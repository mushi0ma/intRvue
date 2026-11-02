import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../app/routes.dart';
import '../../core/constants/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
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

  /// D13: үстінде «Mobile · Бастапқы» және күй тегі, астында атау.
  Widget _header(BuildContext context, InterviewSession s, Widget tag) => Row(
    children: [
      Expanded(
        child: Text(
          s.trackLabel,
          style: context.text.bodySmall!.copyWith(
            color: context.colors.onSurfaceVariant,
          ),
        ),
      ),
      tag,
    ],
  );

  Widget _complete(BuildContext context, InterviewSession s, bool canPop) {
    final colors = context.colors;
    final topics = context.read<TopicRepository>();
    final small = context.text.bodySmall!.copyWith(
      color: colors.onSurfaceVariant,
    );
    final score = Fmt.score(s.score!);

    return AppPage(
      showBack: canPop,
      header: Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
        child: _header(
          context,
          s,
          AppTag(S.statusComplete, kind: TagKind.success),
        ),
      ),
      title: S.summaryTitle,
      subtitle:
          '${Fmt.dayTime(s.startedAt)} · ${S.questionsCount(s.questionCount)}',
      body: [
        Semantics(
          label: '$score / 100',
          excludeSemantics: true,
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(text: score, style: context.text.displayLarge),
                TextSpan(
                  text: '  / 100',
                  style: context.text.bodyLarge!.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            textScaler: MediaQuery.textScalerOf(context)
                .clamp(maxScaleFactor: 1.3),
          ),
        ),
        Text(
          S.summaryCounts(s.answeredCount, s.skippedCount, s.assessedCount),
          style: small,
        ),
        const SizedBox(height: AppSpacing.lg),
        _AnswersTable(session: s),
        const SizedBox(height: AppSpacing.lg),
        GroupHeader(title: S.byTopic),
        for (final entry in s.topicScores.entries) ...[
          ScoreBar(
            label: topics.tryById(entry.key)?.title ?? entry.key,
            score: entry.value,
            valueText: Fmt.score(entry.value),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        Text(
          '${S.aiDisclaimer} '
          '${S.summaryFormula(s.pointsEarned, s.pointsMax, score)}',
          style: small,
        ),
      ],
      actions: [
        AppButton.accent(
          label: S.whatToReview,
          onPressed: () => context.push(Routes.recommendations(s.id)),
        ),
        AppButton.tonal(
          label: S.reviewAnswers,
          onPressed: () => context.push(Routes.answers(s.id)),
        ),
      ],
    );
  }

  Widget _incomplete(BuildContext context, InterviewSession s, bool canPop) {
    final colors = context.colors;
    final p = context.palette;
    final pending = s.pendingCount > 0;
    final done = s.answeredCount + s.skippedCount;

    return AppPage(
      showBack: canPop,
      header: Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
        child: _header(
          context,
          s,
          AppTag(
            pending ? S.statusPending : S.statusIncomplete,
            kind: TagKind.warning,
          ),
        ),
      ),
      title: S.summaryIncompleteTitle,
      subtitle: '${Fmt.dayTime(s.startedAt)} · $done / ${s.questionCount}',
      body: [
        const SizedBox(height: AppSpacing.sm),
        // Балл жоқ: «—» орнына жуан сызық және түсініктеме.
        Semantics(
          label: S.scoreNotReady,
          excludeSemantics: true,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(width: 32, height: 3, color: p.ink),
              const SizedBox(width: AppSpacing.md),
              Text(
                S.scoreNotReady,
                style: context.text.bodyMedium!.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          S.incompleteCounts(
            s.answeredCount,
            s.skippedCount,
            s.assessedCount,
            s.pendingCount,
          ),
          style: context.text.bodySmall!.copyWith(
            color: colors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        FullBleed(
          child: InfoBanner(
            kind: BannerKind.warning,
            title: S.unassessedNotZero,
            body: S.incompleteBody,
            actionLabel: pending && !_retrying ? S.retryAssessment : null,
            onAction: pending && !_retrying ? _retry : null,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        _AnswersTable(session: s),
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
          AppButton.text(
            label: S.toHistory,
            onPressed: () => context.go(Routes.history),
          ),
      ],
    );
  }
}

/// D13 кестесі: сұрақ, үш өлшем, барлығы. «…» — күтілуде, «—» — өткізілді.
class _AnswersTable extends StatelessWidget {
  const _AnswersTable({required this.session});

  final InterviewSession session;

  @override
  Widget build(BuildContext context) {
    final small = context.text.bodySmall!.copyWith(
      color: context.colors.onSurfaceVariant,
    );
    const cell = 36.0;
    Widget head(String t) => SizedBox(
      width: cell + 4,
      child: Text(
        t,
        style: small.copyWith(fontSize: 11),
        textAlign: TextAlign.center,
        maxLines: 1,
        softWrap: false,
        overflow: TextOverflow.fade,
      ),
    );
    // Кесте ұяшықтары бекітілген: мәтін 130%-дан аспайды, ал экран оқу
    // құралына әр жол толық сипатталады (Semantics label).
    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: 1.3,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ExcludeSemantics(
            child: Row(
              children: [
                Expanded(child: Text(S.rubricQuestion, style: small)),
                head(S.colCorrect),
                head(S.colComplete),
                head(S.colClarity),
                SizedBox(
                  width: 52,
                  child: Text(
                    S.colTotal,
                    style: small.copyWith(fontSize: 11),
                    textAlign: TextAlign.end,
                    maxLines: 1,
                    softWrap: false,
                    overflow: TextOverflow.fade,
                  ),
                ),
              ],
            ),
          ),
          for (var i = 0; i < session.answers.length; i++)
            _row(context, i, cell),
          const SizedBox(height: AppSpacing.sm),
          Text(S.tableLegend, style: small),
        ],
      ),
    );
  }

  Widget _row(BuildContext context, int i, double cell) {
    final r = session.answers[i];
    final a = r.assessment;
    final (cells, total) = switch (r.status) {
      AnswerStatus.assessed => (
        [
          for (final v in [a!.correctness, a.completeness, a.clarity])
            ScoreCell(text: '$v', band: bandOf(v), width: cell, height: cell),
        ],
        '${a.total}',
      ),
      AnswerStatus.pending => (
        [
          for (var k = 0; k < 3; k++)
            ScoreCell(
              text: '…',
              band: ScoreBand.pending,
              width: cell,
              height: cell,
            ),
        ],
        '…',
      ),
      _ => (
        [
          for (var k = 0; k < 3; k++)
            ScoreCell(
              text: '—',
              band: ScoreBand.skipped,
              width: cell,
              height: cell,
            ),
        ],
        '0',
      ),
    };
    return Semantics(
      label: '${i + 1}. ${r.question.text}: $total',
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.only(top: 6),
        child: Row(
          children: [
            SizedBox(
              width: 18,
              child: Text('${i + 1}', style: context.text.bodySmall),
            ),
            Expanded(
              child: Text(
                r.question.text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.text.bodyMedium,
              ),
            ),
            for (final c in cells)
              Padding(padding: const EdgeInsets.only(left: 4), child: c),
            SizedBox(
              width: 52,
              child: Text(
                total,
                textAlign: TextAlign.end,
                style: context.text.headlineSmall,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
