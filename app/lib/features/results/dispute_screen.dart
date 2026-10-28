import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/routes.dart';
import '../../core/constants/app_strings.dart';
import '../../core/utils/navigation.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/widgets.dart';
import '../../data/local/db_errors.dart';
import '../../data/repositories/session_repository.dart';
import '../../data/repositories/topic_repository.dart';

enum _Reason { wrong, unclear }

/// «Бағаны белгілеу»: бағаға келіспеу себебі және түсіндірме.
class DisputeScreen extends StatefulWidget {
  const DisputeScreen({
    super.key,
    required this.sessionId,
    required this.index,
  });

  final String sessionId;
  final int index;

  @override
  State<DisputeScreen> createState() => _DisputeScreenState();
}

class _DisputeScreenState extends State<DisputeScreen> {
  final _form = GlobalKey<FormState>();
  final _comment = TextEditingController();
  _Reason _reason = _Reason.wrong;

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (!_form.currentState!.validate()) return;
    try {
      await context.read<SessionRepository>().dispute(
        widget.sessionId,
        widget.index,
        reason: _reason == _Reason.wrong ? S.disputeWrong : S.disputeUnclear,
        comment: _comment.text,
      );
    } on AppException catch (e) {
      if (mounted) showAppSnackBar(context, e.message);
      return;
    }
    if (!mounted) return;
    showAppSnackBar(context, S.disputeSent);
    context.popOr(Routes.history);
  }

  @override
  Widget build(BuildContext context) {
    final session = context.read<SessionRepository>().byId(widget.sessionId);
    final question = session?.answers[widget.index].question;
    final topic = question == null
        ? null
        : context.read<TopicRepository>().tryById(question.topicId);

    return Form(
      key: _form,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: AppPage(
        showBack: true,
        title: S.disputeTitle,
        subtitle: S.disputeSubtitle(widget.index + 1, topic?.title ?? ''),
        headerGap: 34,
        body: [
          Text(S.disputeQuestion, style: context.text.titleLarge),
          const SizedBox(height: 16),
          ChoiceGroup<_Reason>(
            values: _Reason.values,
            selected: _reason,
            labelOf: (r) =>
                r == _Reason.wrong ? S.disputeWrong : S.disputeUnclear,
            onChanged: (r) => setState(() => _reason = r),
          ),
          const SizedBox(height: 28),
          AppTextField(
            label: S.disputeComment,
            controller: _comment,
            hint: S.disputeCommentHint,
            minLines: 5,
            maxLines: 8,
            maxLength: 1000,
            textCapitalization: TextCapitalization.sentences,
            validator: (v) => (v == null || v.trim().isEmpty)
                ? S.disputeCommentRequired
                : null,
          ),
          const SizedBox(height: 20),
          Text(
            S.disputeNote,
            style: context.text.bodyMedium!.copyWith(
              color: context.colors.onSurfaceVariant,
            ),
          ),
        ],
        actions: [AppButton(label: S.disputeSend, onPressed: _send)],
      ),
    );
  }
}
