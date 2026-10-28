import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

/// Пароль ашық түрде сақталмайды: кездейсоқ тұз + SHA-256.
abstract final class PasswordHasher {
  static final _random = Random.secure();

  static String newSalt() =>
      base64Url.encode(List<int>.generate(16, (_) => _random.nextInt(256)));

  static String hash(String password, String salt) =>
      sha256.convert(utf8.encode('$salt:$password')).toString();

  static bool verify(String password, String salt, String expected) =>
      hash(password, salt) == expected;
}
