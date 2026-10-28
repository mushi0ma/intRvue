import 'enums.dart';

class UserProfile {
  const UserProfile({
    this.id,
    required this.name,
    required this.email,
    this.direction = Direction.mobile,
    this.level = Level.beginner,
    this.interviewLanguage = InterviewLanguage.kk,
  });

  /// users.id — деректер қорындағы идентификатор.
  final int? id;
  final String name;
  final String email;
  final Direction direction;
  final Level level;
  final InterviewLanguage interviewLanguage;

  String get initial =>
      name.trim().isEmpty ? '?' : name.trim().substring(0, 1).toUpperCase();

  /// «Mobile · Бастапқы»
  String get trackLabel => '${direction.label} · ${level.label}';

  UserProfile copyWith({
    String? name,
    String? email,
    Direction? direction,
    Level? level,
    InterviewLanguage? interviewLanguage,
  }) {
    return UserProfile(
      id: id,
      name: name ?? this.name,
      email: email ?? this.email,
      direction: direction ?? this.direction,
      level: level ?? this.level,
      interviewLanguage: interviewLanguage ?? this.interviewLanguage,
    );
  }
}
