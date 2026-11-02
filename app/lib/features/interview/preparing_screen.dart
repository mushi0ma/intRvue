import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../app/routes.dart';
import '../../core/constants/app_strings.dart';
import '../../core/theme/app_icons.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/navigation.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/widgets.dart';
import '../../data/local/db_errors.dart';
import '../../data/repositories/session_repository.dart';
import '../../data/repositories/topic_repository.dart';

/// «Сұрақтарды дайындап жатырмыз»: сессия құрылғанша күту.
class PreparingScreen extends StatefulWidget {
  const PreparingScreen({super.key});

  @override
  State<PreparingScreen> createState() => _PreparingScreenState();
}

class _PreparingScreenState extends State<PreparingScreen> {
  late final _request = context.read<SessionRepository>().pending;
  bool _cancelled = false;

  /// Сұрақтар құрылмады: себебі және қайталау мүмкіндігі.
  String? _error;

  @override
  void initState() {
    super.initState();
    // Навигация build аяқталғаннан кейін ғана.
    WidgetsBinding.instance.addPostFrameCallback((_) => _prepare());
  }

  Future<void> _prepare() async {
    final sessions = context.read<SessionRepository>();
    if (sessions.pending == null) {
      // Мысалы, бет қайта ашылды: бастайтын параметр жоқ.
      context.go(Routes.home);
      return;
    }
    String? error;
    try {
      final session = await sessions.startPending();
      if (session == null) error = S.prepareNoQuestions;
    } on AppException catch (e) {
      error = e.message;
    }
    if (!mounted || _cancelled) return;
    if (error == null) {
      context.go(Routes.interview);
    } else {
      setState(() => _error = error);
    }
  }

  void _retry() {
    setState(() => _error = null);
    _prepare();
  }

  void _cancel() {
    _cancelled = true;
    context.read<SessionRepository>().pending = null;
    context.go(Routes.home);
  }

  @override
  Widget build(BuildContext context) {
    final request = _request;
    final topics = context.read<TopicRepository>();
    Widget closeButton(VoidCallback onPressed) => Row(
      children: [
        IconButton.outlined(
          tooltip: S.cancel,
          onPressed: onPressed,
          style: IconButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.control),
            ),
            side: BorderSide(color: context.palette.ink),
          ),
          icon: const Icon(AppIcons.close, size: 20),
        ),
      ],
    );
    final muted = context.text.bodySmall!.copyWith(
      color: context.colors.onSurfaceVariant,
    );

    final error = _error;
    if (error != null) {
      return AppPage(
        leading: closeButton(() => context.popOr(Routes.practiceTopics)),
        title: S.prepareErrorTitle,
        subtitle: S.prepareErrorSubtitle,
        body: [
          Semantics(liveRegion: true, child: ReviewNote(error)),
          if (request != null) ...[
            const SizedBox(height: 24),
            Text(
              '${request.direction.label} · ${request.level.label} · '
              '${S.questionsCount(request.questionCount)}\n'
              '${request.topicIds.map((id) => topics.tryById(id)?.title ?? id).join(', ')}',
              style: muted,
            ),
          ],
        ],
        actions: [
          AppButton(label: S.retry, onPressed: _retry),
          AppButton.tonal(
            label: S.backToParams,
            onPressed: () => context.popOr(Routes.practiceTopics),
          ),
        ],
      );
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _cancel();
      },
      // D3: «×», мазмұн экранның төменгі жартысында, жіңішке жолақ.
      child: AppPage(
        leading: closeButton(_cancel),
        body: [
          SizedBox(height: MediaQuery.sizeOf(context).height * 0.18),
          Semantics(
            label: S.preparingTitle,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.pill),
              child: LinearProgressIndicator(
                minHeight: 4,
                color: context.palette.ink,
                backgroundColor: context.palette.lineStrong.withValues(
                  alpha: 0.45,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Semantics(
            header: true,
            child: Text(S.preparingTitle, style: context.text.headlineLarge),
          ),
          const SizedBox(height: AppSpacing.smd),
          if (request != null)
            Text(
              '${request.direction.label} · ${request.level.label} · '
              '${S.questionsCount(request.questionCount)}\n'
              '${request.topicIds.map((id) => topics.tryById(id)?.title ?? id).join(', ')}',
              style: muted,
            ),
          const SizedBox(height: AppSpacing.md),
          Text(S.preparingBody, style: muted),
          const SizedBox(height: AppSpacing.lg),
          Text(S.preparingMotto, style: context.text.titleMedium),
          const SizedBox(height: AppSpacing.xs),
          Text(
            S.preparingHint,
            style: context.text.bodyMedium!.copyWith(
              color: context.colors.onSurfaceVariant,
            ),
          ),
        ],
        actions: [AppButton.tonal(label: S.cancel, onPressed: _cancel)],
      ),
    );
  }
}
