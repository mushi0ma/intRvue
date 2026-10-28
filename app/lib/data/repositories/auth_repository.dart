import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

import '../../core/constants/app_strings.dart';
import '../local/app_database.dart';
import '../local/db_errors.dart';
import '../local/db_schema.dart';
import '../local/mappers.dart';
import '../local/password_hasher.dart';
import '../models/user_profile.dart';
import 'user_scoped.dart';

enum AuthError { wrongCredentials, emailTaken, wrongPassword, resetLinkInvalid }

/// Email арқылы кіру. Аккаунттар `users` кестесінде, пароль — тұзды хэш.
/// Кірген пайдаланушының id-і SharedPreferences-те сақталады.
class AuthRepository extends ChangeNotifier {
  AuthRepository(this._database, this._prefs, {List<UserScoped>? scoped})
    : _scoped = scoped ?? const [];

  static const demoEmail = AppDatabase.demoEmail;
  static const demoPassword = AppDatabase.demoPassword;

  static const _currentKey = 'auth.userId';
  static const _onboardingKey = 'onboarding.seen';

  final AppDatabase _database;
  final SharedPreferences _prefs;
  final List<UserScoped> _scoped;
  UserProfile? _user;

  Database get _db => _database.db;

  UserProfile? get user => _user;
  bool get isLoggedIn => _user != null;
  bool get onboardingSeen => _prefs.getBool(_onboardingKey) ?? false;

  /// Қосымша іске қосылғанда: соңғы кірген пайдаланушыны қалпына келтіру.
  Future<void> init() async {
    final id = _prefs.getInt(_currentKey);
    UserProfile? user;
    if (id != null) {
      final rows = await dbGuard(
        () => _db.query(DbSchema.users, where: 'id = ?', whereArgs: [id]),
      );
      if (rows.isNotEmpty) user = Mappers.user(rows.first);
    }
    await _switchTo(user);
  }

  Future<void> _switchTo(UserProfile? user) async {
    _user = user;
    if (user == null) {
      await _prefs.remove(_currentKey);
    } else {
      await _prefs.setInt(_currentKey, user.id!);
    }
    for (final repo in _scoped) {
      await repo.loadFor(user);
    }
    notifyListeners();
  }

  Future<void> completeOnboarding() async {
    await _prefs.setBool(_onboardingKey, true);
    notifyListeners();
  }

  Future<Map<String, Object?>?> _row(String email) async {
    final rows = await dbGuard(
      () => _db.query(
        DbSchema.users,
        where: 'email = ?',
        whereArgs: [email.trim().toLowerCase()],
      ),
    );
    return rows.isEmpty ? null : rows.first;
  }

  Future<AuthError?> login(String email, String password) async {
    final row = await _row(email);
    if (row == null ||
        !PasswordHasher.verify(
          password,
          row['password_salt']! as String,
          row['password_hash']! as String,
        )) {
      return AuthError.wrongCredentials;
    }
    await _switchTo(Mappers.user(row));
    return null;
  }

  Future<AuthError?> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final salt = PasswordHasher.newSalt();
    final profile = UserProfile(name: name.trim(), email: email.trim());
    try {
      final id = await dbGuard(
        () => _db.insert(DbSchema.users, {
          ...Mappers.userProfileRow(profile),
          'password_hash': PasswordHasher.hash(password, salt),
          'password_salt': salt,
          'created_at': Mappers.ms(DateTime.now()),
        }),
        unique: S.emailTaken,
      );
      final rows = await _db.query(
        DbSchema.users,
        where: 'id = ?',
        whereArgs: [id],
      );
      await _switchTo(Mappers.user(rows.first));
      return null;
    } on AppException catch (e) {
      if (e.message == S.emailTaken) return AuthError.emailTaken;
      rethrow;
    }
  }

  static const resetLinkLifetime = Duration(minutes: 15);

  /// Бір реттік қалпына келтіру сілтемесін жасайды. Пошта сервері әзірге
  /// жоқ, сондықтан сілтеме қайтарылады (демо). Белгісіз email-ге де
  /// бірдей жауап береміз — аккаунттың бар-жоғы ашылмайды.
  Future<Uri?> requestPasswordReset(String email) async {
    final row = await _row(email);
    if (row == null) return null;
    final token = PasswordHasher.newSalt();
    await dbGuard(
      () => _db.insert(DbSchema.passwordResets, {
        'token': token,
        'user_id': row['id'],
        'expires_at': Mappers.ms(DateTime.now().add(resetLinkLifetime)),
      }),
    );
    return Uri(
      scheme: 'intrvue',
      host: 'app',
      path: '/reset-password',
      queryParameters: {'token': token},
    );
  }

  /// Сілтеме арқылы жаңа пароль орнату. Сілтеме бір рет қана жарамды.
  Future<AuthError?> resetPassword(String token, String newPassword) async {
    final rows = await dbGuard(
      () => _db.query(
        DbSchema.passwordResets,
        where: 'token = ? AND used = 0 AND expires_at > ?',
        whereArgs: [token, Mappers.ms(DateTime.now())],
      ),
    );
    if (rows.isEmpty) return AuthError.resetLinkInvalid;
    final salt = PasswordHasher.newSalt();
    await dbGuard(
      () => _db.transaction((txn) async {
        await txn.update(
          DbSchema.users,
          {
            'password_hash': PasswordHasher.hash(newPassword, salt),
            'password_salt': salt,
          },
          where: 'id = ?',
          whereArgs: [rows.first['user_id']],
        );
        await txn.update(
          DbSchema.passwordResets,
          {'used': 1},
          where: 'token = ?',
          whereArgs: [token],
        );
      }),
    );
    return null;
  }

  /// Update: профильді өзгерту.
  Future<void> updateProfile(UserProfile profile) async {
    final current = _user;
    if (current == null) return;
    await dbGuard(
      () => _db.update(
        DbSchema.users,
        Mappers.userProfileRow(profile),
        where: 'id = ?',
        whereArgs: [current.id],
      ),
    );
    _user = profile;
    notifyListeners();
  }

  Future<void> logout() => _switchTo(null);

  /// Delete: аккаунт және оған тиесілі барлық жазба (CASCADE).
  Future<AuthError?> deleteAccount(String password) async {
    final current = _user;
    if (current == null) return null;
    final row = await _row(current.email);
    if (row == null ||
        !PasswordHasher.verify(
          password,
          row['password_salt']! as String,
          row['password_hash']! as String,
        )) {
      return AuthError.wrongPassword;
    }
    await dbGuard(
      () =>
          _db.delete(DbSchema.users, where: 'id = ?', whereArgs: [current.id]),
    );
    await _switchTo(null);
    return null;
  }
}
