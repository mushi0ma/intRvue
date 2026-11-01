import 'dart:convert';
import 'dart:isolate';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

/// Пароль ашық түрде сақталмайды: PBKDF2-HMAC-SHA256, кездейсоқ тұз.
///
/// Хэш пішімі: `pbkdf2-sha256$<итерация>$<hex>`, тұз — бөлек бағанда.
/// Ескі пішім (тұз + бір рет SHA-256, 64 hex) әлі тексеріледі; ондай
/// аккаунт кірген сәтте жаңа пішімге көшіріледі ([needsRehash]).
///
/// Есептеу ~0,3 с алады, сондықтан бөлек isolate-та жүреді: интерфейс
/// қатып қалмайды.
abstract final class PasswordHasher {
  /// Сервердегімен бірдей. Тесттерде азайтылады (flutter_test_config).
  static int iterations = 120000;

  static const _scheme = 'pbkdf2-sha256';
  static final _random = Random.secure();

  static String newSalt() =>
      base64Url.encode(List<int>.generate(16, (_) => _random.nextInt(256)));

  static Future<String> hash(String password, String salt) {
    final rounds = iterations;
    return _run(() => _format(rounds, _pbkdf2(password, salt, rounds)));
  }

  static Future<bool> verify(
    String password,
    String salt,
    String stored,
  ) async {
    final parts = stored.split(r'$');
    if (parts.length == 3 && parts[0] == _scheme) {
      final rounds = int.tryParse(parts[1]);
      if (rounds == null || rounds < 1) return false;
      final actual = await _run(() => _hex(_pbkdf2(password, salt, rounds)));
      return _same(actual, parts[2]);
    }
    return _same(_legacy(password, salt), stored);
  }

  /// Ескі пішім немесе басқа итерация саны — кіргеннен кейін қайта хэштеу.
  static bool needsRehash(String stored) =>
      !stored.startsWith('$_scheme\$$iterations\$');

  static Future<T> _run<T>(T Function() body) =>
      iterations >= 10000 ? Isolate.run(body) : Future.sync(body);

  static String _format(int rounds, List<int> key) =>
      '$_scheme\$$rounds\$${_hex(key)}';

  static String _legacy(String password, String salt) =>
      sha256.convert(utf8.encode('$salt:$password')).toString();

  /// SHA-256 шығысы 32 байт — бір блок жеткілікті.
  static List<int> _pbkdf2(String password, String salt, int rounds) {
    final hmac = Hmac(sha256, utf8.encode(password));
    var u = hmac.convert([...utf8.encode(salt), 0, 0, 0, 1]).bytes;
    final result = Uint8List.fromList(u);
    for (var i = 1; i < rounds; i++) {
      u = hmac.convert(u).bytes;
      for (var j = 0; j < result.length; j++) {
        result[j] ^= u[j];
      }
    }
    return result;
  }

  static String _hex(List<int> bytes) =>
      bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();

  /// Уақыты мәтіннің қай жерінде айырмашылық бар екеніне тәуелді емес.
  static bool _same(String a, String b) {
    if (a.length != b.length) return false;
    var diff = 0;
    for (var i = 0; i < a.length; i++) {
      diff |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
    }
    return diff == 0;
  }
}
