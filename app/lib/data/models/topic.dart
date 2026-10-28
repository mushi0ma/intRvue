import '../../core/constants/app_strings.dart';
import 'enums.dart';

/// Тақырыптар каталогының бір элементі (List → Detail).
/// [ownerId] бос болса — кірістірілген тақырып, әйтпесе пайдаланушы қосқан.
class Topic {
  const Topic({
    required this.id,
    required this.title,
    required this.summary,
    required this.direction,
    required this.description,
    required this.reviewPoints,
    required this.sampleQuestion,
    this.level = Level.beginner,
    this.ownerId,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String title;

  /// Тізімдегі қысқа сипаттама: «Типтер, null safety, коллекциялар».
  final String summary;
  final Direction direction;
  final Level level;

  /// Detail экранындағы кіріспе мәтін.
  final String description;

  /// «Нені қайталаймыз?» бөлімі.
  final List<String> reviewPoints;

  /// «Үлгі сұрақ» бөлімі.
  final String sampleQuestion;

  final int? ownerId;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  /// Пайдаланушы өзі қосқан — өзгертуге және жоюға болады.
  bool get isCustom => ownerId != null;

  String get trackLabel => '${direction.label} · ${level.label}';
}

/// Create/Edit формасының деректері.
class TopicDraft {
  const TopicDraft({
    required this.title,
    required this.summary,
    required this.description,
    required this.direction,
    required this.level,
    required this.reviewPoints,
    required this.questions,
  });

  final String title;
  final String summary;
  final String description;
  final Direction direction;
  final Level level;
  final List<String> reviewPoints;
  final List<QuestionDraft> questions;
}

class QuestionDraft {
  const QuestionDraft({this.id, required this.text, required this.modelAnswer});

  /// Өзгертілетін сұрақтың идентификаторы; жаңасында бос.
  final String? id;
  final String text;
  final String modelAnswer;
}

/// Каталогты сұрыптау тәсілі.
enum TopicSort {
  titleAsc,
  titleDesc,
  newest,
  weakest;

  String get label => switch (this) {
    titleAsc => S.sortTitleAsc,
    titleDesc => S.sortTitleDesc,
    newest => S.sortNewest,
    weakest => S.sortWeakest,
  };
}

/// Каталог сұрауы: іздеу, сүзгілер, сұрыптау.
class TopicQuery {
  const TopicQuery({
    this.search = '',
    this.direction,
    this.level,
    this.onlyFavorites = false,
    this.onlyMine = false,
    this.sort = TopicSort.titleAsc,
  });

  final String search;
  final Direction? direction;
  final Level? level;
  final bool onlyFavorites;
  final bool onlyMine;
  final TopicSort sort;

  /// Белсенді сүзгілер саны (іздеу мен сұрыптаудан басқа).
  int get activeFilters =>
      (direction != null ? 1 : 0) +
      (level != null ? 1 : 0) +
      (onlyFavorites ? 1 : 0) +
      (onlyMine ? 1 : 0);

  TopicQuery copyWith({
    String? search,
    Direction? Function()? direction,
    Level? Function()? level,
    bool? onlyFavorites,
    bool? onlyMine,
    TopicSort? sort,
  }) {
    return TopicQuery(
      search: search ?? this.search,
      direction: direction != null ? direction() : this.direction,
      level: level != null ? level() : this.level,
      onlyFavorites: onlyFavorites ?? this.onlyFavorites,
      onlyMine: onlyMine ?? this.onlyMine,
      sort: sort ?? this.sort,
    );
  }
}

/// Каталог жолы: тақырып, пайдаланушының орташа балы, таңдаулы белгісі.
class TopicListItem {
  const TopicListItem({
    required this.topic,
    required this.questionCount,
    this.averageScore,
    this.isFavorite = false,
  });

  final Topic topic;
  final int questionCount;

  /// Бағаланған жауаптар бойынша 0–100; жауап жоқ болса — null.
  final double? averageScore;
  final bool isFavorite;
}
