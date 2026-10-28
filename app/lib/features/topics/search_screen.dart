import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../app/routes.dart';
import '../../core/constants/app_strings.dart';
import '../../core/theme/app_colors.dart';
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

    return AppPage(
      showBack: true,
      title: S.searchTitle,
      subtitle: S.searchSubtitle,
      headerGap: 30,
      body: [
        AppTextField(
          label: S.searchLabel,
          controller: _query,
          hint: S.searchHint,
          autofocus: true,
          textInputAction: TextInputAction.search,
          onChanged: _onChanged,
          suffixIcon: _query.text.isEmpty
              ? Icon(Icons.search, color: colors.onSurfaceVariant)
              : IconButton(
                  tooltip: S.clearSearch,
                  onPressed: _clear,
                  icon: const Icon(Icons.close),
                ),
        ),
        const SizedBox(height: 32),
        if (_error != null) ...[
          Text(_error!, style: muted.copyWith(color: colors.error)),
          const SizedBox(height: 12),
          AppButton.tonal(label: S.retry, onPressed: _run),
        ] else if (query.isEmpty) ...[
          Text(S.popularTopics, style: context.text.titleMedium),
          const SizedBox(height: 16),
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
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.chip),
                  ),
                  side: BorderSide(color: colors.outline),
                  backgroundColor: colors.surface,
                  labelStyle: context.text.labelMedium,
                ),
            ],
          ),
          const SizedBox(height: 32),
          Text(S.searchAllDirections, style: muted),
        ] else if (results.isEmpty) ...[
          Semantics(
            liveRegion: true,
            child: Text(S.notFoundTitle, style: context.text.titleLarge),
          ),
          const SizedBox(height: 12),
          Text(S.notFoundBody, style: muted),
        ] else ...[
          Semantics(
            liveRegion: true,
            child: Text(
              S.found(results.length),
              style: context.text.bodyMedium!.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(height: 8),
          for (final topic in results)
            ListRow(
              title: topic.title,
              titleStyle: context.text.titleLarge,
              subtitle: '${topic.trackLabel}\n${topic.summary}',
              onTap: () => context.push(Routes.topic(topic.id)),
            ),
        ],
      ],
      actions: [
        if (query.isNotEmpty)
          AppButton.tonal(label: S.clearSearch, onPressed: _clear),
        if (query.isEmpty || results.isEmpty)
          AppButton(
            variant: query.isEmpty
                ? AppButtonVariant.tonal
                : AppButtonVariant.filled,
            label: S.toCatalog,
            onPressed: () => context.canPop()
                ? context.pop()
                : context.pushReplacement(Routes.topics),
          ),
      ],
    );
  }
}
