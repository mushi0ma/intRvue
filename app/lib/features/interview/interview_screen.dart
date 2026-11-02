import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../app/routes.dart';
import '../../core/constants/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_icons.dart';
import '../../core/utils/validators.dart';
import '../../core/widgets/widgets.dart';
import '../../data/local/db_errors.dart';
import '../../data/models/interview_session.dart';
import '../../data/repositories/session_repository.dart';
import '../../data/repositories/topic_repository.dart';
import 'practice_bar.dart';

/// S09 Сұхбат: сұрақ, мәтіндік жауап, нобайды сақтау, жіберу/өткізу.
class InterviewScreen extends StatefulWidget {
  const InterviewScreen({super.key});

  @override
  State<InterviewScreen> createState() => _InterviewScreenState();
}

class _InterviewScreenState extends State<InterviewScreen> {
  final _form = GlobalKey<FormState>();
  final _answer = TextEditingController();
  String? _questionId;
  bool _submitting = false;

  /// Экраннан кетіп жатырмыз: күй өзгерсе де қайта бағыттамаймыз.
  bool _leaving = false;

  @override
  void dispose() {
    _answer.dispose();
    super.dispose();
  }

  /// Сұрақ ауысқанда өрісті сақталған нобаймен толтырады.
  void _syncDraft(AnswerRecord record) {
    if (_questionId == record.question.id) return;
    _questionId = record.question.id;
    _answer.text = record.text;
  }

  Future<void> _pause() async {
    final sessions = context.read<SessionRepository>()..saveDraft(_answer.text);
    setState(() => _leaving = true);
    var message = S.pauseSaved;
    try {
      await sessions.flushDraft();
    } on AppException catch (e) {
      message = e.message;
    }
    if (!mounted) return;
    showAppSnackBar(context, message);
    context.go(Routes.home);
  }

  /// D8: үзіліс парағы — жалғастыру, Басты бетке шығу, ерте аяқтау.
  Future<void> _openPauseSheet() async {
    context.read<SessionRepository>().saveDraft(_answer.text);
    final choice = await showModalBottomSheet<_PauseChoice>(
      context: context,
      showDragHandle: true,
      builder: (context) => const _PauseSheet(),
    );
    if (!mounted) return;
    switch (choice) {
      case _PauseChoice.home:
        await _pause();
      case _PauseChoice.finish:
        await _finishEarly();
      case _PauseChoice.resume || null:
        break;
    }
  }

  Future<void> _finishEarly() async {
    final sessions = context.read<SessionRepository>()..saveDraft(_answer.text);
    final id = sessions.active!.id;
    setState(() => _leaving = true);
    try {
      await sessions.flushDraft();
      await sessions.finishActive();
    } on AppException catch (e) {
      if (!mounted) return;
      setState(() => _leaving = false);
      showAppSnackBar(context, e.message);
      return;
    }
    if (mounted) context.go(Routes.summary(id));
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_form.currentState!.validate()) return;
    setState(() => _submitting = true);
    try {
      await context.read<SessionRepository>().submitCurrent(_answer.text);
    } on AppException catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      showAppSnackBar(context, e.message);
      return;
    }
    if (!mounted) return;
    setState(() => _leaving = true);
    context.go(Routes.feedback);
  }

  Future<void> _skip() async {
    final index = context.read<SessionRepository>().active!.currentIndex;
    final confirmed = await showConfirmDialog(
      context,
      title: S.skipConfirmTitle,
      body: S.skipConfirmBody,
      confirmLabel: S.skip,
      // D7: өткізілген сұрақтың баллы алдын ала көрінеді.
      extra: Wrap(
        spacing: 6,
        runSpacing: 6,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(
            S.questionN(index + 1),
            style: context.text.bodySmall!.copyWith(
              color: context.colors.onSurfaceVariant,
            ),
          ),
          for (var i = 0; i < 3; i++)
            const ScoreCell(
              text: '—',
              band: ScoreBand.skipped,
              width: 32,
              height: 28,
            ),
          Text(S.zeroPoints, style: context.text.bodySmall),
        ],
      ),
    );
    if (!confirmed || !mounted) return;
    final sessions = context.read<SessionRepository>();
    final active = sessions.active!;
    final last = active.isLastQuestion;
    if (last) setState(() => _leaving = true);
    try {
      await sessions.skipCurrent();
    } on AppException catch (e) {
      if (!mounted) return;
      setState(() => _leaving = false);
      showAppSnackBar(context, e.message);
      return;
    }
    if (last && mounted) context.go(Routes.summary(active.id));
  }

  @override
  Widget build(BuildContext context) {
    if (_leaving) return const Scaffold();
    final session = context.watch<SessionRepository>().active;
    if (session == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.go(Routes.home);
      });
      return const Scaffold();
    }
    final record = session.current;
    if (record.status == AnswerStatus.assessed) {
      // Талдауы дайын сұраққа қайта оралса — талдау экранына.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.go(Routes.feedback);
      });
    }
    _syncDraft(record);

    final colors = context.colors;
    final topic = context.read<TopicRepository>().tryById(
      record.question.topicId,
    );
    final length = _answer.text.characters.length;

    final p = context.palette;
    final small = context.text.bodySmall!.copyWith(
      color: colors.onSurfaceVariant,
    );

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && !_submitting) _pause();
      },
      child: Form(
        key: _form,
        child: AppPage(
          leading: PracticeBar(
            icon: AppIcons.pause,
            tooltip: S.pause,
            onPressed: _submitting ? null : _openPauseSheet,
            label: '${S.practiceLabel} · ${session.trackLabel}',
            counter: '${session.currentIndex + 1} / ${session.questionCount}',
            counterSemantics: S.progressOf(
              session.currentIndex + 1,
              session.questionCount,
            ),
          ),
          body: [
            const SizedBox(height: AppSpacing.sm),
            QuestionProgress(
              total: session.questionCount,
              done: session.currentIndex + 1,
            ),
            const SizedBox(height: AppSpacing.md),
            FullBleed(
              child: Container(
                color: p.muted,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                child: Row(
                  children: [
                    const Icon(AppIcons.code, size: 18),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        topic?.title ?? '',
                        style: context.text.labelLarge,
                      ),
                    ),
                    Text(S.questionN(session.currentIndex + 1), style: small),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Semantics(
              header: true,
              child: Text(
                record.question.text,
                style: context.text.headlineSmall,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(record.question.hint, style: small),
            const SizedBox(height: AppSpacing.lg),
            AppTextField(
              label: S.yourAnswer,
              controller: _answer,
              hint: S.answerHint,
              minLines: 8,
              maxLines: 14,
              maxLength: SessionRepository.maxAnswerLength,
              keyboardType: TextInputType.multiline,
              textCapitalization: TextCapitalization.sentences,
              enabled: !_submitting,
              validator: (v) =>
                  Validators.answer(v, max: SessionRepository.maxAnswerLength),
              onChanged: (text) {
                context.read<SessionRepository>().saveDraft(text);
                setState(() {});
              },
            ),
            const SizedBox(height: AppSpacing.sm),
            // Үлкен мәтінде екі жолға бөлінеді.
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              runSpacing: 4,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (length > 0) ...[
                      Icon(AppIcons.check, size: 14, color: p.success),
                      const SizedBox(width: 4),
                      Text(
                        S.draftSaved,
                        style: small.copyWith(color: p.success),
                      ),
                    ],
                  ],
                ),
                Text(
                  '$length / ${SessionRepository.maxAnswerLength}',
                  style: small,
                ),
              ],
            ),
          ],
          actions: [
            // D6: бағалау кезінде — үш өлшемнің жүктелу жолақтары.
            if (_submitting) const _AssessingPanel(),
            AppButton.accent(
              label: S.submitAnswer,
              loading: _submitting,
              onPressed: _submit,
            ),
            AppButton.text(
              label: S.skipQuestion,
              icon: AppIcons.skip,
              onPressed: _submitting ? null : _skip,
            ),
          ],
        ),
      ),
    );
  }
}

enum _PauseChoice { resume, home, finish }

class _PauseSheet extends StatelessWidget {
  const _PauseSheet();

  @override
  Widget build(BuildContext context) {
    final secondary = context.colors.onSurfaceVariant;
    Widget row(
      IconData icon,
      String title,
      String? hint,
      _PauseChoice choice, {
      Widget? tag,
    }) => ListTile(
      leading: Icon(icon, size: 20),
      title: Text(title),
      subtitle: hint == null ? null : Text(hint),
      trailing: tag ?? const Icon(AppIcons.chevronRight, size: 20),
      onTap: () => Navigator.of(context).pop(choice),
    );
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 4,
              children: [
                Semantics(
                  header: true,
                  child: Text(S.pause, style: context.text.titleLarge),
                ),
                Text(
                  S.pauseSheetBody,
                  style: context.text.bodySmall!.copyWith(color: secondary),
                ),
              ],
            ),
          ),
          row(AppIcons.play, S.continueAction, null, _PauseChoice.resume),
          const Divider(),
          row(AppIcons.home, S.pauseHome, S.pauseHomeHint, _PauseChoice.home),
          const Divider(),
          row(
            AppIcons.flag,
            S.pauseFinish,
            S.pauseFinishHint,
            _PauseChoice.finish,
            tag: AppTag(S.statusIncomplete, kind: TagKind.warning),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
      ),
    );
  }
}

class _AssessingPanel extends StatelessWidget {
  const _AssessingPanel();

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final small = context.text.bodySmall!.copyWith(
      color: context.colors.onSurfaceVariant,
    );
    return Semantics(
      liveRegion: true,
      label: S.assessing,
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.smd),
        decoration: BoxDecoration(
          color: p.tonal,
          borderRadius: BorderRadius.circular(AppRadius.control),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: AppSpacing.sm,
          children: [
            Row(
              children: [
                const Icon(AppIcons.schedule, size: 18),
                const SizedBox(width: AppSpacing.sm),
                Text(S.assessing, style: context.text.labelLarge),
              ],
            ),
            Row(
              spacing: AppSpacing.sm,
              children: [
                for (final label in [S.correctness, S.completeness, S.clarity])
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      spacing: 4,
                      children: [
                        Text(label, style: small, maxLines: 1),
                        LinearProgressIndicator(
                          minHeight: 3,
                          color: p.ink,
                          backgroundColor: p.lineStrong.withValues(alpha: 0.4),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
