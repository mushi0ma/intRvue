import 'package:flutter/foundation.dart';

/// Журнал деңгейі.
enum LogLevel { info, warn, error }

/// Бір жазба (тесттер мен диагностика үшін соңғылары сақталады).
class LogEntry {
  const LogEntry(this.at, this.level, this.tag, this.message);
  final DateTime at;
  final LogLevel level;
  final String tag;
  final String message;

  @override
  String toString() => '[intRvue] ${level.name.toUpperCase()} $tag: $message';
}

/// Маңызды әрекеттер мен қателердің журналы.
///
/// Жазу алдында құпия деректер жасырылады: токендер, парольдер, email.
/// Release құрастыруда тек `warn` және `error` шығарылады; соңғы
/// [keep] жазба жадта сақталады.
abstract final class Log {
  static const keep = 200;
  static final _recent = <LogEntry>[];

  /// Шығару (тесттерде ауыстыруға болады).
  static void Function(String line) output = (line) => debugPrint(line);

  static List<LogEntry> get recent => List.unmodifiable(_recent);

  static void info(String tag, String message) =>
      _write(LogLevel.info, tag, message);

  static void warn(String tag, String message) =>
      _write(LogLevel.warn, tag, message);

  static void error(String tag, String message, [Object? error]) =>
      _write(LogLevel.error, tag, error == null ? message : '$message: $error');

  static void _write(LogLevel level, String tag, String message) {
    final entry = LogEntry(DateTime.now(), level, tag, redact(message));
    _recent.add(entry);
    if (_recent.length > keep) _recent.removeAt(0);
    if (kReleaseMode && level == LogLevel.info) return;
    output(entry.toString());
  }

  static final _bearer = RegExp(r'Bearer\s+[A-Za-z0-9._~+/=-]+');
  static final _secretField = RegExp(
    r'''(["']?(?:password|token|secret)["']?\s*[:=]\s*)(["']?)[^"',\s}&]+\2''',
    caseSensitive: false,
  );
  static final _email = RegExp(
    r'([A-Za-z0-9._%+-])[A-Za-z0-9._%+-]*@([A-Za-z0-9.-]+\.[A-Za-z]{2,})',
  );

  /// Токен, пароль және email-ді жасыру.
  static String redact(String text) => text
      .replaceAll(_bearer, 'Bearer ***')
      .replaceAllMapped(_secretField, (m) => '${m[1]}${m[2]}***${m[2]}')
      .replaceAllMapped(_email, (m) => '${m[1]}***@${m[2]}');

  @visibleForTesting
  static void clear() => _recent.clear();
}
