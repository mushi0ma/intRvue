import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../app/routes.dart';
import '../../core/constants/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_icons.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/widgets.dart';
import '../../data/models/assessment.dart';
import '../../data/models/interview_session.dart';
import '../../data/models/topic.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/session_repository.dart';
import '../../data/repositories/settings_repository.dart';
import '../../data/repositories/topic_repository.dart';
import '../../data/services/reminder_coordinator.dart';
import '../topics/topic_detail_screen.dart';

/// B Басты бет (Figma v2 Home, B1, B2).
///
/// ```
/// [А] Сәлем, Айдана            [🔔 Сәр, 19:00]
/// ── Белсенді сессия ─────────────── 2 / 5 сұрақ
/// Flutter виджеттері             Жалғастыру →
/// 80,0 / 100                 ↑ +6,7 алдыңғы …
/// [рубрика торы 3 × N]
/// [+ Жаңа жаттығу] [≡ Жауаптар]
/// ███ Келесі қадам: ең әлсіз тақырып ██████████
/// ```
/// Толық сессия жоқ кезде (B1) — бастау блогы және бағалау рубрикасы.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  /// Келесі еске салу: «Сәр, 19:00»; өшірулі болса — «Еске салу».
  static String reminderButtonLabel(ReminderSettings r, DateTime now) {
    if (!r.enabled || r.days.isEmpty) return S.reminders;
    final passed =
        now.hour * 60 + now.minute >= r.time.hour * 60 + r.time.minute;
    for (var i = 0; i < 8; i++) {
      final day = (now.weekday - 1 + i) % 7 + 1;
      if (r.days.contains(day) && !(i == 0 && passed)) {
        return '${Fmt.weekdaysShort[day]}, ${Fmt.timeOfDay(r.time)}';
      }
    }
    return S.reminders;
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthRepository>().user;
    final sessions = context.watch<SessionRepository>();
    final topics = context.watch<TopicRepository>();
    final reminders = context.watch<SettingsRepository>().reminders;
    final active = sessions.active;
    final last = sessions.lastComplete;
    final weak = last == null ? null : _weakest(sessions, topics, last);

    final top = <Widget>[
      _Header(
        name: user?.name ?? '',
        initial: user?.initial ?? '?',
        track: user?.trackLabel ?? '',
        reminder: reminderButtonLabel(
          reminders,
          context.read<ReminderCoordinator>().now,
        ),
      ),
      if (active != null) _ActiveSession(session: active, topics: topics),
      if (last != null)
        _LastResult(
          session: last,
          previous: _previous(sessions, last),
          showHeader: active == null,
        )
      else
        const _FirstRun(),
    ];

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AppSpacing.maxContentWidth,
            ),
            child: CustomScrollView(
              slivers: [
                SliverList.list(children: top),
                // Қалған биіктікті төменгі блок толтырады: қараңғы панель
                // навигациямен жалғасады (Figma), B1-де — каталог батырмасы.
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: weak != null
                      ? _NextStep(topic: weak.$1, score: weak.$2)
                      : Align(
                          alignment: Alignment.bottomCenter,
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
                            child: AppButton.tonal(
                              label: S.homeCatalog,
                              icon: AppIcons.topics,
                              onPressed: () => context.go(Routes.topics),
                            ),
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static (Topic, double)? _weakest(
    SessionRepository sessions,
    TopicRepository topics,
    InterviewSession last,
  ) {
    for (final w in sessions.weakTopics(last)) {
      final t = topics.tryById(w.topicId);
      if (t != null) return (t, w.score);
    }
    return null;
  }

  /// Сол бағыт пен деңгейдегі алдыңғы толық сессия (айырманы есептеу үшін).
  static InterviewSession? _previous(
    SessionRepository sessions,
    InterviewSession last,
  ) {
    final same = sessions.completeSessions(last.direction, last.level);
    final i = same.indexWhere((s) => s.id == last.id);
    return i > 0 ? same[i - 1] : null;
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.name,
    required this.initial,
    required this.track,
    required this.reminder,
  });

  final String name;
  final String initial;
  final String track;
  final String reminder;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Row(
        children: [
          Semantics(
            button: true,
            label: S.openProfile,
            excludeSemantics: true,
            child: InkResponse(
              onTap: () => context.go(Routes.profile),
              radius: 28,
              child: SizedBox.square(
                dimension: 48,
                child: Center(child: Monogram(initial: initial, size: 40)),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Semantics(
                  header: true,
                  child: Text(
                    S.greeting(name),
                    style: context.text.titleMedium,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  track,
                  style: context.text.bodySmall!.copyWith(
                    color: context.colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          // 130%-дан үлкен мәтінде — тек белгіше: сәлемдесу тасымалданбайды.
          if (MediaQuery.textScalerOf(context).scale(1) > 1.3)
            IconButton.outlined(
              tooltip: '${S.reminders}: $reminder',
              onPressed: () => context.push(Routes.reminders),
              style: IconButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.control),
                ),
                side: BorderSide(color: context.palette.ink),
              ),
              icon: const Icon(AppIcons.notifications),
            )
          else
            OutlinedButton.icon(
              onPressed: () => context.push(Routes.reminders),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(0, AppSpacing.controlHeight),
                padding: const EdgeInsets.symmetric(horizontal: 14),
              ),
              icon: const Icon(AppIcons.notifications, size: 18),
              label: Text(reminder),
            ),
        ],
      ),
    );
  }
}

/// Бөлім жолағы: белгіше + атау, оң жақта мета (bg/muted).
class _Strip extends StatelessWidget {
  const _Strip({required this.icon, required this.title, this.meta});

  final IconData icon;
  final String title;
  final String? meta;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: context.palette.muted,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Semantics(
        header: true,
        child: Row(
          children: [
            Icon(icon, size: 18),
            const SizedBox(width: AppSpacing.sm),
            Expanded(child: Text(title, style: context.text.labelLarge)),
            if (meta != null)
              Text(
                meta!,
                style: context.text.bodySmall!.copyWith(
                  color: context.colors.onSurfaceVariant,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ActiveSession extends StatelessWidget {
  const _ActiveSession({required this.session, required this.topics});

  final InterviewSession session;
  final TopicRepository topics;

  @override
  Widget build(BuildContext context) {
    final names = session.topicIds
        .map((id) => topics.tryById(id)?.title)
        .whereType<String>()
        .join(', ');
    void open() => context.push(Routes.interview);
    final big = MediaQuery.textScalerOf(context).scale(1) > 1.3;
    final info = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 2,
      children: [
        Text(
          names.isEmpty ? session.trackLabel : names,
          style: context.text.titleMedium,
        ),
        Text(
          '${session.trackLabel} · ${S.draftStored}',
          style: context.text.bodySmall!.copyWith(
            color: context.colors.onSurfaceVariant,
          ),
        ),
      ],
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Strip(
          icon: AppIcons.pending,
          title: S.homeActiveSession,
          meta: S.progressOf(session.currentIndex + 1, session.questionCount),
        ),
        Material(
          color: context.palette.surface,
          child: InkWell(
            onTap: open,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
              child: Flex(
                direction: big ? Axis.vertical : Axis.horizontal,
                crossAxisAlignment: big
                    ? CrossAxisAlignment.start
                    : CrossAxisAlignment.center,
                children: [
                  if (big) info else Expanded(child: info),
                  TextButton.icon(
                    onPressed: open,
                    iconAlignment: IconAlignment.end,
                    icon: const Icon(AppIcons.forward, size: 18),
                    label: Text(S.continueAction),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _LastResult extends StatelessWidget {
  const _LastResult({
    required this.session,
    required this.previous,
    required this.showHeader,
  });

  final InterviewSession session;
  final InterviewSession? previous;
  final bool showHeader;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final secondary = context.colors.onSurfaceVariant;
    final small = context.text.bodySmall!.copyWith(color: secondary);
    final score = session.score!;
    final delta = previous == null ? null : score - previous!.score!;
    final date = Fmt.day(session.startedAt);
    final big = MediaQuery.textScalerOf(context).scale(1) > 1.3;

    Widget deltaLine() {
      final up = delta! >= 0;
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            up ? AppIcons.up : AppIcons.down,
            size: 16,
            color: up ? p.success : p.ink,
          ),
          const SizedBox(width: 2),
          Text(
            '${up ? '+' : '−'}${Fmt.score(delta.abs())}',
            style: context.text.labelLarge!.copyWith(
              color: up ? p.success : p.ink,
            ),
          ),
        ],
      );
    }

    List<int?> criterion(int Function(Assessment a) of) => [
      for (final a in session.answers)
        a.status == AnswerStatus.assessed && a.assessment != null
            ? of(a.assessment!)
            : null,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showHeader)
          _Strip(
            icon: AppIcons.check,
            title: '${S.homeLastResult} · $date',
            meta: S.homeComplete,
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Semantics(
            button: true,
            label: '${S.homeLastResult}: ${Fmt.score(score)} ${S.outOf100}',
            child: InkWell(
              borderRadius: BorderRadius.circular(AppRadius.cell),
              onTap: () => context.push(Routes.summary(session.id)),
              child: big
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ExcludeSemantics(
                          child: Align(
                            alignment: AlignmentDirectional.bottomStart,
                            child: Text.rich(
                              textScaler: MediaQuery.textScalerOf(context)
                                  .clamp(maxScaleFactor: 1.3),
                              TextSpan(
                                children: [
                                  TextSpan(
                                    text: Fmt.score(score),
                                    style: context.text.displayLarge,
                                  ),
                                  TextSpan(
                                    text: '  / 100',
                                    style: context.text.bodyLarge!.copyWith(
                                      color: secondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (delta != null) ...[
                              deltaLine(),
                              Text(S.homeDeltaPrev, style: small),
                            ],
                            if (!showHeader)
                              Text(
                                '$date · ${S.homeLastSession}',
                                style: small,
                              ),
                          ],
                        ),
                      ],
                    )
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: ExcludeSemantics(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: AlignmentDirectional.bottomStart,
                              child: Text.rich(
                                textScaler: MediaQuery.textScalerOf(context)
                                    .clamp(maxScaleFactor: 1.3),
                                TextSpan(
                                  children: [
                                    TextSpan(
                                      text: Fmt.score(score),
                                      style: context.text.displayLarge,
                                    ),
                                    TextSpan(
                                      text: '  / 100',
                                      style: context.text.bodyLarge!.copyWith(
                                        color: secondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            if (delta != null) ...[
                              deltaLine(),
                              Text(S.homeDeltaPrev, style: small),
                            ],
                            if (!showHeader)
                              Text(
                                '$date · ${S.homeLastSession}',
                                style: small,
                              ),
                          ],
                        ),
                      ],
                    ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: RubricGrid(
            columns: [for (var i = 1; i <= session.questionCount; i++) '$i'],
            rows: [
              (S.correctness, criterion((a) => a.correctness)),
              (S.completeness, criterion((a) => a.completeness)),
              (S.clarity, criterion((a) => a.clarity)),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
          child: Row(
            spacing: AppSpacing.sm,
            children: [
              Expanded(
                child: AppButton(
                  label: S.homeStartAction,
                  icon: AppIcons.add,
                  onPressed: () => context.push(Routes.practiceTopics),
                ),
              ),
              Expanded(
                child: AppButton.tonal(
                  label: S.homeAnswers,
                  icon: AppIcons.list,
                  onPressed: () => context.push(Routes.answers(session.id)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// B1: толық сессия әлі жоқ.
class _FirstRun extends StatelessWidget {
  const _FirstRun();

  @override
  Widget build(BuildContext context) {
    final secondary = context.colors.onSurfaceVariant;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            S.homeFirstLabel,
            style: context.text.bodySmall!.copyWith(color: secondary),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(S.homeStartTitle, style: context.text.headlineLarge),
          const SizedBox(height: AppSpacing.sm),
          Text(
            S.homeStartBody,
            style: context.text.bodyMedium!.copyWith(color: secondary),
          ),
          const SizedBox(height: AppSpacing.md),
          AppButton.accent(
            label: S.homeStartAction,
            onPressed: () => context.push(Routes.practiceTopics),
          ),
          const SizedBox(height: AppSpacing.lg),
          const Divider(),
          const SizedBox(height: AppSpacing.md),
          Text(S.homeHowAssessed, style: context.text.titleMedium),
          const SizedBox(height: AppSpacing.xs),
          CriterionRow(score: 5, title: S.correctness, hint: S.correctnessHint),
          CriterionRow(
            score: 3,
            title: S.completeness,
            hint: S.completenessHint,
          ),
          CriterionRow(score: 2, title: S.clarity, hint: S.clarityHint),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '${S.aiDisclaimer} ${S.notHiringDecision}',
            style: context.text.bodySmall!.copyWith(color: secondary),
          ),
        ],
      ),
    );
  }
}

/// Қараңғы панель: ең әлсіз тақырып және оны жаттықтыру.
class _NextStep extends StatelessWidget {
  const _NextStep({required this.topic, required this.score});

  final Topic topic;
  final double score;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return ColoredBox(
      color: p.panel,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: AppSpacing.xs,
                    children: [
                      Semantics(
                        header: true,
                        child: Text(
                          S.homeNextStep,
                          style: context.text.bodySmall!.copyWith(
                            color: p.onPanelMuted,
                          ),
                        ),
                      ),
                      Text(
                        S.homeWeakest(topic.title),
                        style: context.text.headlineSmall!.copyWith(
                          color: p.onPanel,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.smd),
                Container(
                  width: 56,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    border: Border.all(color: p.onPanel),
                    borderRadius: BorderRadius.circular(AppRadius.cell),
                  ),
                  child: Semantics(
                    label: '${score.round()} / 100',
                    excludeSemantics: true,
                    child: Column(
                      children: [
                        Text(
                          '${score.round()}',
                          textScaler: TextScaler.noScaling,
                          style: context.text.headlineSmall!.copyWith(
                            color: p.onPanel,
                          ),
                        ),
                        Text(
                          '/ 100',
                          textScaler: TextScaler.noScaling,
                          style: context.text.bodySmall!.copyWith(
                            color: p.onPanelMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            AppButton.accent(
              label: S.practiceThisTopic,
              onPressed: () =>
                  context.push(TopicDetailScreen.practiceLocation(topic)),
            ),
          ],
        ),
      ),
    );
  }
}
