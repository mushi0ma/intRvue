import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../app/routes.dart';
import '../../core/constants/app_strings.dart';
import '../../data/repositories/session_repository.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/formatters.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_icons.dart';
import '../../core/widgets/widgets.dart';
import '../../data/local/db_errors.dart';
import '../../data/models/topic.dart';
import '../../data/repositories/topic_repository.dart';

/// S17 Тақырып туралы (Detail): мазмұны, үлгі сұрақ, таңдаулыға қосу.
class TopicDetailScreen extends StatelessWidget {
  const TopicDetailScreen({super.key, required this.topicId});

  final String topicId;

  static String practiceLocation(Topic topic) => Uri(
    path: Routes.practiceSetup,
    queryParameters: {'direction': topic.direction.name, 'topics': topic.id},
  ).toString();

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<TopicRepository>();
    final topic = repo.tryById(topicId);
    if (topic == null) {
      return AppPage(
        showBack: true,
        title: S.notFoundTitle,
        body: [Text(S.notFoundBody)],
      );
    }
    final favorite = repo.isFavorite(topic.id);
    final colors = context.colors;
    final p = context.palette;
    final secondary = colors.onSurfaceVariant;
    final questions = repo.questionsFor(topic.id);
    final last = _lastScore(context.watch<SessionRepository>(), topic.id);

    Future<void> toggleFavorite() async {
      try {
        await repo.toggleFavorite(topic.id);
      } on AppException catch (e) {
        if (context.mounted) showAppSnackBar(context, e.message);
        return;
      }
      if (!context.mounted) return;
      if (favorite) {
        showAppSnackBar(context, S.removedFromFavorites);
      } else {
        showAppSnackBar(
          context,
          S.addedToFavorites,
          actionLabel: S.open,
          onAction: () => context.push(Routes.favorites),
        );
      }
    }

    final outlined = IconButton.styleFrom(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.control),
      ),
      side: BorderSide(color: p.ink),
    );

    return AppPage(
      showBack: true,
      // C6/C7: бетбелгі мен өңдеу — жоғарғы оң жақтағы шаршы батырмалар.
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: AppSpacing.sm,
        children: [
          if (topic.isCustom)
            IconButton.outlined(
              tooltip: S.edit,
              style: outlined,
              onPressed: () => context.push(Routes.topicEdit(topic.id)),
              icon: const Icon(AppIcons.edit, size: 20),
            ),
          IconButton.outlined(
            tooltip: favorite ? S.removeFavorite : S.addFavorite,
            style: outlined,
            onPressed: toggleFavorite,
            // Белгіленгенде толтырылған бетбелгі; батырма фоны өзгермейді.
            icon: Icon(AppIcons.bookmark, size: 20, fill: favorite ? 1 : 0),
          ),
          const SizedBox(width: AppSpacing.sm),
        ],
      ),
      header: Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
        child: Text(
          '${topic.trackLabel} · ${S.questionsCount(questions.length)}',
          style: context.text.bodySmall!.copyWith(color: secondary),
        ),
      ),
      title: topic.title,
      subtitle: topic.description,
      body: [
        if (topic.isCustom) ...[
          Row(children: [AppTag(S.myTopic, kind: TagKind.ink)]),
          const SizedBox(height: AppSpacing.md),
        ],
        if (last != null)
          FullBleed(
            child: Container(
              color: p.muted,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${S.lastScoreOn} · ${Fmt.day(last.$1)}',
                          style: context.text.bodySmall!.copyWith(
                            color: secondary,
                          ),
                        ),
                        Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: '${last.$2.round()}',
                                style: context.text.headlineMedium,
                              ),
                              TextSpan(
                                text: ' / 100',
                                style: context.text.bodySmall!.copyWith(
                                  color: secondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (last.$2 < 60)
                    AppTag(S.weakTopicTag, kind: TagKind.warning),
                ],
              ),
            ),
          ),
        const SizedBox(height: AppSpacing.lg),
        Text(S.whatWeReview, style: context.text.titleMedium),
        const SizedBox(height: AppSpacing.sm),
        for (final point in topic.reviewPoints)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  margin: const EdgeInsets.only(top: 8, right: 12),
                  color: p.ink,
                ),
                Expanded(child: Text(point, style: context.text.bodyMedium)),
              ],
            ),
          ),
        const SizedBox(height: AppSpacing.lg),
        if (topic.isCustom) ...[
          GroupHeader(title: S.questionsSection, meta: '${questions.length}'),
          for (final q in questions)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: ListGroup(
                children: [
                  ItemRow(
                    title: q.text,
                    meta: q.modelAnswer.isEmpty ? null : S.hasModelAnswer,
                  ),
                ],
              ),
            ),
        ] else ...[
          Text(S.sampleQuestion, style: context.text.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          FullBleed(
            child: Container(
              color: p.muted,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Text(topic.sampleQuestion, style: context.text.bodyLarge),
            ),
          ),
        ],
      ],
      actions: [
        AppButton.accent(
          label: S.practiceWithTopic,
          onPressed: () => context.push(practiceLocation(topic)),
        ),
      ],
    );
  }

  /// Тақырып кездескен ең соңғы толық сессия: (күні, тақырып баллы).
  static (DateTime, double)? _lastScore(SessionRepository sessions, String id) {
    for (final s in sessions.history) {
      final score = s.topicScores[id];
      if (score != null) return (s.startedAt, score);
    }
    return null;
  }
}
