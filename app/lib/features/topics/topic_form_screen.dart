import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../app/routes.dart';
import '../../core/constants/app_strings.dart';
import '../../core/utils/navigation.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/validators.dart';
import '../../core/widgets/widgets.dart';
import '../../data/local/db_errors.dart';
import '../../data/models/enums.dart';
import '../../data/models/topic.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/topic_repository.dart';

/// Пайдаланушы тақырыбын қосу (Create) және өзгерту (Update/Delete).
class TopicFormScreen extends StatefulWidget {
  const TopicFormScreen({super.key, this.topicId});

  /// null — жаңа тақырып.
  final String? topicId;

  @override
  State<TopicFormScreen> createState() => _TopicFormScreenState();
}

class _QuestionFields {
  _QuestionFields({this.id, String text = '', String answer = ''})
    : text = TextEditingController(text: text),
      answer = TextEditingController(text: answer);

  final String? id;
  final TextEditingController text;
  final TextEditingController answer;

  /// Тізімнен алып тастағанда өрістер дұрыс қайта құрылуы үшін.
  final key = UniqueKey();

  void dispose() {
    text.dispose();
    answer.dispose();
  }
}

class _TopicFormScreenState extends State<TopicFormScreen> {
  final _form = GlobalKey<FormState>();
  late final TopicRepository _repo = context.read<TopicRepository>();
  late final Topic? _existing = widget.topicId == null
      ? null
      : _repo.tryById(widget.topicId!);

  late final _title = TextEditingController(text: _existing?.title);
  late final _summary = TextEditingController(text: _existing?.summary);
  late final _description = TextEditingController(
    text: _existing?.description == _existing?.summary
        ? ''
        : _existing?.description,
  );
  late final _points = TextEditingController(
    text: _existing?.reviewPoints.join('\n'),
  );
  late Direction _direction =
      _existing?.direction ??
      context.read<AuthRepository>().user?.direction ??
      Direction.mobile;
  late Level _level =
      _existing?.level ??
      context.read<AuthRepository>().user?.level ??
      Level.beginner;
  late final List<_QuestionFields> _questions = _existing == null
      ? [_QuestionFields()]
      : [
          for (final q in _repo.questionsFor(_existing.id))
            _QuestionFields(id: q.id, text: q.text, answer: q.modelAnswer),
        ];

  var _autovalidate = AutovalidateMode.disabled;
  bool _saving = false;
  bool _dirty = false;

  bool get _isEdit => _existing != null;

  @override
  void dispose() {
    for (final c in [_title, _summary, _description, _points]) {
      c.dispose();
    }
    for (final q in _questions) {
      q.dispose();
    }
    super.dispose();
  }

  void _markDirty() {
    if (!_dirty) setState(() => _dirty = true);
  }

  TopicDraft _draft() => TopicDraft(
    title: _title.text,
    summary: _summary.text,
    description: _description.text,
    direction: _direction,
    level: _level,
    reviewPoints: _points.text
        .split('\n')
        .map((p) => p.trim())
        .where((p) => p.isNotEmpty)
        .toList(),
    questions: [
      for (final q in _questions)
        QuestionDraft(id: q.id, text: q.text.text, modelAnswer: q.answer.text),
    ],
  );

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    setState(() => _autovalidate = AutovalidateMode.onUserInteraction);
    if (!_form.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final topic = _isEdit
          ? await _repo.update(_existing!.id, _draft())
          : await _repo.create(_draft());
      if (!mounted) return;
      _dirty = false;
      showAppSnackBar(context, _isEdit ? S.topicUpdated : S.topicCreated);
      if (_isEdit) {
        context.popOr(Routes.topics);
      } else {
        context.pushReplacement(Routes.topic(topic.id));
      }
    } on AppException catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        showAppSnackBar(context, e.message);
      }
    }
  }

  Future<void> _delete() async {
    final ok = await showConfirmDialog(
      context,
      title: S.deleteTopicTitle,
      body: S.deleteTopicBody,
      confirmLabel: S.delete,
      destructive: true,
    );
    if (!ok || !mounted) return;
    try {
      await _repo.delete(_existing!.id);
      if (!mounted) return;
      _dirty = false;
      showAppSnackBar(context, S.topicDeleted);
      context.go(Routes.topics);
    } on AppException catch (e) {
      if (mounted) showAppSnackBar(context, e.message);
    }
  }

  Future<void> _leave() async {
    if (!_dirty) {
      context.popOr(Routes.topics);
      return;
    }
    final discard = await showConfirmDialog(
      context,
      title: S.discardTitle,
      body: S.discardBody,
      confirmLabel: S.discardAction,
    );
    if (discard && mounted) context.popOr(Routes.topics);
  }

  void _addQuestion() {
    setState(() {
      _questions.add(_QuestionFields());
      _dirty = true;
    });
  }

  void _removeQuestion(_QuestionFields q) {
    if (_questions.length == 1) {
      showAppSnackBar(context, S.atLeastOneQuestion);
      return;
    }
    setState(() {
      _questions.remove(q);
      _dirty = true;
    });
    q.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return PopScope(
      canPop: !_dirty || _saving,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _leave();
      },
      child: Form(
        key: _form,
        autovalidateMode: _autovalidate,
        onChanged: _markDirty,
        child: AppPage(
          showBack: true,
          onBack: _leave,
          title: _isEdit ? S.topicFormEdit : S.topicFormCreate,
          subtitle: S.topicFormSubtitle,
          body: [
            AppTextField(
              label: S.fieldTopicTitle,
              controller: _title,
              maxLength: 60,
              textCapitalization: TextCapitalization.sentences,
              textInputAction: TextInputAction.next,
              validator: Validators.topicTitle,
            ),
            const SizedBox(height: 24),
            AppTextField(
              label: S.fieldSummary,
              controller: _summary,
              maxLength: 80,
              textCapitalization: TextCapitalization.sentences,
              textInputAction: TextInputAction.next,
              validator: Validators.summary,
            ),
            const SizedBox(height: 24),
            AppDropdownField<Direction>(
              label: S.fieldDirection,
              value: _direction,
              items: Direction.values,
              itemLabel: (d) => d.label,
              onChanged: (d) => setState(() {
                _direction = d;
                _dirty = true;
              }),
            ),
            const SizedBox(height: 24),
            AppDropdownField<Level>(
              label: S.fieldLevel,
              value: _level,
              items: Level.values,
              itemLabel: (l) => l.label,
              onChanged: (l) => setState(() {
                _level = l;
                _dirty = true;
              }),
            ),
            const SizedBox(height: 24),
            AppTextField(
              label: S.fieldDescription,
              controller: _description,
              minLines: 2,
              maxLines: 5,
              maxLength: 400,
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 24),
            AppTextField(
              label: S.fieldReviewPoints,
              controller: _points,
              helper: S.reviewPointsHelper,
              minLines: 3,
              maxLines: 6,
              maxLength: 400,
              keyboardType: TextInputType.multiline,
            ),
            const SectionDivider(vertical: 28),
            Text(S.questionsSection, style: context.text.titleLarge),
            const SizedBox(height: 8),
            for (var i = 0; i < _questions.length; i++)
              _QuestionCard(
                key: _questions[i].key,
                index: i,
                fields: _questions[i],
                onRemove: () => _removeQuestion(_questions[i]),
              ),
            AppButton.text(
              label: S.addQuestion,
              icon: Icons.add,
              onPressed: _addQuestion,
            ),
            if (_isEdit) ...[
              const SectionDivider(vertical: 20),
              TextButton.icon(
                onPressed: _saving ? null : _delete,
                style: TextButton.styleFrom(
                  foregroundColor: colors.error,
                  minimumSize: const Size.fromHeight(56),
                ),
                icon: const Icon(Icons.delete_outline),
                label: Text(S.deleteTopic),
              ),
              Text(
                S.deleteTopicBody,
                style: context.text.bodySmall!.copyWith(
                  color: colors.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
          actions: [
            AppButton(
              label: _isEdit ? S.saveChanges : S.addTopic,
              loading: _saving,
              onPressed: _save,
            ),
          ],
        ),
      ),
    );
  }
}

class _QuestionCard extends StatelessWidget {
  const _QuestionCard({
    super.key,
    required this.index,
    required this.fields,
    required this.onRemove,
  });

  final int index;
  final _QuestionFields fields;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  S.questionN(index + 1),
                  style: context.text.titleMedium,
                ),
              ),
              IconButton(
                tooltip: S.removeQuestion,
                onPressed: onRemove,
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          AppTextField(
            label: S.fieldQuestionText,
            controller: fields.text,
            minLines: 1,
            maxLines: 3,
            maxLength: 200,
            textCapitalization: TextCapitalization.sentences,
            validator: Validators.questionText,
          ),
          const SizedBox(height: 16),
          AppTextField(
            label: S.fieldModelAnswer,
            controller: fields.answer,
            minLines: 3,
            maxLines: 8,
            maxLength: 1500,
            textCapitalization: TextCapitalization.sentences,
            validator: Validators.modelAnswer,
          ),
        ],
      ),
    );
  }
}
