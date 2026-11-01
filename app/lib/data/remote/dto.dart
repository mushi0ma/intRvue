import '../models/enums.dart';
import '../models/question.dart';
import '../models/topic.dart';

/// REST API-дің JSON пішімдері ↔ Dart объектілері.
///
/// `fromJson` қатаң: өріс жоқ немесе түрі басқа болса — [FormatException].
/// Сервер жауабы бұзылса, қате экранда «сервер қатесі» болып көрінеді,
/// қосымша құламайды.

T _field<T>(Map<String, Object?> json, String key) {
  final v = json[key];
  if (v is T) return v;
  throw FormatException('"$key": expected $T, got ${v.runtimeType}');
}

List<T> _list<T>(Map<String, Object?> json, String key) =>
    _field<List<Object?>>(json, key).map((e) {
      if (e is T) return e;
      throw FormatException('"$key": expected a list of $T');
    }).toList();

/// Сервер уақытты екі пішімде береді: ресурстарда ISO 8601, аккаунтта мс.
DateTime _time(Map<String, Object?> json, String key) {
  final v = json[key];
  if (v is int) return DateTime.fromMillisecondsSinceEpoch(v, isUtc: true);
  if (v is String) {
    final parsed = DateTime.tryParse(v);
    if (parsed != null) return parsed.toUtc();
  }
  throw FormatException('"$key": expected a date-time');
}

E _enum<E extends Enum>(List<E> values, Map<String, Object?> json, String k) {
  final name = _field<String>(json, k);
  for (final v in values) {
    if (v.name == name) return v;
  }
  throw FormatException('"$k": unknown value "$name"');
}

/// `GET /v1/account`
class AccountDto {
  const AccountDto({
    required this.id,
    required this.email,
    required this.name,
    required this.direction,
    required this.level,
    required this.interviewLanguage,
    required this.createdAt,
  });

  factory AccountDto.fromJson(Map<String, Object?> json) => AccountDto(
    id: _field<int>(json, 'id'),
    email: _field<String>(json, 'email'),
    name: _field<String>(json, 'name'),
    direction: _enum(Direction.values, json, 'direction'),
    level: _enum(Level.values, json, 'level'),
    interviewLanguage: _enum(
      InterviewLanguage.values,
      json,
      'interview_language',
    ),
    createdAt: _time(json, 'created_at'),
  );

  final int id;
  final String email;
  final String name;
  final Direction direction;
  final Level level;
  final InterviewLanguage interviewLanguage;
  final DateTime createdAt;

  Map<String, Object?> toJson() => {
    'id': id,
    'email': email,
    'name': name,
    'direction': direction.name,
    'level': level.name,
    'interview_language': interviewLanguage.name,
    'created_at': createdAt.millisecondsSinceEpoch,
  };
}

/// Тақырып ішіндегі сұрақ.
class QuestionDto {
  const QuestionDto({
    required this.id,
    required this.text,
    required this.modelAnswer,
    this.hint = '',
    this.position = 0,
    this.concepts = const [],
  });

  factory QuestionDto.fromJson(Map<String, Object?> json) => QuestionDto(
    id: _field<String>(json, 'id'),
    position: _field<int>(json, 'position'),
    text: _field<String>(json, 'text'),
    hint: _field<String>(json, 'hint'),
    modelAnswer: _field<String>(json, 'model_answer'),
    concepts: [
      for (final c in _list<Map<String, Object?>>(json, 'concepts'))
        Concept(_field<String>(c, 'label'), _list<String>(c, 'keywords')),
    ],
  );

  factory QuestionDto.fromModel(Question q, int position) => QuestionDto(
    id: q.id,
    position: position,
    text: q.text,
    hint: q.hint,
    modelAnswer: q.modelAnswer,
    concepts: q.concepts,
  );

  final String id;
  final int position;
  final String text;
  final String hint;
  final String modelAnswer;
  final List<Concept> concepts;

  Map<String, Object?> toJson() => {
    'id': id,
    'position': position,
    'text': text,
    'hint': hint,
    'model_answer': modelAnswer,
    'concepts': [
      for (final c in concepts) {'label': c.label, 'keywords': c.keywords},
    ],
  };
}

/// `GET /v1/topics`, `GET|PATCH /v1/topics/{id}`, `POST /v1/topics`.
class TopicDto {
  const TopicDto({
    required this.id,
    required this.title,
    required this.summary,
    required this.direction,
    required this.level,
    required this.description,
    required this.reviewPoints,
    required this.sampleQuestion,
    required this.questions,
    this.createdAt,
    this.updatedAt,
  });

  factory TopicDto.fromJson(Map<String, Object?> json) => TopicDto(
    id: _field<String>(json, 'id'),
    title: _field<String>(json, 'title'),
    summary: _field<String>(json, 'summary'),
    direction: _enum(Direction.values, json, 'direction'),
    level: _enum(Level.values, json, 'level'),
    description: _field<String>(json, 'description'),
    reviewPoints: _list<String>(json, 'review_points'),
    sampleQuestion: _field<String>(json, 'sample_question'),
    questions: [
      for (final q in _list<Map<String, Object?>>(json, 'questions'))
        QuestionDto.fromJson(q),
    ],
    createdAt: _time(json, 'created_at'),
    updatedAt: _time(json, 'updated_at'),
  );

  /// Құрылғыдағы тақырыпты серверге жіберу үшін.
  factory TopicDto.fromModel(Topic t, List<Question> questions) => TopicDto(
    id: t.id,
    title: t.title,
    summary: t.summary,
    direction: t.direction,
    level: t.level,
    description: t.description,
    reviewPoints: t.reviewPoints,
    sampleQuestion: t.sampleQuestion,
    questions: [
      for (var i = 0; i < questions.length; i++)
        QuestionDto.fromModel(questions[i], i),
    ],
    createdAt: t.createdAt,
    updatedAt: t.updatedAt,
  );

  final String id;
  final String title;
  final String summary;
  final Direction direction;
  final Level level;
  final String description;
  final List<String> reviewPoints;
  final String sampleQuestion;
  final List<QuestionDto> questions;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  /// POST денесі. `updated_at`-ті сервер өзі қояды.
  Map<String, Object?> toJson() => {
    'id': id,
    'title': title,
    'summary': summary,
    'direction': direction.name,
    'level': level.name,
    'description': description,
    'review_points': reviewPoints,
    'questions': [for (final q in questions) q.toJson()],
    if (createdAt != null) 'created_at': createdAt!.toUtc().toIso8601String(),
  };

  /// PATCH денесі: тек мазмұн өрістері (id мен уақыт өзгермейді).
  Map<String, Object?> toPatchJson() =>
      toJson()..removeWhere((k, _) => k == 'id' || k == 'created_at');
}
