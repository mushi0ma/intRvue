import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:postgres/postgres.dart';

import 'errors.dart';
import 'passwords.dart';

/// Аккаунттар мен Bearer токендері.
class AuthService {
  AuthService(
    this._db, {
    Passwords? passwords,
    this.tokenLifetime = const Duration(days: 30),
  }) : _passwords = passwords ?? const Passwords();

  final Pool _db;
  final Passwords _passwords;
  final Duration tokenLifetime;

  static final _email = RegExp(r'^[\w.+-]+@[\w-]+(\.[\w-]+)*\.[a-zA-Z]{2,}$');
  static const directions = {'frontend', 'backend', 'mobile', 'qa'};
  static const levels = {'beginner', 'junior', 'middle'};
  static const languages = {'kk', 'ru', 'en'};

  /// Тіркелу: аккаунт жасап, бірден токен береді.
  Future<Map<String, Object?>> register(Map<String, Object?> body) async {
    final email = _checkEmail(body.str('email', max: 254));
    final password = _checkPassword(body.str('password', max: 128));
    final profile = profileFrom(body);
    return _db.runTx((tx) async {
      final exists = await tx.execute(
        Sql.named('SELECT 1 FROM accounts WHERE email = @email'),
        parameters: {'email': email},
      );
      if (exists.isNotEmpty) {
        throw const ApiError(
          409,
          'email_taken',
          'Email is already registered.',
        );
      }
      final rows = await tx.execute(
        Sql.named('''
          INSERT INTO accounts
            (email, name, password_hash, direction, level, interview_language)
          VALUES (@email, @name, @hash, @direction, @level, @language)
          RETURNING id'''),
        parameters: {
          'email': email,
          'hash': _passwords.hash(password),
          ...profile,
        },
      );
      final id = rows.first.first! as int;
      return {
        'token': await _issueToken(tx, id),
        'account': await account(id, tx),
      };
    });
  }

  /// Кіру. Белгісіз email мен қате пароль бірдей жауап береді.
  Future<Map<String, Object?>> login(Map<String, Object?> body) async {
    final email = body.str('email', max: 254).trim().toLowerCase();
    final password = body.str('password', max: 128);
    final rows = await _db.execute(
      Sql.named('SELECT id, password_hash FROM accounts WHERE email = @email'),
      parameters: {'email': email},
    );
    // Аккаунт болмаса да хэш есептеледі — жауап уақыты email-ді ашпайды.
    final stored = rows.isEmpty
        ? _passwords.hash('timing-equalizer')
        : rows.first[1]! as String;
    if (!_passwords.verify(password, stored) || rows.isEmpty) {
      throw const ApiError(
        401,
        'invalid_credentials',
        'Wrong email or password.',
      );
    }
    final id = rows.first[0]! as int;
    return {'token': await _issueToken(_db, id), 'account': await account(id)};
  }

  Future<void> logout(String token) => _db.execute(
    Sql.named('DELETE FROM auth_tokens WHERE token_hash = @h'),
    parameters: {'h': _hashToken(token)},
  );

  /// Токенді тексеріп, аккаунт id-ін қайтарады.
  Future<int> authenticate(String? header) async {
    const prefix = 'Bearer ';
    if (header == null || !header.startsWith(prefix)) {
      throw const ApiError.unauthorized();
    }
    final rows = await _db.execute(
      Sql.named('''
        SELECT account_id FROM auth_tokens
        WHERE token_hash = @h AND expires_at > now()'''),
      parameters: {'h': _hashToken(header.substring(prefix.length).trim())},
    );
    if (rows.isEmpty) throw const ApiError.unauthorized();
    return rows.first.first! as int;
  }

  Future<Map<String, Object?>> account(int id, [Session? session]) async {
    final rows = await (session ?? _db).execute(
      Sql.named('''
        SELECT id, email::text, name, direction, level, interview_language,
               created_at
        FROM accounts WHERE id = @id'''),
      parameters: {'id': id},
    );
    if (rows.isEmpty) throw const ApiError.unauthorized();
    final r = rows.first.toColumnMap();
    return {
      ...r,
      'created_at': (r['created_at']! as DateTime).millisecondsSinceEpoch,
    };
  }

  /// Аккаунт және барлық деректері (CASCADE).
  Future<void> deleteAccount(int id) => _db.execute(
    Sql.named('DELETE FROM accounts WHERE id = @id'),
    parameters: {'id': id},
  );

  /// Профиль өрістері: тіркелуде және синхрондауда бірдей тексеріледі.
  static Map<String, Object?> profileFrom(Map<String, Object?> body) {
    final name = body.str('name', max: 40).trim();
    final direction = body.str('direction', max: 20);
    final level = body.str('level', max: 20);
    final language = body.str('interview_language', max: 5);
    if (name.length < 2 ||
        !directions.contains(direction) ||
        !levels.contains(level) ||
        !languages.contains(language)) {
      throw const ApiError.badRequest('Invalid profile fields.');
    }
    return {
      'name': name,
      'direction': direction,
      'level': level,
      'language': language,
    };
  }

  static String _checkEmail(String raw) {
    final email = raw.trim().toLowerCase();
    if (!_email.hasMatch(email)) {
      throw const ApiError.badRequest('Invalid email.');
    }
    return email;
  }

  static String _checkPassword(String password) {
    if (password.length < 8 ||
        !password.contains(RegExp(r'\d')) ||
        !password.contains(RegExp(r'[^\d\s]'))) {
      throw const ApiError(
        400,
        'weak_password',
        'Password needs 8+ characters with letters and digits.',
      );
    }
    return password;
  }

  Future<String> _issueToken(Session db, int accountId) async {
    final token = base64Url
        .encode(Passwords.randomBytes(32))
        .replaceAll('=', '');
    await db.execute(
      Sql.named('''
        INSERT INTO auth_tokens (token_hash, account_id, expires_at)
        VALUES (@h, @id, @expires)'''),
      parameters: {
        'h': _hashToken(token),
        'id': accountId,
        'expires': DateTime.now().toUtc().add(tokenLifetime),
      },
    );
    return token;
  }

  static String _hashToken(String token) =>
      sha256.convert(utf8.encode(token)).toString();
}
