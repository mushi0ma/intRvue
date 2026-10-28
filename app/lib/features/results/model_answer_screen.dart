import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/routes.dart';
import '../../core/constants/app_strings.dart';
import '../../core/utils/navigation.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/widgets.dart';
import '../../data/repositories/session_repository.dart';
import '../../data/repositories/topic_repository.dart';

/// Үлгі жауап: сұрақтың эталон түсіндірмесі және жауаптағы негізгі ұғымдар.
class ModelAnswerScreen extends StatelessWidget {
  const ModelAnswerScreen({
    super.key,
    required this.sessionId,
    required this.index,
  });

  final String sessionId;
  final int index;

  @override
  Widget build(BuildContext context) {
    final session = context.read<SessionRepository>().byId(sessionId);
    if (session == null || index >= session.answers.length) {
      return AppPage(showBack: true, title: S.modelAnswerTitle);
    }
    final question = session.answers[index].question;
    final topic = context.read<TopicRepository>().tryById(question.topicId);
    final colors = context.colors;

    return AppPage(
      showBack: true,
      title: S.modelAnswerTitle,
      subtitle: topic?.title,
      headerGap: 40,
      body: [
        Text(question.text, style: context.text.titleLarge),
        const SizedBox(height: 16),
        Text(
          question.modelAnswer,
          style: context.text.bodyLarge!.copyWith(
            color: colors.onSurfaceVariant,
          ),
        ),
        const SectionDivider(vertical: 28),
        Text(S.keyConcepts, style: context.text.titleMedium),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final concept in question.concepts)
              Chip(
                label: Text(concept.label),
                labelStyle: context.text.labelMedium,
                backgroundColor: colors.secondaryContainer,
                side: BorderSide.none,
              ),
          ],
        ),
      ],
      actions: [
        AppButton.tonal(
          label: S.backToFeedback,
          onPressed: () => context.popOr(Routes.history),
        ),
      ],
    );
  }
}
