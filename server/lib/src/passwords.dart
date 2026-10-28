import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

/// PBKDF2-HMAC-SHA256. Сақталу пішімі: `pbkdf2-sha256$<итерация>$<тұз>$<хэш>`,
/// сондықтан итерация санын кейін өзгертсе, ескі хэштер де тексеріледі.
class Passwords {
  const Passwords({this.iterations = 120000});

  final int iterations;

  static final _random = Random.secure();

  static List<int> randomBytes(int n) =>
      List<int>.generate(n, (_) => _random.nextInt(256));

  String hash(String password) {
    final salt = randomBytes(16);
    final key = _pbkdf2(utf8.encode(password), salt, iterations);
    return 'pbkdf2-sha256\$$iterations\$${base64Url.encode(salt)}'
        '\$${base64Url.encode(key)}';
  }

  bool verify(String password, String stored) {
    final parts = stored.split(r'$');
    if (parts.length != 4 || parts[0] != 'pbkdf2-sha256') return false;
    final rounds = int.tryParse(parts[1]);
    if (rounds == null || rounds < 1) return false;
    final salt = base64Url.decode(parts[2]);
    final expected = base64Url.decode(parts[3]);
    final actual = _pbkdf2(utf8.encode(password), salt, rounds);
    return constantTimeEquals(actual, expected);
  }

  /// SHA-256 шығысы 32 байт — бір блок жеткілікті.
  static List<int> _pbkdf2(List<int> password, List<int> salt, int rounds) {
    final hmac = Hmac(sha256, password);
    var u = hmac.convert([...salt, 0, 0, 0, 1]).bytes;
    final result = Uint8List.fromList(u);
    for (var i = 1; i < rounds; i++) {
      u = hmac.convert(u).bytes;
      for (var j = 0; j < result.length; j++) {
        result[j] ^= u[j];
      }
    }
    return result;
  }

  static bool constantTimeEquals(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    var diff = 0;
    for (var i = 0; i < a.length; i++) {
      diff |= a[i] ^ b[i];
    }
    return diff == 0;
  }
}
