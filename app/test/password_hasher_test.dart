// Аудит (№8): жергілікті пароль — PBKDF2-HMAC-SHA256. Стандарт векторлары,
// нақты 120 000 итерация (isolate), ескі SHA-256 хэшінің тексерілуі және
// кіргенде жаңа пішімге көшуі.
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intrvue/app/bootstrap.dart';
import 'package:intrvue/data/local/db_schema.dart';
import 'package:intrvue/data/local/password_hasher.dart';
import 'package:intrvue/data/repositories/auth_repository.dart';
import 'package:intrvue/data/services/reminder_scheduler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  test('PBKDF2-HMAC-SHA256 стандарт векторлары', () async {
    // RFC 7914 §11 (c=1) және кең тараған c=4096 векторы, алғашқы 32 байт.
    expect(
      await PasswordHasher.verify(
        'passwd',
        'salt',
        'pbkdf2-sha256\$1\$'
            '55ac046e56e3089fec1691c22544b605f94185216dde0465e68b9d57c20dacbc',
      ),
      isTrue,
    );
    expect(
      await PasswordHasher.verify(
        'password',
        'salt',
        'pbkdf2-sha256\$4096\$'
            'c5e478d59288c841aa530db6845c4c8d962893a001ce4e11a4963873aa98134a',
      ),
      isTrue,
    );
  });

  test('нақты 120 000 итерация: isolate-та, дұрыс/қате пароль', () async {
    final saved = PasswordHasher.iterations;
    PasswordHasher.iterations = 120000;
    addTearDown(() => PasswordHasher.iterations = saved);

    final salt = PasswordHasher.newSalt();
    final hash = await PasswordHasher.hash('qwerty2026', salt);
    expect(hash, startsWith(r'pbkdf2-sha256$120000$'));
    expect(hash, isNot(contains('qwerty2026')));
    expect(await PasswordHasher.verify('qwerty2026', salt, hash), isTrue);
    expect(await PasswordHasher.verify('qwerty2027', salt, hash), isFalse);
    expect(await PasswordHasher.verify('qwerty2026', 'other', hash), isFalse);
    expect(PasswordHasher.needsRehash(hash), isFalse);
  });

  test('бұзылған хэш — false, exception жоқ', () async {
    for (final bad in ['', r'pbkdf2-sha256$x$00', r'pbkdf2-sha256$0$00']) {
      expect(await PasswordHasher.verify('a', 'b', bad), isFalse);
    }
  });

  test('ескі SHA-256 хэші: кіру өтеді және PBKDF2-ге көшеді', () async {
    SharedPreferences.setMockInitialValues({});
    final s = await AppServices.start(
      factory: databaseFactoryFfiNoIsolate,
      databasePath: inMemoryDatabasePath,
      reminders: const NoopReminderScheduler(),
    );
    addTearDown(s.dispose);
    const email = 'legacy@example.com';
    expect(
      await s.auth.register(name: 'Ескі', email: email, password: 'old2026pw'),
      isNull,
    );
    await s.auth.logout();

    // v1–v3 пішімі: тұз + бір рет SHA-256.
    const salt = 'legacy-salt';
    final legacy = sha256.convert(utf8.encode('$salt:old2026pw')).toString();
    final db = s.database.db;
    await db.update(
      DbSchema.users,
      {'password_hash': legacy, 'password_salt': salt},
      where: 'email = ?',
      whereArgs: [email],
    );
    expect(PasswordHasher.needsRehash(legacy), isTrue);

    expect(
      await s.auth.login(email, 'wrong-pass1'),
      AuthError.wrongCredentials,
    );
    // Қате пароль хэшті өзгертпейді.
    var row = (await db.query(
      DbSchema.users,
      where: 'email = ?',
      whereArgs: [email],
    )).single;
    expect(row['password_hash'], legacy);

    expect(await s.auth.login(email, 'old2026pw'), isNull);
    row = (await db.query(
      DbSchema.users,
      where: 'email = ?',
      whereArgs: [email],
    )).single;
    expect(row['password_hash'], startsWith(r'pbkdf2-sha256$'));
    expect(row['password_salt'], isNot(salt));

    // Көшкеннен кейін де сол парольмен кіреді.
    await s.auth.logout();
    expect(await s.auth.login(email, 'old2026pw'), isNull);
  });
}
