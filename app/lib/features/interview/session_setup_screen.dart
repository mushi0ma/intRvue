import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../app/routes.dart';
import '../../core/constants/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/widgets.dart';
import '../../data/models/enums.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/session_repository.dart';
import '../../data/repositories/topic_repository.dart';

/// S08 Сессия параметрлері: деңгей, тіл, сұрақ саны.
class SessionSetupScreen extends StatefulWidget {
  const SessionSetupScreen({
    super.key,
    required this.direction,
    required this.topicIds,
  });

  final Direction? direction;
  final List<String> topicIds;

  @override
  State<SessionSetupScreen> createState() => _SessionSetupScreenState();
}

class _SessionSetupScreenState extends State<SessionSetupScreen> {
  late final _user = context.read<AuthRepository>().user;
  late Level _level = _user?.level ?? Level.beginner;
  late InterviewLanguage _language =
      _user?.interviewLanguage ?? InterviewLanguage.kk;
  int _count = 5;

  void _start() {
    final sessions = context.read<SessionRepository>();
    final topics = context.read<TopicRepository>();
    final topicIds = widget.topicIds.isNotEmpty
        ? widget.topicIds
        : [topics.byDirection(_direction).first.id];
    sessions.pending = PracticeRequest(
      direction: _direction,
      level: _level,
      language: _language,
      topicIds: topicIds,
      questionCount: _count,
    );
    final next = sessions.active != null
        ? Routes.activeConflict
        : sessions.consentGiven
        ? Routes.preparing
        : Routes.consent;
    context.push(next);
  }

  Direction get _direction =>
      widget.direction ?? _user?.direction ?? Direction.mobile;

  @override
  Widget build(BuildContext context) {
    final repo = context.read<TopicRepository>();
    final names = [for (final id in widget.topicIds) ?repo.tryById(id)?.title]
        .join(', ');

    return AppPage(
      showBack: true,
      title: S.paramsTitle,
      subtitle: names.isEmpty
          ? _direction.label
          : '${_direction.label} · $names',
      headerGap: 32,
      body: [
        ChoiceGroup<Level>(
          label: S.fieldLevel,
          columns: 3,
          values: Level.values,
          selected: _level,
          labelOf: (l) => l.label,
          onChanged: (l) => setState(() => _level = l),
        ),
        const SizedBox(height: 28),
        ChoiceGroup<InterviewLanguage>(
          label: S.paramsLanguage,
          columns: 3,
          values: InterviewLanguage.values,
          selected: _language,
          labelOf: (l) => l.label,
          onChanged: (l) => setState(() => _language = l),
        ),
        const SizedBox(height: 28),
        ChoiceGroup<int>(
          label: S.paramsCount,
          values: const [5, 10],
          selected: _count,
          labelOf: S.questionsCount,
          onChanged: (c) => setState(() => _count = c),
        ),
        const SectionDivider(vertical: 40),
        InfoSection(title: S.paramsPaceTitle, body: S.paramsPaceBody),
        const SizedBox(height: 8),
        Text(
          S.aiDisclaimer,
          style: context.text.bodyMedium!.copyWith(
            color: context.colors.onSurfaceVariant,
          ),
        ),
      ],
      actions: [AppButton(label: S.paramsStart, onPressed: _start)],
    );
  }
}
