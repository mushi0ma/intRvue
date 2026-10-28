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

    return AppPage(
      showBack: true,
      title: S.sessionAnswers,
      subtitle: '${Fmt.day(session.startedAt)} · ${session.trackLabel}',
      headerGap: 32,
      body: [
        for (var i = 0; i < session.answers.length; i++)
          _row(context, session, i, colors),
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

  Widget _row(
    BuildContext context,
    InterviewSession session,
    int i,
    ColorScheme colors,
  ) {
    final record = session.answers[i];
    final (status, color, openable) = switch (record.status) {
      AnswerStatus.assessed => (
        S.assessedPoints(record.assessment!.total),
        null,
        true,
      ),
      AnswerStatus.pending => (
        S.pendingPoints,
        context.palette.onWarningContainer,
        true,
      ),
      AnswerStatus.skipped => (S.skippedPoints, null, false),
      AnswerStatus.notAnswered => (S.notAnswered, null, false),
    };
    return ListRow(
      title: '${i + 1}. ${record.question.text}',
      subtitle: status,
      subtitleColor: color,
      trailing: openable
          ? Icon(Icons.chevron_right, color: colors.onSurfaceVariant)
          : null,
      onTap: openable ? () => context.push(Routes.answer(session.id, i)) : null,
    );
  }
}
