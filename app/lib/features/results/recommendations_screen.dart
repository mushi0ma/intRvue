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
    final answers = session!.answers
        .where((a) => a.question.topicId == main.topicId)
        .toList();
    final missing = {for (final a in answers) ...?a.assessment?.missing}
        .take(2)
        .join('; ');

    final p = context.palette;
    final small = context.text.bodySmall!.copyWith(
      color: colors.onSurfaceVariant,
    );
    return AppPage(
      showBack: true,
      title: S.recommendTitle,
      subtitle: S.recommendSubtitle,
      body: [
        // Басты беттегі «Келесі қадам» панелімен бір тіл: қараңғы панель,
        // балл шаршыда, жасыл әрекет.
        FullBleed(
          child: ColoredBox(
            color: p.panel,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          spacing: AppSpacing.xs,
                          children: [
                            Text(
                              mainTopic.title,
                              style: context.text.headlineSmall!.copyWith(
                                color: p.onPanel,
                              ),
                            ),
                            Text(
                              mainTopic.reviewPoints.join(', '),
                              style: context.text.bodySmall!.copyWith(
                                color: p.onPanelMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: AppSpacing.smd),
                      Semantics(
                        label: S.recommendScore(Fmt.score(main.score)),
                        excludeSemantics: true,
                        child: Container(
                          width: 56,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            border: Border.all(color: p.onPanel),
                            borderRadius: BorderRadius.circular(AppRadius.cell),
                          ),
                          child: Column(
                            children: [
                              Text(
                                '${main.score.round()}',
                                textScaler: TextScaler.noScaling,
                                style: context.text.headlineSmall!.copyWith(
                                  color: p.onPanel,
                                ),
                              ),
                              Text(
                                '/ 100',
                                textScaler: TextScaler.noScaling,
                                style: context.text.bodySmall!.copyWith(
                                  color: p.onPanelMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppButton.accent(
                    label: S.practiceThisTopic,
                    onPressed: () => context.push(
                      TopicDetailScreen.practiceLocation(mainTopic),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(S.whyThisTopic, style: context.text.titleMedium),
        const SizedBox(height: AppSpacing.sm),
        CodeText(
          missing.isEmpty
              ? S.whyLowest(answers.length)
              : S.whyMissing(answers.length, missing),
          style: context.text.bodyMedium!.copyWith(
            color: colors.onSurfaceVariant,
          ),
        ),
        if (weak.length > 1) ...[
          GroupHeader(title: S.otherWeakTopics),
          ListGroup(
            children: [
              for (final w in weak.skip(1))
                ItemRow(
                  title: topics.byId(w.topicId).title,
                  onTap: () => context.push(Routes.topic(w.topicId)),
                  trailing: Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      spacing: AppSpacing.sm,
                      children: [
                        Text(Fmt.score(w.score), style: context.text.bodyLarge),
                        const Icon(AppIcons.forward, size: 18),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ],
        const SizedBox(height: AppSpacing.md),
        Text(S.recommendLimit, style: small),
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
