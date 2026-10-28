import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../app/routes.dart';
import '../../core/constants/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/validators.dart';
import '../../core/widgets/widgets.dart';
import '../../data/local/db_errors.dart';
import '../../data/models/interview_session.dart';
import '../../data/repositories/session_repository.dart';
import '../../data/repositories/topic_repository.dart';

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
    final confirmed = await showConfirmDialog(
      context,
      title: S.skipConfirmTitle,
      body: S.skipConfirmBody,
      confirmLabel: S.skip,
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

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && !_submitting) _pause();
      },
      child: Form(
        key: _form,
        child: AppPage(
          leading: AppBackLink(label: S.pause, onPressed: _pause),
          trailing: Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Text(
              S.progressOf(session.currentIndex + 1, session.questionCount),
              style: context.text.bodyLarge!.copyWith(
                fontWeight: FontWeight.w500,
                color: colors.onSurfaceVariant,
              ),
            ),
          ),
          body: [
            const SizedBox(height: 14),
            QuestionProgress(
              total: session.questionCount,
              done: session.currentIndex + 1,
            ),
            const SizedBox(height: 34),
            if (topic != null)
              Text(
                topic.title,
                style: context.text.labelMedium!.copyWith(
                  color: colors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            const SizedBox(height: 22),
            Semantics(
              header: true,
              child: Text(
                record.question.text,
                style: context.text.headlineSmall,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              record.question.hint,
              style: context.text.bodyMedium!.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 40),
            AppTextField(
              label: S.yourAnswer,
              controller: _answer,
              hint: S.answerHint,
              minLines: 10,
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
            const SizedBox(height: 12),
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              runSpacing: 4,
              children: [
                Text(
                  length > 0 ? S.draftSaved : '',
                  style: context.text.bodyMedium!.copyWith(
                    color: colors.primary,
                  ),
                ),
                Text(
                  '$length / ${SessionRepository.maxAnswerLength}',
                  style: context.text.bodyMedium!.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            if (_submitting) ...[
              const SizedBox(height: 16),
              Semantics(
                liveRegion: true,
                child: Text(
                  S.assessing,
                  style: context.text.bodyMedium!.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ],
          actions: [
            AppButton(
              label: S.submitAnswer,
              loading: _submitting,
              onPressed: _submit,
            ),
            AppButton.tonal(
              label: S.skipQuestion,
              onPressed: _submitting ? null : _skip,
            ),
          ],
        ),
      ),
    );
  }
}
