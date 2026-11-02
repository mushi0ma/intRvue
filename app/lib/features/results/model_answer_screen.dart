import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/routes.dart';
import '../../core/constants/app_strings.dart';
import '../../core/utils/navigation.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
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

    final p = context.palette;
    return AppPage(
      showBack: true,
      header: Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
        child: Text(
          [S.questionN(index + 1), ?topic?.title].join(' · '),
          style: context.text.bodySmall!.copyWith(
            color: colors.onSurfaceVariant,
          ),
        ),
      ),
      title: S.modelAnswerTitle,
      body: [
        Text(question.text, style: context.text.titleMedium),
        const SizedBox(height: AppSpacing.smd),
        CodeText(question.modelAnswer, style: context.text.bodyMedium),
        const SizedBox(height: AppSpacing.lg),
        // D11: негізгі ұғымдар — сұр жолақта, сия жиекті чиптер.
        FullBleed(
          child: Container(
            color: p.muted,
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(S.keyConcepts, style: context.text.labelLarge),
                const SizedBox(height: AppSpacing.smd),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final concept in question.concepts)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: p.surface,
                          border: Border.all(color: p.ink),
                          borderRadius: BorderRadius.circular(AppRadius.chip),
                        ),
                        child: Text(
                          concept.label,
                          style: context.text.labelMedium,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
      actions: [
        AppButton(
          label: S.backToFeedback,
          onPressed: () => context.popOr(Routes.history),
        ),
      ],
    );
  }
}
