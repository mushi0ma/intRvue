import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../app/routes.dart';
import '../../core/constants/app_strings.dart';
import '../../core/theme/app_colors.dart';
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

    final questionCount = repo.questionsFor(topic.id).length;

    return AppPage(
      showBack: true,
      trailing: topic.isCustom
          ? TextButton(
              onPressed: () => context.push(Routes.topicEdit(topic.id)),
              child: Text(S.edit),
            )
          : null,
      title: topic.title,
      subtitle: [
        topic.trackLabel,
        S.questionsCount(questionCount),
        if (topic.isCustom) S.myTopic,
      ].join(' · '),
      headerGap: 32,
      body: [
        Text(
          topic.description,
          style: context.text.bodyLarge!.copyWith(
            color: colors.onSurfaceVariant,
          ),
        ),
        const SectionDivider(vertical: 28),
        Text(S.whatWeReview, style: context.text.titleLarge),
        const SizedBox(height: 16),
        for (final point in topic.reviewPoints)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Text(point, style: context.text.bodyLarge),
          ),
        const SizedBox(height: 32),
        Text(
          S.sampleQuestion,
          style: context.text.titleMedium!.copyWith(color: colors.primary),
        ),
        const SizedBox(height: 16),
        Text(topic.sampleQuestion, style: context.text.titleLarge),
      ],
      actions: [
        AppButton.tonal(
          label: favorite ? S.removeFavorite : S.addFavorite,
          icon: favorite
              ? Icons.bookmark_remove_outlined
              : Icons.bookmark_add_outlined,
          onPressed: () async {
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
          },
        ),
        AppButton(
          label: S.practiceWithTopic,
          onPressed: () => context.push(practiceLocation(topic)),
        ),
      ],
    );
  }
}
