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

    return AppPage(
      showBack: true,
      backLabel: S.questionList,
      title: S.savedAnswerHeader(index + 1, session.questionCount),
      titleStyle: context.text.titleLarge,
      subtitle: Fmt.dayTime(session.startedAt),
      headerGap: 28,
      body: [
        Text(record.question.text, style: context.text.headlineSmall),
        const SizedBox(height: 24),
        Text(
          S.yourAnswerSaved,
          style: context.text.titleSmall!.copyWith(color: colors.primary),
        ),
        const SizedBox(height: 12),
        Text(record.text, style: context.text.bodyLarge),
        const SizedBox(height: 28),
        if (record.status == AnswerStatus.assessed)
          AssessmentDetails(
            record: record,
            onDispute: () => context.push(Routes.dispute(sessionId, index)),
          )
        else
          InfoSection(
            title: S.statusPending,
            body: S.unassessedNotZero,
            bodyColor: context.palette.onWarningContainer,
          ),
      ],
      actions: [
        AppButton.tonal(
          label: S.readModelAnswer,
          onPressed: () => context.push(Routes.modelAnswer(sessionId, index)),
        ),
      ],
    );
  }
}
