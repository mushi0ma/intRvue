import '../../core/constants/app_strings.dart';

/// Сұхбат бағыты.
enum Direction {
  frontend('Frontend'),
  backend('Backend'),
  mobile('Mobile'),
  qa('QA');

  const Direction(this.label);
  final String label;
}

/// Дайындық деңгейі.
enum Level {
  beginner,
  junior,
  middle;

  /// Интерфейс тіліне қарай.
  String get label => switch (this) {
    beginner => S.levelBeginner,
    junior => S.levelJunior,
    middle => S.levelMiddle,
  };
}

/// Сұхбат пен кері байланыс тілі.
enum InterviewLanguage {
  kk('Қазақша', 'ҚАЗ'),
  ru('Русский', 'РУС'),
  en('English', 'ENG');

  const InterviewLanguage(this.label, this.code);
  final String label;

  /// Тар сегменттер үшін қысқа белгі (Figma D1).
  final String code;
}

/// Интерфейс тілі. Қазір тек қазақша мәтіндер бар.
enum InterfaceLanguage {
  kk('Қазақша'),
  ru('Русский');

  const InterfaceLanguage(this.label);
  final String label;
}
