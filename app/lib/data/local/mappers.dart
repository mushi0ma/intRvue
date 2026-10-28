import 'dart:convert';

import '../models/assessment.dart';
import '../models/enums.dart';
import '../models/interview_session.dart';
import '../models/question.dart';
import '../models/topic.dart';
import '../models/user_profile.dart';

/// Кесте жолы ↔ модель түрлендірулері. JSON бағандарында тізімдер сақталады.
abstract final class Mappers {
  static int ms(DateTime d) => d.millisecondsSinceEpoch;
  static DateTime date(Object? v) =>
      DateTime.fromMillisecondsSinceEpoch(v! as int);

  // users
  static UserProfile user(Map<String, Object?> r) => UserProfile(
    id: r['id']! as int,
    name: r['name']! as String,
    email: r['email']! as String,
    direction: Direction.values.byName(r['direction']! as String),
    level: Level.values.byName(r['level']! as String),
    interviewLanguage: InterviewLanguage.values.byName(
      r['interview_language']! as String,
    ),
  );

  static Map<String, Object?> userProfileRow(UserProfile u) => {
    'name': u.name,
    'email': u.email.trim().toLowerCase(),
    'direction': u.direction.name,
    'level': u.level.name,
    'interview_language': u.interviewLanguage.name,
  };

  // topics
  static Topic topic(Map<String, Object?> r) => Topic(
    id: r['id']! as String,
    ownerId: r['owner_id'] as int?,
    title: r['title']! as String,
    summary: r['summary']! as String,
    direction: Direction.values.byName(r['direction']! as String),
    level: Level.values.byName(r['level']! as String),
    description: r['description']! as String,
    reviewPoints: (jsonDecode(r['review_points']! as String) as List)
        .cast<String>(),
    sampleQuestion: r['sample_question']! as String,
    createdAt: date(r['created_at']),
    updatedAt: date(r['updated_at']),
  );

  static Map<String, Object?> topicRow(Topic t) => {
    'id': t.id,
    'owner_id': t.ownerId,
    'title': t.title,
    'summary': t.summary,
    'direction': t.direction.name,
    'level': t.level.name,
    'description': t.description,
    'review_points': jsonEncode(t.reviewPoints),
    'sample_question': t.sampleQuestion,
    // SQLite LIKE/NOCASE кириллицаны ажыратпайды — іздеуге кіші әріппен
    // дайындалған баған сақтаймыз.
    'search_text': [
      t.title,
      t.summary,
      t.description,
      ...t.reviewPoints,
      t.direction.label,
    ].join(' ').toLowerCase(),
    'title_sort': t.title.toLowerCase(),
    'created_at': ms(t.createdAt ?? DateTime.now()),
    'updated_at': ms(t.updatedAt ?? DateTime.now()),
  };

  // questions
  static Question question(Map<String, Object?> r) => Question(
    id: r['id']! as String,
    topicId: r['topic_id']! as String,
    text: r['text']! as String,
    hint: r['hint']! as String,
    modelAnswer: r['model_answer']! as String,
    concepts: [
      for (final c in jsonDecode(r['concepts']! as String) as List)
        Concept(c['label'] as String, (c['keywords'] as List).cast<String>()),
    ],
  );

  static Map<String, Object?> questionRow(Question q, int position) => {
    'id': q.id,
    'topic_id': q.topicId,
    'position': position,
    'text': q.text,
    'hint': q.hint,
    'model_answer': q.modelAnswer,
    'concepts': jsonEncode([
      for (final c in q.concepts) {'label': c.label, 'keywords': c.keywords},
    ]),
  };

  // sessions
  static Map<String, Object?> sessionRow(InterviewSession s, int userId) => {
    'id': s.id,
    'user_id': userId,
    'direction': s.direction.name,
    'level': s.level.name,
    'language': s.language.name,
    'topic_ids': jsonEncode(s.topicIds),
    'started_at': ms(s.startedAt),
    'current_index': s.currentIndex,
    'finished': s.finished ? 1 : 0,
    'updated_at': ms(DateTime.now()),
  };

  static InterviewSession session(
    Map<String, Object?> r,
    List<AnswerRecord> answers,
  ) =>
      InterviewSession(
          id: r['id']! as String,
          direction: Direction.values.byName(r['direction']! as String),
          level: Level.values.byName(r['level']! as String),
          language: InterviewLanguage.values.byName(r['language']! as String),
          topicIds: (jsonDecode(r['topic_ids']! as String) as List)
              .cast<String>(),
          answers: answers,
          startedAt: date(r['started_at']),
        )
        ..currentIndex = r['current_index']! as int
        ..finished = r['finished'] == 1;

  // answers
  static Map<String, Object?> answerRow(
    String sessionId,
    int position,
    AnswerRecord a,
  ) {
    final x = a.assessment;
    return {
      'session_id': sessionId,
      'question_id': a.question.id,
      'position': position,
      ...answerState(a),
      'correctness': x?.correctness,
      'completeness': x?.completeness,
      'clarity': x?.clarity,
      'headline': x?.headline,
      'advice': x?.advice,
      'evidence': x?.evidence,
      'missing': x == null ? null : jsonEncode(x.missing),
      // Синхрондауда «соңғы өзгеріс жеңеді» ережесі осы уақытпен жұмыс істейді.
      'updated_at': ms(DateTime.now()),
    };
  }

  /// Жауаптың өзгермелі бөлігі — UPDATE үшін.
  static Map<String, Object?> answerState(AnswerRecord a) => {
    'text': a.text,
    'status': a.status.name,
    'disputed': a.disputed ? 1 : 0,
    'dispute_reason': a.disputeReason,
    'dispute_comment': a.disputeComment,
  };

  static AnswerRecord answer(Map<String, Object?> r, Question question) {
    final record = AnswerRecord(question: question)
      ..text = r['text']! as String
      ..status = AnswerStatus.values.byName(r['status']! as String)
      ..disputed = r['disputed'] == 1
      ..disputeReason = r['dispute_reason'] as String?
      ..disputeComment = r['dispute_comment'] as String?;
    if (r['correctness'] != null) {
      record.assessment = Assessment(
        correctness: r['correctness']! as int,
        completeness: r['completeness']! as int,
        clarity: r['clarity']! as int,
        headline: r['headline']! as String,
        advice: r['advice']! as String,
        evidence: r['evidence']! as String,
        missing: (jsonDecode(r['missing']! as String) as List).cast<String>(),
      );
    }
    return record;
  }
}
