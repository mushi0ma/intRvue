import '../models/assessment.dart';
import '../models/enums.dart';
import '../models/interview_session.dart';
import '../models/question.dart';
import 'seed_questions.dart';

/// Тарих пен прогресс үшін синтетикалық сессиялар (дизайндағы мысалдар).
List<InterviewSession> buildDemoHistory() {
  return [
    _session(
      id: 's-1019',
      at: DateTime(2026, 10, 19, 18, 42),
      plan: [
        ('dart-1', 13),
        ('widgets-1', 12),
        ('dart-3', 13),
        ('widgets-2', 9),
        ('dart-2', 13),
      ],
    ),
    _session(
      id: 's-1017',
      at: DateTime(2026, 10, 17, 20, 10),
      plan: [
        ('widgets-1', 11),
        ('state-1', 10),
        ('widgets-3', 12),
        ('state-2', 11),
        ('async-1', 11),
      ],
    ),
    _incompleteSession(),
    _session(
      id: 's-1012',
      at: DateTime(2026, 10, 12, 17, 30),
      plan: [
        for (final id in [
          'dart-1', 'dart-2', 'dart-3', 'widgets-1', 'widgets-2', //
          'widgets-3', 'state-1', 'state-2', 'async-1', 'async-2',
        ])
          (id, 10),
      ],
    ),
    _session(
      id: 's-1009',
      at: DateTime(2026, 10, 9, 19, 15),
      plan: [
        ('dart-1', 9),
        ('dart-2', 9),
        ('widgets-1', 9),
        ('async-1', 9),
        ('async-3', 9),
      ],
    ),
  ];
}

/// Үзіліске қойылған белсенді сессия: 2 / 5 сұрақ, нобай сақталған.
InterviewSession buildDemoActiveSession() {
  final session = InterviewSession(
    id: 's-active',
    direction: Direction.mobile,
    level: Level.beginner,
    language: InterviewLanguage.kk,
    topicIds: const ['dart-basics', 'flutter-widgets'],
    answers: [
      for (final id in ['dart-1', 'widgets-1', 'dart-3', 'widgets-2', 'dart-2'])
        AnswerRecord(question: _q(id)),
    ],
    startedAt: DateTime(2026, 10, 26, 9, 20),
  );
  _assess(session.answers[0], 12);
  session.currentIndex = 1;
  session.answers[1].text = _savedWidgetsAnswer;
  return session;
}

const _savedWidgetsAnswer =
    'StatelessWidget өзгермейтін интерфейсті '
    'көрсетеді. StatefulWidget күйі өзгергенде интерфейсті жаңарта алады. '
    'Мысалы, санауыш үшін StatefulWidget қолданамын.';

InterviewSession _session({
  required String id,
  required DateTime at,
  required List<(String, int)> plan,
}) {
  final session = InterviewSession(
    id: id,
    direction: Direction.mobile,
    level: Level.beginner,
    language: InterviewLanguage.kk,
    topicIds: {for (final (qid, _) in plan) _q(qid).topicId}.toList(),
    answers: [for (final (qid, _) in plan) AnswerRecord(question: _q(qid))],
    startedAt: at,
  );
  for (var i = 0; i < plan.length; i++) {
    final record = session.answers[i];
    if (record.question.id == 'widgets-1') record.text = _savedWidgetsAnswer;
    _assess(record, plan[i].$2);
  }
  session
    ..currentIndex = plan.length - 1
    ..finished = true;
  return session;
}

InterviewSession _incompleteSession() {
  final session = InterviewSession(
    id: 's-1015',
    direction: Direction.mobile,
    level: Level.beginner,
    language: InterviewLanguage.kk,
    topicIds: const ['dart-basics', 'flutter-widgets', 'state-management'],
    answers: [
      for (final id in ['dart-1', 'widgets-1', 'dart-3', 'state-1', 'dart-2'])
        AnswerRecord(question: _q(id)),
    ],
    startedAt: DateTime(2026, 10, 15, 19, 5),
  );
  _assess(session.answers[0], 11);
  session.answers[1]
    ..text = _savedWidgetsAnswer
    ..status = AnswerStatus.pending;
  session.answers[2].status = AnswerStatus.skipped;
  session
    ..currentIndex = 2
    ..finished = true;
  return session;
}

Question _q(String id) => seedQuestions.firstWhere((q) => q.id == id);

void _assess(AnswerRecord record, int total) {
  // 12 → 4 / 3 / 5 — дизайндағы сақталған жауап мысалы.
  final (c, comp, cl) = switch (total) {
    12 => (4, 3, 5),
    13 => (5, 4, 4),
    11 => (4, 3, 4),
    10 => (4, 3, 3),
    9 => (3, 3, 3),
    _ => (total ~/ 3, total ~/ 3, total - 2 * (total ~/ 3)),
  };
  final missing = record.question.concepts.skip(2).map((c) => c.label).toList();
  record
    ..text = record.text.isEmpty
        ? record.question.modelAnswer.split('. ').first
        : record.text
    ..status = AnswerStatus.assessed
    ..assessment = Assessment(
      correctness: c,
      completeness: comp,
      clarity: cl,
      headline: total >= 12
          ? 'Негізгі ой дұрыс.'
          : 'Бағыт дұрыс, бірақ толық емес.',
      advice: missing.isEmpty
          ? 'Келесі сұраққа өтуге болады.'
          : '«${missing.first}» бөлігін нақтылаңыз.',
      evidence:
          '«${record.question.concepts.first.label}» дұрыс '
          'түсіндірілген.',
      missing: missing,
    );
}
