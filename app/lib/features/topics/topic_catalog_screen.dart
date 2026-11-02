import 'dart:async';

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
import '../../data/local/db_errors.dart';
import '../../data/models/enums.dart';
import '../../data/models/topic.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/topic_repository.dart';

/// S16 Тақырыптар каталогы (List): іздеу, сүзгі, сұрыптау, таңдаулы.
/// Әр өзгерісте SQLite-қа бір сұрау жіберіледі.
class TopicCatalogScreen extends StatefulWidget {
  const TopicCatalogScreen({super.key});

  @override
  State<TopicCatalogScreen> createState() => _TopicCatalogScreenState();
}

class _TopicCatalogScreenState extends State<TopicCatalogScreen> {
  late final TopicRepository _repo = context.read<TopicRepository>();
  final _search = TextEditingController();
  Timer? _debounce;

  late TopicQuery _query = TopicQuery(
    direction: context.read<AuthRepository>().user?.direction,
  );
  List<TopicListItem>? _items;
  String? _error;

  @override
  void initState() {
    super.initState();
    _repo.addListener(_load);
    _load();
  }

  @override
  void dispose() {
    _repo.removeListener(_load);
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final query = _query;
    try {
      final items = await _repo.query(query);
      if (!mounted || query != _query) return;
      setState(() {
        _items = items;
        _error = null;
      });
    } on AppException catch (e) {
      if (mounted) setState(() => _error = e.message);
    }
  }

  void _update(TopicQuery query) {
    setState(() => _query = query);
    _load();
  }

  void _onSearch(String text) {
    _debounce?.cancel();
    _debounce = Timer(
      const Duration(milliseconds: 250),
      () => _update(_query.copyWith(search: text)),
    );
  }

  void _reset() {
    _search.clear();
    _update(TopicQuery(sort: _query.sort));
  }

  Future<void> _toggleFavorite(Topic topic) async {
    try {
      await _repo.toggleFavorite(topic.id);
    } on AppException catch (e) {
      if (mounted) showAppSnackBar(context, e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final items = _items;

    return AppPage(
      bottomNavigation: true,
      body: [
        const SizedBox(height: AppSpacing.md),
        // C1: атау және санауыш бір жолда.
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Expanded(
              child: Semantics(
                header: true,
                child: Text(S.catalogTitle, style: context.text.headlineLarge),
              ),
            ),
            if (items != null)
              Text(
                S.topicCount(items.length),
                style: context.text.bodySmall!.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        TextField(
          controller: _search,
          onChanged: _onSearch,
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            hintText: S.searchTopics,
            prefixIcon: Icon(AppIcons.search, color: colors.onSurfaceVariant),
            suffixIcon: _query.search.isEmpty
                ? null
                : IconButton(
                    tooltip: S.clearSearch,
                    icon: const Icon(AppIcons.close),
                    onPressed: () {
                      _search.clear();
                      _update(_query.copyWith(search: ''));
                    },
                  ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        // Сүзгі чиптері көлденең айналады — шет 16 сақталады.
        FullBleed(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.inset),
            child: Row(
              spacing: AppSpacing.sm,
              children: [
                FilterDropdown<Direction?>(
                  expand: false,
                  highlighted: _query.direction != null,
                  value: _query.direction,
                  values: const [null, ...Direction.values],
                  labelOf: (d) => d?.label ?? S.allDirections,
                  semanticLabel: S.fieldDirection,
                  onChanged: (d) =>
                      _update(_query.copyWith(direction: () => d)),
                ),
                FilterDropdown<Level?>(
                  expand: false,
                  highlighted: _query.level != null,
                  value: _query.level,
                  values: const [null, ...Level.values],
                  labelOf: (l) => l?.label ?? S.allLevels,
                  semanticLabel: S.fieldLevel,
                  onChanged: (l) => _update(_query.copyWith(level: () => l)),
                ),
                FilterChip(
                  avatar: const Icon(AppIcons.bookmark, size: 18),
                  label: Text(S.filterFavorites),
                  selected: _query.onlyFavorites,
                  showCheckmark: false,
                  onSelected: (v) => _update(_query.copyWith(onlyFavorites: v)),
                ),
                FilterChip(
                  label: Text(S.filterMine),
                  selected: _query.onlyMine,
                  onSelected: (v) => _update(_query.copyWith(onlyMine: v)),
                ),
              ],
            ),
          ),
        ),
        _SortButton(
          value: _query.sort,
          onChanged: (s) => _update(_query.copyWith(sort: s)),
        ),
        if (_error != null) ...[
          const SizedBox(height: 24),
          ReviewNote(_error!),
          const SizedBox(height: 12),
          AppButton.tonal(label: S.retry, onPressed: _load),
        ] else if (items == null)
          const Padding(
            padding: EdgeInsets.all(32),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (items.isEmpty) ...[
          EmptyState(
            title: S.catalogEmptyTitle,
            body: _query.onlyMine && _query.search.isEmpty
                ? S.catalogMineEmptyBody
                : S.catalogEmptyBody,
          ),
          if (_query.activeFilters > 0 || _query.search.isNotEmpty) ...[
            const SizedBox(height: 16),
            AppButton.tonal(label: S.resetFilters, onPressed: _reset),
          ],
        ] else
          ListGroup(
            children: [
              for (final item in items)
                TopicItemRow(
                  item: item,
                  onTap: () => context.push(Routes.topic(item.topic.id)),
                  onFavorite: () => _toggleFavorite(item.topic),
                ),
            ],
          ),
      ],
      actions: [
        // C1: бір әрекет; жаттығу Басты беттен және тақырып бетінен басталады.
        AppButton.tonal(
          label: S.addTopic,
          icon: AppIcons.add,
          onPressed: () => context.push(Routes.topicNew),
        ),
      ],
    );
  }
}

/// Тақырып жолы: «Mobile · Бастапқы · Менің тақырыбым», атау,
/// «3 сұрақ · орт. 73,3», бетбелгі. Каталог, іздеу, таңдаулыда ортақ.
class TopicItemRow extends StatelessWidget {
  const TopicItemRow({
    super.key,
    required this.item,
    required this.onTap,
    required this.onFavorite,
  });

  final TopicListItem item;
  final VoidCallback onTap;
  final VoidCallback onFavorite;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final topic = item.topic;
    return ItemRow(
      overline: [topic.trackLabel, if (topic.isCustom) S.myTopic].join(' · '),
      title: topic.title,
      meta: [
        S.questionsCount(item.questionCount),
        if (item.averageScore != null)
          S.averageShort(Fmt.score(item.averageScore!)),
      ].join(' · '),
      onTap: onTap,
      trailing: IconButton(
        tooltip: item.isFavorite ? S.removeFavorite : S.addFavorite,
        isSelected: item.isFavorite,
        onPressed: onFavorite,
        icon: Icon(AppIcons.bookmark, color: colors.onSurface),
        selectedIcon: Icon(AppIcons.bookmark, fill: 1, color: colors.onSurface),
      ),
    );
  }
}

class _SortButton extends StatelessWidget {
  const _SortButton({required this.value, required this.onChanged});

  final TopicSort value;
  final ValueChanged<TopicSort> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return PopupMenuButton<TopicSort>(
      tooltip: S.sortLabel,
      initialValue: value,
      onSelected: onChanged,
      position: PopupMenuPosition.under,
      itemBuilder: (context) => [
        for (final s in TopicSort.values)
          PopupMenuItem(value: s, child: Text(s.label)),
      ],
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: AppSpacing.touchTarget),
        child: Row(
          children: [
            Expanded(
              child: Text(
                '${S.sortLabel}: ${value.label}',
                style: context.text.bodySmall!.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
            ),
            Icon(AppIcons.sort, size: 20, color: colors.onSurface),
          ],
        ),
      ),
    );
  }
}
