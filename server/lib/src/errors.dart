/// Клиентке JSON түрінде қайтарылатын қате: `{"error": code, "message": ...}`.
class ApiError implements Exception {
  const ApiError(this.status, this.code, this.message);

  const ApiError.badRequest(String message)
    : this(400, 'invalid_request', message);
  const ApiError.unauthorized()
    : this(401, 'unauthorized', 'Missing or expired token.');

  final int status;
  final String code;
  final String message;

  Map<String, Object> toJson() => {'error': code, 'message': message};

  @override
  String toString() => 'ApiError($status, $code): $message';
}

/// JSON денесін тексеруге арналған көмекшілер: тип сәйкес келмесе — 400.
extension JsonFields on Map<String, Object?> {
  String str(String key, {int max = 20000, bool allowEmpty = false}) {
    final v = this[key];
    if (v is! String || (!allowEmpty && v.trim().isEmpty) || v.length > max) {
      throw ApiError.badRequest('"$key" must be a string (1–$max chars).');
    }
    return v;
  }

  String? optStr(String key, {int max = 20000}) =>
      this[key] == null ? null : str(key, max: max, allowEmpty: true);

  int integer(String key) {
    final v = this[key];
    if (v is! int) throw ApiError.badRequest('"$key" must be an integer.');
    return v;
  }

  int? optInt(String key) => this[key] == null ? null : integer(key);

  bool flag(String key) {
    final v = this[key];
    if (v is bool) return v;
    if (v == 0 || v == 1) return v == 1;
    throw ApiError.badRequest('"$key" must be a boolean.');
  }

  /// Миллисекундтағы Unix уақыты → UTC DateTime.
  DateTime time(String key) =>
      DateTime.fromMillisecondsSinceEpoch(integer(key), isUtc: true);

  List<Map<String, Object?>> objects(String key, {int max = 5000}) {
    final v = this[key] ?? const [];
    if (v is! List || v.length > max || v.any((e) => e is! Map)) {
      throw ApiError.badRequest('"$key" must be a list of objects (≤ $max).');
    }
    return [for (final e in v) (e as Map).cast<String, Object?>()];
  }
}
