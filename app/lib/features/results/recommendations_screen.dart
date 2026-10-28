import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../app/routes.dart';
import '../../core/constants/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/widgets.dart';
import '../../data/repositories/session_repository.dart';
import '../../data/repositories/topic_repository.dart';
import '../topics/topic_detail_screen.dart';

/// S12 Ұсынымдар: ең әлсіз тақырып және ең көбі тағы екеуі.
class RecommendationsScreen extends StatelessWidget {
  const RecommendationsScreen({super.key, required this.sessionId});

  final String sessionId;

  @override
  Widget build(BuildContext context) {
    final sessions = context.read<SessionRepository>();
    final topics = context.read<TopicRepository>();
    final session = sessions.byId(sessionId);
    final weak = session == null
        ? const <WeakTopic>[]
        : sessions.weakTopics(session);
    final colors = context.colors;
    final muted = context.text.bodyLarge!.copyWith(
      color: colors.onSurfaceVariant,
    );

    if (weak.isEmpty) {
      return AppPage(
        showBack: true,
        title: S.recommendTitle,
        body: [Text(S.noRecommendations, style: muted)],
        actions: [
          AppButton.tonal(
            label: S.toHome,
            onPressed: () => context.go(Routes.home),
          ),
        ],
      );
    }

    final main = weak.first;
    final mainTopic = topics.byId(main.topicId);
    final onBlock = TextStyle(color: colors.onPrimaryContainer);
    final answers = session!.answers
        .where((a) => a.question.topicId == main.topicId)
        .toList();
    final missing = {for (final a in answers) ...?a.assessment?.missing}
        .take(2)
        .join('; ');

    return AppPage(
      showBack: true,
      title: S.recommendTitle,
      subtitle: S.recommendSubtitle,
      headerGap: 40,
      body: [
        TrainingBlock(
          children: [
            Text(
              mainTopic.title,
              style: context.text.headlineMedium!.merge(onBlock),
            ),
            const SizedBox(height: 20),
            Text(
              S.recommendScore(Fmt.score(main.score)),
              style: context.text.bodyLarge!
                  .merge(onBlock)
                  .copyWith(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 16),
            Text(
              mainTopic.reviewPoints.join(', '),
              style: context.text.bodyLarge!.merge(onBlock),
            ),
            const SizedBox(height: 24),
            AppButton(
              label: S.practiceThisTopic,
              onPressed: () =>
                  context.push(TopicDetailScreen.practiceLocation(mainTopic)),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Text(S.whyThisTopic, style: context.text.titleLarge),
        const SizedBox(height: 16),
        Text(
          missing.isEmpty
              ? S.whyLowest(answers.length)
              : S.whyMissing(answers.length, missing),
          style: muted,
        ),
        if (weak.length > 1) ...[
          const SizedBox(height: 32),
          Text(S.otherWeakTopics, style: context.text.titleMedium),
          const SizedBox(height: 4),
          for (final w in weak.skip(1))
            ListRow(
              title: topics.byId(w.topicId).title,
              trailing: Text(
                Fmt.score(w.score),
                style: context.text.titleSmall!.copyWith(color: colors.primary),
              ),
              onTap: () => context.push(Routes.topic(w.topicId)),
            ),
        ],
        const SectionDivider(vertical: 24),
        Text(
          S.recommendLimit,
          style: context.text.bodyMedium!.copyWith(
            color: colors.onSurfaceVariant,
          ),
        ),
      ],
      actions: [
        AppButton.tonal(
          label: S.toHome,
          onPressed: () => context.go(Routes.home),
        ),
      ],
    );
  }
}
