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
import 'assessment_details.dart';

/// Сақталған жауап және оның талдауы (тек қарау, жаңа жаттығу емес).
class SavedAnswerScreen extends StatelessWidget {
  const SavedAnswerScreen({
    super.key,
    required this.sessionId,
    required this.index,
  });

  final String sessionId;
  final int index;

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionRepository>().byId(sessionId);
    if (session == null || index >= session.answers.length) {
      return AppPage(showBack: true, title: S.sessionAnswers);
    }
    final record = session.answers[index];
    final colors = context.colors;

    final topic = context.read<TopicRepository>().tryById(
      record.question.topicId,
    );
    final p = context.palette;
    final small = context.text.bodySmall!.copyWith(
      color: colors.onSurfaceVariant,
    );
    return AppPage(
      showBack: true,
      header: Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
        child: Text(
          '${index + 1} / ${session.questionCount} · '
          '${Fmt.day(session.startedAt)}',
          style: small,
        ),
      ),
      body: [
        if (topic != null) Text(topic.title, style: small),
        const SizedBox(height: AppSpacing.xs),
        Semantics(
          header: true,
          child: Text(record.question.text, style: context.text.headlineSmall),
        ),
        const SizedBox(height: AppSpacing.md),
        // Өткізілген сұраққа тікелей сілтемемен келсе: жауап жоқ, 0 балл —
        // «бағалау күтілуде» емес.
        if (record.status case AnswerStatus.skipped || AnswerStatus.notAnswered)
          FullBleed(
            child: InfoBanner(
              kind: BannerKind.info,
              title: record.status == AnswerStatus.skipped
                  ? S.skippedPoints
                  : S.notAnswered,
            ),
          )
        else ...[
          // E7: жауап — сұр жолақта, код атаулары моно.
          FullBleed(
            child: Container(
              color: p.muted,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: AppSpacing.xs,
                children: [
                  Text(S.yourAnswerSaved, style: context.text.labelLarge),
                  CodeText(record.text, style: context.text.bodyMedium),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          if (record.status == AnswerStatus.assessed)
            AssessmentDetails(
              record: record,
              onDispute: () => context.push(Routes.dispute(sessionId, index)),
            )
          else
            FullBleed(
              child: InfoBanner(
                kind: BannerKind.warning,
                title: S.statusPending,
                body: S.unassessedNotZero,
              ),
            ),
        ],
      ],
      actions: [
        AppButton.tonal(
          label: S.readModelAnswer,
          onPressed: () => context.push(Routes.modelAnswer(sessionId, index)),
        ),
        AppButton.text(
          label: S.questionList,
          onPressed: () => context.canPop()
              ? context.pop()
              : context.go(Routes.answers(sessionId)),
        ),
      ],
    );
  }
}
