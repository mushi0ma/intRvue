import 'dart:async';

import 'package:flutter/material.dart' show DateTimeRange, DateUtils;
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

import '../../core/constants/app_strings.dart';
import '../local/app_database.dart';
import '../local/db_errors.dart';
import '../local/db_schema.dart';
import '../local/mappers.dart';
import '../local/sync_journal.dart';
import '../models/enums.dart';
import '../models/interview_session.dart';
import '../models/question.dart';
import '../models/user_profile.dart';
import '../services/assessment_service.dart';
import 'topic_repository.dart';
import 'user_scoped.dart';

/// S08-де жиналған параметрлер. Келісім мен дайындық экрандары арқылы
/// сессия басталғанға дейін сақталады.
class PracticeRequest {
  const PracticeRequest({
    required this.direction,
    required this.level,
    required this.language,
    required this.topicIds,
    required this.questionCount,
  });

  final Direction direction;
  final Level level;
  final InterviewLanguage language;
  final List<String> topicIds;
  final int questionCount;
}

/// Ұсынылатын әлсіз тақырып.
class WeakTopic {
  const WeakTopic(this.topicId, this.score);
  final String topicId;
  final double score;
}

/// Тарихты сұрыптау.
enum HistorySort {
  newest,
  oldest,
  scoreHigh,
  scoreLow;

  String get label => switch (this) {
    newest => S.historyNewest,
    oldest => S.historyOldest,
    scoreHigh => S.historyScoreHigh,
    scoreLow => S.historyScoreLow,
  };
}

/// Жаттығу сессиялары: белсенді сессия, тарих, прогресс.
/// Әр өзгеріс `sessions` / `answers` кестелеріне бірден жазылады.
class SessionRepository extends ChangeNotifier implements UserScoped {
  SessionRepository(
    this._database,
    this._prefs,
    this._topics, {
    AssessmentService? assessment,
  }) : _assessment = assessment ?? const AssessmentService();

  static const _consentKey = 'session.consent';
  static const maxAnswerLength = 4000;
  static const maxRecommendations = 3;
  static const _draftDelay = Duration(milliseconds: 400);

  final AppDatabase _database;
  final SharedPreferences _prefs;
  final TopicRepository _topics;
  final AssessmentService _assessment;

  int? _userId;
  List<InterviewSession> _history = [];
  InterviewSession? _active;
  Timer? _draftTimer;
  int _counter = 0;

  Database get _db => _database.db;

  InterviewSession? get active => _active;

  /// Басталуды күтіп тұрған параметрлер.
  PracticeRequest? pending;

  @override
  Future<void> loadFor(UserProfile? user) async {
    _draftTimer?.cancel();
    _userId = user?.id;
    pending = null;
    if (user == null) {
      _history = [];
      _active = null;
      notifyListeners();
      return;
    }
    final (sessionRows, answerRows) = await dbGuard(() async {
      final sessions = await _db.query(
        DbSchema.sessions,
        where: 'user_id = ?',
        whereArgs: [user.id],
        orderBy: 'started_at DESC',
      );
      final answers = await _db.rawQuery(
        'SELECT a.* FROM ${DbSchema.answers} a '
        'JOIN ${DbSchema.sessions} s ON s.id = a.session_id '
        'WHERE s.user_id = ? ORDER BY a.session_id, a.position',
        [user.id],
      );
      return (sessions, answers);
    });

    final bySession = <String, List<AnswerRecord>>{};
    for (final row in answerRows) {
      final question = _topics.questionById(row['question_id']! as String);
      if (question == null) continue;
      (bySession[row['session_id']! as String] ??= []).add(
        Mappers.answer(row, question),
      );
    }
    final sessions = [
      for (final row in sessionRows)
        Mappers.session(row, bySession[row['id']] ?? []),
    ].where((s) => s.answers.isNotEmpty).toList();

    _active = sessions.where((s) => !s.finished).firstOrNull;
    _history = sessions.where((s) => s.finished).toList();
    notifyListeners();
  }

  /// Аяқталған сессиялар, жаңасы басында.
  List<InterviewSession> get history =>
      [..._history]..sort((a, b) => b.startedAt.compareTo(a.startedAt));

  /// Тарихты сүзгілеу және сұрыптау.
  List<InterviewSession> queryHistory({
    Direction? direction,
    bool? complete,
    DateTimeRange? period,
    HistorySort sort = HistorySort.newest,
  }) {
    final list = _history
        .where((s) => direction == null || s.direction == direction)
        .where((s) => complete == null || s.isComplete == complete)
        .where((s) => period == null || _inPeriod(s.startedAt, period))
        .toList();
    int byDate(InterviewSession a, InterviewSession b) =>
        a.startedAt.compareTo(b.startedAt);
    // Балы жоқ (толық емес) сессиялар әрқашан соңында.
    int byScore(InterviewSession a, InterviewSession b, bool desc) {
      final x = a.score, y = b.score;
      if (x == null || y == null) {
        return x == null ? (y == null ? -byDate(a, b) : 1) : -1;
      }
      final c = desc ? y.compareTo(x) : x.compareTo(y);
      return c != 0 ? c : -byDate(a, b);
    }

    list.sort(
      (a, b) => switch (sort) {
        HistorySort.newest => -byDate(a, b),
        HistorySort.oldest => byDate(a, b),
        HistorySort.scoreHigh => byScore(a, b, true),
        HistorySort.scoreLow => byScore(a, b, false),
      },
    );
    return list;
  }

  /// Кезеңнің соңғы күні толық кіреді (23:59-ға дейін).
  static bool _inPeriod(DateTime at, DateTimeRange period) {
    final start = DateUtils.dateOnly(period.start);
    final end = DateUtils.dateOnly(period.end).add(const Duration(days: 1));
    return !at.isBefore(start) && at.isBefore(end);
  }

  bool get consentGiven => _prefs.getBool(_consentKey) ?? false;

  Future<void> giveConsent() async {
    await _prefs.setBool(_consentKey, true);
    notifyListeners();
  }

  InterviewSession? byId(String id) {
    if (_active?.id == id) return _active;
    for (final s in _history) {
      if (s.id == id) return s;
    }
    return null;
  }

  /// Соңғы толық сессия (басты беттегі «Соңғы нәтиже»).
  InterviewSession? get lastComplete {
    for (final s in history) {
      if (s.isComplete) return s;
    }
    return null;
  }

  /// Тек бір бағыт пен деңгейдегі толық сессиялар, ескісі басында.
  List<InterviewSession> completeSessions(Direction direction, Level level) {
    return history.reversed
        .where(
          (s) => s.isComplete && s.direction == direction && s.level == level,
        )
        .toList();
  }

  /// Create: [pending] параметрлерімен жаңа сессия.
  /// Сұрақтарды «дайындау» ЖИ сұрауын имитациялайды.
  Future<InterviewSession?> startPending() async {
    final request = pending;
    final uid = _userId;
    if (request == null || uid == null) return null;
    await Future<void>.delayed(const Duration(milliseconds: 1600));
    final questions = _pickQuestions(
      request.direction,
      request.topicIds,
      request.questionCount,
    );
    if (questions.isEmpty) return null;
    final session = InterviewSession(
      id: 's-${DateTime.now().millisecondsSinceEpoch}-${_counter++}',
      direction: request.direction,
      level: request.level,
      language: request.language,
      topicIds: request.topicIds,
      answers: [for (final q in questions) AnswerRecord(question: q)],
      startedAt: DateTime.now(),
    );
    await dbGuard(
      () => _db.transaction(
        (txn) => AppDatabase.insertSession(txn, session, uid),
      ),
    );
    _active = session;
    pending = null;
    notifyListeners();
    return session;
  }

  /// Таңдалған тақырыптардан кезекпен алады, жетпесе — сол бағыттың
  /// басқа тақырыптарынан толықтырады.
  List<Question> _pickQuestions(
    Direction direction,
    List<String> topicIds,
    int count,
  ) {
    final pools = [for (final id in topicIds) _topics.questionsFor(id)];
    final picked = <Question>[];
    var round = 0;
    while (picked.length < count && pools.any((p) => p.length > round)) {
      for (final pool in pools) {
        if (pool.length > round && picked.length < count) {
          picked.add(pool[round]);
        }
      }
      round++;
    }
    if (picked.length < count) {
      for (final topic in _topics.byDirection(direction)) {
        if (topicIds.contains(topic.id)) continue;
        for (final q in _topics.questionsFor(topic.id)) {
          if (picked.length == count) break;
          picked.add(q);
        }
      }
    }
    return picked;
  }

  // ---------------------------------------------------------------- Update

  Future<void> _saveAnswer(InterviewSession s, int position) {
    final record = s.answers[position];
    return dbGuard(
      () => _db.update(
        DbSchema.answers,
        Mappers.answerRow(s.id, position, record)
          ..remove('session_id')
          ..remove('position'),
        where: 'session_id = ? AND position = ?',
        whereArgs: [s.id, position],
      ),
    );
  }

  Future<void> _saveSession(InterviewSession s) => dbGuard(
    () => _db.update(
      DbSchema.sessions,
      {
        'current_index': s.currentIndex,
        'finished': s.finished ? 1 : 0,
        'updated_at': Mappers.ms(DateTime.now()),
      },
      where: 'id = ?',
      whereArgs: [s.id],
    ),
  );

  /// Нобайды сақтау: жадта бірден, деректер қорына — 400 мс кідіріспен.
  void saveDraft(String text) {
    final session = _active;
    if (session == null) return;
    session.current.text = text;
    _draftTimer?.cancel();
    _draftTimer = Timer(_draftDelay, () => flushDraft());
  }

  /// Нобайды дереу жазу (үзіліс, экраннан шығу).
  Future<void> flushDraft() async {
    _draftTimer?.cancel();
    final session = _active;
    if (session == null) return;
    await _saveAnswer(session, session.currentIndex);
  }

  Future<void> submitCurrent(String text) async {
    final session = _active;
    if (session == null) return;
    _draftTimer?.cancel();
    final index = session.currentIndex;
    final record = session.current
      ..text = text.trim()
      ..status = AnswerStatus.pending;
    await _saveAnswer(session, index);
    notifyListeners();
    record
      ..assessment = await _assessment.assess(record.question, record.text)
      ..status = AnswerStatus.assessed;
    await _saveAnswer(session, index);
    notifyListeners();
  }

  Future<void> skipCurrent() async {
    final session = _active;
    if (session == null) return;
    _draftTimer?.cancel();
    session.current
      ..status = AnswerStatus.skipped
      ..assessment = null;
    await _saveAnswer(session, session.currentIndex);
    await _advance(session);
  }

  /// «Келесі сұрақ». Соңғы сұрақтан кейін сессия аяқталады.
  Future<void> next() async {
    final session = _active;
    if (session == null) return;
    await _advance(session);
  }

  Future<void> _advance(InterviewSession session) async {
    if (session.isLastQuestion) {
      await _finish(session);
    } else {
      session.currentIndex++;
      notifyListeners();
      await _saveSession(session);
    }
  }

  /// Сессияны ерте аяқтау — ол «Толық емес» болып сақталады.
  Future<void> finishActive() async {
    final session = _active;
    if (session != null) await _finish(session);
  }

  Future<void> _finish(InterviewSession session) async {
    session.finished = true;
    _history.add(session);
    _active = null;
    notifyListeners();
    await _saveSession(session);
  }

  /// Бағасы келмеген жауаптарды қайта бағалау.
  Future<void> retryPending(String sessionId) async {
    final session = byId(sessionId);
    if (session == null) return;
    for (var i = 0; i < session.answers.length; i++) {
      final record = session.answers[i];
      if (record.status != AnswerStatus.pending) continue;
      record
        ..assessment = await _assessment.assess(record.question, record.text)
        ..status = AnswerStatus.assessed;
      await _saveAnswer(session, i);
    }
    notifyListeners();
  }

  /// Бағаға пікір: себебі мен түсіндірмесі жауаппен бірге сақталады.
  /// Бастапқы балл өзгермейді.
  Future<void> dispute(
    String sessionId,
    int index, {
    required String reason,
    required String comment,
  }) async {
    final session = byId(sessionId);
    if (session == null) return;
    session.answers[index]
      ..disputed = true
      ..disputeReason = reason
      ..disputeComment = comment.trim();
    notifyListeners();
    await _saveAnswer(session, index);
  }

  // ---------------------------------------------------------------- Delete

  /// Сессия мен оның жауаптары (answers — ON DELETE CASCADE).
  Future<void> delete(String sessionId) async {
    final uid = _userId;
    if (uid == null) return;
    await dbGuard(
      () => _db.transaction((txn) async {
        final n = await txn.delete(
          DbSchema.sessions,
          where: 'id = ? AND user_id = ?',
          whereArgs: [sessionId, uid],
        );
        if (n > 0) {
          await SyncJournal.deleted(txn, uid, SyncJournal.session, sessionId);
        }
      }),
    );
    _history.removeWhere((s) => s.id == sessionId);
    notifyListeners();
  }

  /// Ең көбі үш әлсіз тақырып, ең төмен балл басында.
  List<WeakTopic> weakTopics(InterviewSession session) {
    final scores = session.topicScores.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));
    return scores
        .take(maxRecommendations)
        .map((e) => WeakTopic(e.key, e.value))
        .toList();
  }

  @override
  void dispose() {
    _draftTimer?.cancel();
    super.dispose();
  }
}
