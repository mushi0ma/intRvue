import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../app/routes.dart';
import '../../core/constants/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_icons.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/navigation.dart';
import '../../core/widgets/widgets.dart';
import '../../data/models/enums.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/session_repository.dart';
import '../../data/repositories/topic_repository.dart';

/// D1/D2 Жаңа жаттығу — бір экранда: бағыт, деңгей, тақырыптар, сұрақ
/// саны, тіл және бағалауға келісім. Бұрынғы S07 (тақырып), S08
/// (параметрлер) және келісім экраны біріктірілді (Figma v2).
class SessionSetupScreen extends StatefulWidget {
  const SessionSetupScreen({
    super.key,
    this.direction,
    this.level,
    this.topicIds = const [],
  });

  final Direction? direction;

  /// Прогресс сүзгісінен: «Middle» бойынша бос болса, сол деңгеймен бастау.
  final Level? level;

  /// Алдын ала таңдалған тақырыптар (тақырып бетінен, ұсыныстан).
  final List<String> topicIds;

  @override
  State<SessionSetupScreen> createState() => _SessionSetupScreenState();
}

class _SessionSetupScreenState extends State<SessionSetupScreen> {
  late final _user = context.read<AuthRepository>().user;
  late final _sessions = context.read<SessionRepository>();
  late Direction _direction =
      widget.direction ?? _user?.direction ?? Direction.mobile;
  late Level _level = widget.level ?? _user?.level ?? Level.beginner;
  late InterviewLanguage _language =
      _user?.interviewLanguage ?? InterviewLanguage.kk;
  int _count = 5;
  late bool _consent = _sessions.consentGiven;
  late final Set<String> _selected = widget.topicIds.isNotEmpty
      ? widget.topicIds.toSet()
      : _defaultSelection();
  bool _starting = false;

  Set<String> _defaultSelection() => context
      .read<TopicRepository>()
      .byDirection(_direction)
      .take(2)
      .map((t) => t.id)
      .toSet();

  void _changeDirection(Direction d) {
    if (d == _direction) return;
    setState(() {
      _direction = d;
      _selected
        ..clear()
        ..addAll(_defaultSelection());
    });
  }

  Future<void> _start() async {
    final topics = context.read<TopicRepository>().byDirection(_direction);
    setState(() => _starting = true);
    if (!_sessions.consentGiven) await _sessions.giveConsent();
    if (!mounted) return;
    _sessions.pending = PracticeRequest(
      direction: _direction,
      level: _level,
      language: _language,
      // Каталог ретімен — сұрақтар тақырыптар арасында кезектеседі.
      topicIds: [
        for (final t in topics)
          if (_selected.contains(t.id)) t.id,
      ],
      questionCount: _count,
    );
    setState(() => _starting = false);
    context.push(
      _sessions.active != null ? Routes.activeConflict : Routes.preparing,
    );
  }

  @override
  Widget build(BuildContext context) {
    final topics = context.read<TopicRepository>().byDirection(_direction);
    final p = context.palette;
    final secondary = context.colors.onSurfaceVariant;
    final small = context.text.bodySmall!.copyWith(color: secondary);
    // Басқа бағыттың тақырыптары таңдаулыда қалмайды.
    final chosen = topics.where((t) => _selected.contains(t.id)).length;
    final ready = chosen > 0 && _consent;

    return AppPage(
      leading: Row(
        children: [
          IconButton.outlined(
            tooltip: S.cancel,
            onPressed: () => context.popOr(Routes.home),
            style: IconButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.control),
              ),
              side: BorderSide(color: p.ink),
            ),
            icon: const Icon(AppIcons.close, size: 20),
          ),
          const SizedBox(width: AppSpacing.smd),
          Flexible(
            child: Text(
              S.newTraining,
              style: small,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      title: S.topicsPickTitle,
      body: [
        ChoiceGroup<Direction>(
          label: S.fieldDirection,
          values: Direction.values,
          selected: _direction,
          labelOf: (d) => d.label,
          onChanged: _changeDirection,
        ),
        const SizedBox(height: AppSpacing.md),
        ChoiceGroup<Level>(
          label: S.fieldLevel,
          values: Level.values,
          selected: _level,
          labelOf: (l) => l.label,
          onChanged: (l) => setState(() => _level = l),
        ),
        const SizedBox(height: AppSpacing.md),
        // D2: тақырып таңдалмаса — жиектегі белгі және түсініктеме.
        ReviewGutter(
          flagged: chosen == 0,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(S.fieldTopics, style: context.text.labelLarge),
                  ),
                  Text(S.topicsSelected(chosen), style: small),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Semantics(
                label: S.fieldTopics,
                container: true,
                child: ChoiceChips<String>(
                  values: [for (final t in topics) t.id],
                  isSelected: _selected.contains,
                  labelOf: (id) => topics.firstWhere((t) => t.id == id).title,
                  onTap: (id) => setState(() {
                    _selected.contains(id)
                        ? _selected.remove(id)
                        : _selected.add(id);
                  }),
                ),
              ),
              if (chosen == 0) ...[
                const SizedBox(height: AppSpacing.sm),
                ReviewNote(S.topicsPickSubtitle),
              ],
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: AppSpacing.smd,
          children: [
            Expanded(
              flex: 2,
              child: ChoiceGroup<int>(
                label: S.paramsCount,
                values: const [5, 10],
                selected: _count,
                labelOf: (n) => '$n',
                onChanged: (c) => setState(() => _count = c),
              ),
            ),
            Expanded(
              flex: 3,
              child: ChoiceGroup<InterviewLanguage>(
                label: S.paramsLanguageShort,
                values: InterviewLanguage.values,
                selected: _language,
                labelOf: (l) => l.code,
                onChanged: (l) => setState(() => _language = l),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        ReviewGutter(
          flagged: !_consent,
          child: Material(
            color: p.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.control),
              side: BorderSide(color: p.lineSubtle),
            ),
            clipBehavior: Clip.antiAlias,
            child: CheckboxListTile(
              value: _consent,
              onChanged: (v) => setState(() => _consent = v ?? false),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: const EdgeInsets.fromLTRB(4, 4, 12, 4),
              title: Text(S.consentCheck, style: context.text.bodyMedium),
              subtitle: Text(S.consentCheckHint, style: small),
            ),
          ),
        ),
        if (!_consent) ...[
          const SizedBox(height: AppSpacing.sm),
          ReviewNote(S.consentRequired),
        ],
      ],
      actions: [
        Text(S.paramsFooter, style: small),
        AppButton.accent(
          label: S.paramsStart,
          loading: _starting,
          onPressed: ready ? _start : null,
        ),
      ],
    );
  }
}
