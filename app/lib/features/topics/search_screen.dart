import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../app/routes.dart';
import '../../core/constants/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_icons.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/widgets.dart';
import '../../data/local/db_errors.dart';
import '../../data/models/enums.dart';
import '../../data/models/topic.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/topic_repository.dart';

/// S18 Іздеу: бос сұрау, нәтижелер және «Тақырып табылмады» күйі.
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _query = TextEditingController();
  Timer? _debounce;

  /// Соңғы орындалған сұрау және оның нәтижесі (SQLite LIKE).
  String _searched = '';
  List<Topic> _results = const [];
  String? _error;

  @override
  void dispose() {
    _debounce?.cancel();
    _query.dispose();
    super.dispose();
  }

  void _onChanged(String text) {
    setState(() {});
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), _run);
  }

  Future<void> _run() async {
    final text = _query.text.trim();
    try {
      final results = await context.read<TopicRepository>().search(text);
      if (!mounted || text != _query.text.trim()) return;
      setState(() {
        _searched = text;
        _results = results;
        _error = null;
      });
    } on AppException catch (e) {
      if (mounted) setState(() => _error = e.message);
    }
  }

  void _clear() {
    _debounce?.cancel();
    setState(() {
      _query.clear();
      _searched = '';
      _results = const [];
    });
  }

  @override
  Widget build(BuildContext context) {
    final repo = context.read<TopicRepository>();
    final query = _searched;
    final results = _results;
    final colors = context.colors;
    final muted = context.text.bodyLarge!.copyWith(
      color: colors.onSurfaceVariant,
    );

    // C4/C5: «←» және іздеу өрісі бір жолда, нәтижелер карточкада.
    return AppPage(
      bottomNavigation: true,
      leading: Row(
        children: [
          const AppBackLink(),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: TextFormField(
              controller: _query,
              autofocus: true,
              textInputAction: TextInputAction.search,
              onChanged: _onChanged,
              decoration: InputDecoration(
                hintText: S.searchHint,
                isDense: true,
                prefixIcon: Icon(
                  AppIcons.search,
                  color: colors.onSurfaceVariant,
                ),
                suffixIcon: _query.text.isEmpty
                    ? null
                    : IconButton(
                        tooltip: S.clearSearch,
                        onPressed: _clear,
                        icon: const Icon(AppIcons.close),
                      ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
        ],
      ),
      body: [
        const SizedBox(height: AppSpacing.smd),
        if (_error != null) ...[
          ReviewNote(_error!),
          const SizedBox(height: 12),
          AppButton.tonal(label: S.retry, onPressed: _run),
        ] else if (query.isEmpty) ...[
          Text(S.popularTopics, style: context.text.titleMedium),
          const SizedBox(height: AppSpacing.smd),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              // Пайдаланушының бағыты бойынша ұсыныс.
              for (final topic
                  in repo
                      .byDirection(
                        context.read<AuthRepository>().user?.direction ??
                            Direction.mobile,
                      )
                      .take(4))
                ActionChip(
                  label: Text(topic.title),
                  onPressed: () => context.push(Routes.topic(topic.id)),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(S.searchAllDirections, style: muted),
        ] else if (results.isEmpty) ...[
          const SizedBox(height: AppSpacing.xl),
          Center(
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                border: Border.all(color: context.palette.ink),
                borderRadius: BorderRadius.circular(AppRadius.control),
              ),
              child: const Icon(AppIcons.searchOff),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Semantics(
            liveRegion: true,
            child: Text(
              S.notFoundTitle,
              style: context.text.titleLarge,
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(S.notFoundBody, style: muted, textAlign: TextAlign.center),
          const SizedBox(height: AppSpacing.lg),
          AppButton(
            label: S.addTopic,
            icon: AppIcons.add,
            onPressed: () => context.push(Routes.topicNew),
          ),
          const SizedBox(height: AppSpacing.sm),
          AppButton.tonal(label: S.clearSearch, onPressed: _clear),
        ] else ...[
          Semantics(
            liveRegion: true,
            child: Text(
              S.found(results.length),
              style: context.text.bodySmall!.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          ListGroup(
            children: [
              for (final topic in results)
                ItemRow(
                  overline: [
                    topic.trackLabel,
                    if (topic.isCustom) S.myTopic,
                  ].join(' · '),
                  title: topic.title,
                  meta: topic.summary,
                  onTap: () => context.push(Routes.topic(topic.id)),
                  trailing: _Bookmark(topic: topic),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

class _Bookmark extends StatelessWidget {
  const _Bookmark({required this.topic});

  final Topic topic;

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<TopicRepository>();
    final on = repo.isFavorite(topic.id);
    return IconButton(
      tooltip: on ? S.removeFavorite : S.addFavorite,
      isSelected: on,
      onPressed: () async {
        try {
          await repo.toggleFavorite(topic.id);
        } on AppException catch (e) {
          if (context.mounted) showAppSnackBar(context, e.message);
        }
      },
      icon: const Icon(AppIcons.bookmark),
      selectedIcon: const Icon(AppIcons.bookmark, fill: 1),
    );
  }
}
