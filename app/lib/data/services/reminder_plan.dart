import '../../app/routes.dart';
import '../../core/constants/app_strings.dart';
import '../../core/utils/formatters.dart';
import '../models/interview_session.dart';
import '../models/topic.dart';

/// Еске салудың мазмұны мен ашылатын экраны — қазіргі деректерден.
///
/// Басымдық:
/// 1. Аяқталмаған сессия → сол сессияны жалғастыру.
/// 2. Соңғы толық сессиядағы ең әлсіз тақырып → сол тақырыппен жаттығу.
/// 3. Әйтпесе → жалпы мәтін, тақырып таңдау.
///
/// Бүгін сессия аяқталса, бүгінгі еске салу өткізіледі ([skipToday]).
class ReminderPlan {
  const ReminderPlan({
    required this.kind,
    required this.title,
    required this.body,
    required this.route,
    required this.skipToday,
  });

  final ReminderKind kind;
  final String title;
  final String body;

  /// Хабарламаны басқанда ашылатын маршрут.
  final String route;
  final bool skipToday;

  static ReminderPlan build({
    required InterviewSession? active,
    required List<InterviewSession> history,
    required Topic? Function(String id) topicById,
    required DateTime now,
  }) {
    final skipToday = history.any(
      (s) => s.finished && _sameDay(s.startedAt, now),
    );

    if (active != null) {
      return ReminderPlan(
        kind: ReminderKind.resume,
        title: S.reminderResumeTitle,
        body: S.reminderResumeBody(
          active.trackLabel,
          S.progressOf(active.currentIndex + 1, active.questionCount),
        ),
        route: Routes.interview,
        skipToday: skipToday,
      );
    }

    final weak = _weakest(history, topicById);
    if (weak != null) {
      final (topic, score) = weak;
      return ReminderPlan(
        kind: ReminderKind.weakTopic,
        title: S.reminderWeakTitle,
        body: S.reminderWeakBody(topic.title, Fmt.score(score)),
        route: Uri(
          path: Routes.practiceSetup,
          queryParameters: {
            'direction': topic.direction.name,
            'topics': topic.id,
          },
        ).toString(),
        skipToday: skipToday,
      );
    }

    return ReminderPlan(
      kind: ReminderKind.generic,
      title: S.reminderNotificationTitle,
      body: S.reminderNotificationBody,
      route: Routes.practiceTopics,
      skipToday: skipToday,
    );
  }

  /// Соңғы толық сессиядағы ең төмен балды тақырып (тақырып әлі бар болса).
  static (Topic, double)? _weakest(
    List<InterviewSession> history,
    Topic? Function(String id) topicById,
  ) {
    for (final session in history) {
      if (!session.isComplete) continue;
      final scores = session.topicScores.entries.toList()
        ..sort((a, b) => a.value.compareTo(b.value));
      for (final e in scores) {
        final topic = topicById(e.key);
        if (topic != null) return (topic, e.value);
      }
      return null;
    }
    return null;
  }

  static bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  /// Кесте бірдей болса, қайта жоспарламаймыз.
  String signature() => '$kind|$title|$body|$skipToday';
}

enum ReminderKind { resume, weakTopic, generic }
