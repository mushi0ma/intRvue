import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';

import '../../core/constants/app_strings.dart';

/// Пайдаланушыға көрсетуге болатын қате: мәтіні қазақша.
class AppException implements Exception {
  const AppException(this.message, [this.cause]);

  final String message;
  final Object? cause;

  @override
  String toString() => 'AppException: $message ($cause)';
}

/// Деректер қорына жүгінуді орап, SQLite қатесін түсінікті хабарламаға
/// айналдырады. Репозиторийдің барлық әдісі осы арқылы өтеді.
Future<T> dbGuard<T>(
  Future<T> Function() body, {
  String? unique,
  String? foreignKey,
}) async {
  try {
    return await body();
  } on AppException {
    rethrow;
  } on DatabaseException catch (e, stack) {
    debugPrint('SQLite: $e\n$stack');
    final text = e.toString();
    if (e.isUniqueConstraintError()) {
      throw AppException(unique ?? S.dbDuplicate, e);
    }
    if (text.contains('FOREIGN KEY')) {
      throw AppException(foreignKey ?? S.dbInUse, e);
    }
    if (e.isDatabaseClosedError()) throw AppException(S.dbClosed, e);
    throw AppException(S.dbGeneric, e);
  } catch (e, stack) {
    debugPrint('Data error: $e\n$stack');
    throw AppException(S.dbGeneric, e);
  }
}
