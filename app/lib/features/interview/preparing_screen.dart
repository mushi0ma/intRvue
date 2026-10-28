import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../app/routes.dart';
import '../../core/constants/app_strings.dart';
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
    final muted = context.text.bodyLarge!.copyWith(
      color: context.colors.onSurfaceVariant,
    );

    final error = _error;
    if (error != null) {
      return AppPage(
        showBack: true,
        title: S.prepareErrorTitle,
        subtitle: S.prepareErrorSubtitle,
        body: [
          Semantics(
            liveRegion: true,
            child: Text(error, style: context.text.bodyLarge),
          ),
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
      child: AppPage(
        showBack: true,
        onBack: _cancel,
        title: S.preparingTitle,
        headerGap: 40,
        body: [
          if (request != null)
            Text(
              '${request.direction.label} · ${request.level.label}\n'
              '${request.topicIds.map((id) => topics.tryById(id)?.title ?? id).join(', ')}\n'
              '${request.language.label} · ${S.questionsCount(request.questionCount)}',
              style: muted,
            ),
          const SizedBox(height: 40),
          Semantics(
            label: S.preparingTitle.replaceAll('\n', ' '),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: const LinearProgressIndicator(minHeight: 4),
            ),
          ),
          const SizedBox(height: 40),
          Text(S.preparingBody, style: muted),
          const SectionDivider(vertical: 32),
          Text(S.preparingMotto, style: context.text.titleLarge),
          const SizedBox(height: 12),
          Text(
            S.preparingHint,
            style: context.text.bodyMedium!.copyWith(
              color: context.colors.onSurfaceVariant,
            ),
          ),
        ],
        actions: [AppButton.tonal(label: S.backToHome, onPressed: _cancel)],
      ),
    );
  }
}
