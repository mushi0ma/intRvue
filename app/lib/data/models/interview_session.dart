import 'assessment.dart';
import 'enums.dart';
import 'question.dart';

enum AnswerStatus {
  /// Жауап әлі берілмеген.
  notAnswered,

  /// Жауап жіберілді, баға күтілуде.
  pending,

  /// Бағаланды.
  assessed,

  /// Өткізілді — 0 балл.
  skipped,
}

class AnswerRecord {
  AnswerRecord({required this.question});

  final Question question;
  String text = '';
  AnswerStatus status = AnswerStatus.notAnswered;
  Assessment? assessment;

  /// Пайдаланушы бағамен келіспеді.
  bool disputed = false;

  /// «Баға қате» / «Түсініксіз» және пайдаланушының түсіндірмесі.
  String? disputeReason;
  String? disputeComment;
}

/// Бір жаттығу сессиясы. Балл = қосынды / (15 × N) × 100.
/// Өткізілген сұрақ — 0, бағаланбаған жауап нөл емес (балл жоқ).
class InterviewSession {
  InterviewSession({
    required this.id,
    required this.direction,
    required this.level,
    required this.language,
    required this.topicIds,
    required this.answers,
    required this.startedAt,
  });

  final String id;
  final Direction direction;
  final Level level;
  final InterviewLanguage language;
  final List<String> topicIds;
  final List<AnswerRecord> answers;
  final DateTime startedAt;

  int currentIndex = 0;

  /// Сессия аяқталды (толық немесе ерте тоқтатылған).
  bool finished = false;

  int get questionCount => answers.length;
  AnswerRecord get current => answers[currentIndex];
  bool get isLastQuestion => currentIndex == answers.length - 1;

  String get trackLabel => '${direction.label} · ${level.label}';

  int get answeredCount => answers
      .where(
        (a) =>
            a.status == AnswerStatus.assessed ||
            a.status == AnswerStatus.pending,
      )
      .length;
  int get skippedCount =>
      answers.where((a) => a.status == AnswerStatus.skipped).length;
  int get assessedCount =>
      answers.where((a) => a.status == AnswerStatus.assessed).length;
  int get pendingCount =>
      answers.where((a) => a.status == AnswerStatus.pending).length;

  /// Барлық сұраққа жауап берілді не өткізілді және бәрі бағаланды.
  bool get isComplete =>
      finished &&
      answers.every(
        (a) =>
            a.status == AnswerStatus.assessed ||
            a.status == AnswerStatus.skipped,
      );

  int get pointsEarned =>
      answers.fold(0, (sum, a) => sum + (a.assessment?.total ?? 0));
  int get pointsMax => Assessment.maxTotal * questionCount;

  /// Толық емес сессияда балл есептелмейді.
  double? get score => isComplete ? pointsEarned / pointsMax * 100 : null;

  /// Тақырып бойынша балл (тек толық сессияда).
  Map<String, double> get topicScores {
    if (!isComplete) return const {};
    final earned = <String, int>{};
    final count = <String, int>{};
    for (final a in answers) {
      final id = a.question.topicId;
      earned[id] = (earned[id] ?? 0) + (a.assessment?.total ?? 0);
      count[id] = (count[id] ?? 0) + 1;
    }
    return {
      for (final id in earned.keys)
        id: earned[id]! / (Assessment.maxTotal * count[id]!) * 100,
    };
  }
}
