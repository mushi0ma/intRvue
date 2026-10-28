import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../app/routes.dart';
import '../../core/constants/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/widgets.dart';
import '../../data/local/db_errors.dart';
import '../../data/repositories/topic_repository.dart';

/// S19 Таңдаулы: тізім, «Алу» және «Қайтару», бос күй (S23).
class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<TopicRepository>();
    final favorites = repo.favorites;
    final colors = context.colors;

    return AppPage(
      showBack: true,
      title: S.favoritesTitle,
      subtitle: S.favoritesSubtitle,
      headerGap: 40,
      body: [
        if (favorites.isEmpty)
          EmptyState(title: S.favoritesEmptyTitle, body: S.favoritesEmptyBody)
        else ...[
          for (final topic in favorites)
            ListRow(
              title: topic.title,
              titleStyle: context.text.titleLarge,
              subtitle: topic.trackLabel,
              onTap: () => context.push(Routes.topic(topic.id)),
              trailing: TextButton(
                onPressed: () async {
                  try {
                    final addedAt = await repo.removeFavorite(topic.id);
                    if (!context.mounted) return;
                    showAppSnackBar(
                      context,
                      S.topicRemoved,
                      actionLabel: S.undo,
                      // Бұрынғы уақытымен қайтарамыз — тізімдегі орны сақталады.
                      onAction: () => repo.addFavorite(topic.id, at: addedAt),
                    );
                  } on AppException catch (e) {
                    if (context.mounted) showAppSnackBar(context, e.message);
                  }
                },
                child: Text(
                  S.remove,
                  semanticsLabel: '${S.remove}: ${topic.title}',
                ),
              ),
            ),
          const SizedBox(height: 40),
          Text(
            S.favoritesNote,
            style: context.text.bodyLarge!.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
        ],
      ],
      actions: [
        if (favorites.isEmpty)
          AppButton(
            label: S.toCatalog,
            onPressed: () => context.push(Routes.topics),
          )
        else ...[
          AppButton.tonal(
            label: S.homeCatalog,
            onPressed: () => context.push(Routes.topics),
          ),
          AppButton(
            label: S.toProfile,
            onPressed: () => context.push(Routes.profile),
          ),
        ],
      ],
    );
  }
}
