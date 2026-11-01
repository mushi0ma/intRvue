import 'dart:async';

import 'package:intrvue/data/local/password_hasher.dart';

/// Барлық тестке ортақ: PBKDF2 итерациясы азайтылады (әр тіркелу/кіру
/// бірнеше миллисекунд). Нақты 120 000 итерация — password_hasher_test-те.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  PasswordHasher.iterations = 1000;
  await testMain();
}
