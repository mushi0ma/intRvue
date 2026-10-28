import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../app/routes.dart';
import '../../core/constants/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/widgets.dart';
import '../../data/models/enums.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/topic_repository.dart';

/// S07 Бағыт және тақырып: кемінде бір тақырып міндетті.
class TopicSelectionScreen extends StatefulWidget {
  const TopicSelectionScreen({super.key, this.direction});

  final Direction? direction;

  @override
  State<TopicSelectionScreen> createState() => _TopicSelectionScreenState();
}

class _TopicSelectionScreenState extends State<TopicSelectionScreen> {
  late Direction _direction =
      widget.direction ??
      context.read<AuthRepository>().user?.direction ??
      Direction.mobile;
  late final Set<String> _selected = _defaultSelection();

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

  @override
  Widget build(BuildContext context) {
    final topics = context.read<TopicRepository>().byDirection(_direction);
    final count = _selected.length;

    return AppPage(
      showBack: true,
      title: S.topicsPickTitle,
      subtitle: S.topicsPickSubtitle,
      headerGap: 36,
      body: [
        ChoiceGroup<Direction>(
          values: Direction.values,
          selected: _direction,
          labelOf: (d) => d.label,
          onChanged: _changeDirection,
        ),
        const SizedBox(height: 34),
        Text(
          S.directionTopics(_direction.label),
          style: context.text.titleLarge,
        ),
        const SizedBox(height: 12),
        for (final topic in topics)
          CheckRow(
            title: topic.title,
            subtitle: topic.summary,
            checked: _selected.contains(topic.id),
            onChanged: (v) => setState(() {
              v ? _selected.add(topic.id) : _selected.remove(topic.id);
            }),
          ),
      ],
      actions: [
        AppButton(
          label: count == 0 ? S.pickTopicFirst : S.continueWithTopics(count),
          onPressed: count == 0
              ? null
              : () => context.push(
                  Uri(
                    path: Routes.practiceSetup,
                    queryParameters: {
                      'direction': _direction.name,
                      'topics': [
                        for (final t in topics)
                          if (_selected.contains(t.id)) t.id,
                      ].join(','),
                    },
                  ).toString(),
                ),
        ),
      ],
    );
  }
}
