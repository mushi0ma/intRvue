import 'package:postgres/postgres.dart';

/// PostgreSQL схемасы. Құрылғыдағы SQLite кестелерінің серверлік көшірмесі:
/// әр жол аккаунтқа (account_id) тиесілі, уақыт — timestamptz, тізімдер — jsonb.
///
/// ```
/// accounts 1──* auth_tokens
///    ├──* topics 1──* questions
///    ├──* sessions 1──* answers
///    ├──* favorites
///    └──* tombstones   (басқа құрылғыда жойылған жазбалар)
/// ```
///
/// Кірістірілген каталог серверде сақталмайды — ол әр құрылғыда бар.
abstract final class Schema {
  static const migrations = <int, List<String>>{
    1: [
      'CREATE EXTENSION IF NOT EXISTS citext',
      '''
      CREATE TABLE accounts (
        id                 BIGSERIAL   PRIMARY KEY,
        email              CITEXT      NOT NULL UNIQUE,
        name               TEXT        NOT NULL,
        password_hash      TEXT        NOT NULL,
        direction          TEXT        NOT NULL,
        level              TEXT        NOT NULL,
        interview_language TEXT        NOT NULL,
        created_at         TIMESTAMPTZ NOT NULL DEFAULT now(),
        updated_at         TIMESTAMPTZ NOT NULL DEFAULT now()
      )''',
      // Токен ашық түрде сақталмайды — тек SHA-256 хэші.
      '''
      CREATE TABLE auth_tokens (
        token_hash TEXT        PRIMARY KEY,
        account_id BIGINT      NOT NULL REFERENCES accounts(id) ON DELETE CASCADE,
        created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
        expires_at TIMESTAMPTZ NOT NULL
      )''',
      'CREATE INDEX idx_auth_tokens_account ON auth_tokens(account_id)',
      '''
      CREATE TABLE topics (
        account_id      BIGINT      NOT NULL REFERENCES accounts(id) ON DELETE CASCADE,
        id              TEXT        NOT NULL,
        title           TEXT        NOT NULL,
        summary         TEXT        NOT NULL,
        direction       TEXT        NOT NULL,
        level           TEXT        NOT NULL,
        description     TEXT        NOT NULL,
        review_points   JSONB       NOT NULL,
        sample_question TEXT        NOT NULL,
        created_at      TIMESTAMPTZ NOT NULL,
        updated_at      TIMESTAMPTZ NOT NULL,
        PRIMARY KEY (account_id, id)
      )''',
      '''
      CREATE TABLE questions (
        account_id   BIGINT  NOT NULL,
        id           TEXT    NOT NULL,
        topic_id     TEXT    NOT NULL,
        position     INTEGER NOT NULL,
        text         TEXT    NOT NULL,
        hint         TEXT    NOT NULL,
        model_answer TEXT    NOT NULL,
        concepts     JSONB   NOT NULL,
        PRIMARY KEY (account_id, id),
        FOREIGN KEY (account_id, topic_id)
          REFERENCES topics(account_id, id) ON DELETE CASCADE
      )''',
      '''
      CREATE TABLE sessions (
        account_id    BIGINT      NOT NULL REFERENCES accounts(id) ON DELETE CASCADE,
        id            TEXT        NOT NULL,
        direction     TEXT        NOT NULL,
        level         TEXT        NOT NULL,
        language      TEXT        NOT NULL,
        topic_ids     JSONB       NOT NULL,
        started_at    TIMESTAMPTZ NOT NULL,
        current_index INTEGER     NOT NULL,
        finished      BOOLEAN     NOT NULL,
        updated_at    TIMESTAMPTZ NOT NULL,
        PRIMARY KEY (account_id, id)
      )''',
      '''
      CREATE TABLE answers (
        account_id      BIGINT      NOT NULL,
        session_id      TEXT        NOT NULL,
        position        INTEGER     NOT NULL,
        question_id     TEXT        NOT NULL,
        text            TEXT        NOT NULL,
        status          TEXT        NOT NULL,
        correctness     SMALLINT,
        completeness    SMALLINT,
        clarity         SMALLINT,
        headline        TEXT,
        advice          TEXT,
        evidence        TEXT,
        missing         JSONB,
        disputed        BOOLEAN     NOT NULL DEFAULT false,
        dispute_reason  TEXT,
        dispute_comment TEXT,
        updated_at      TIMESTAMPTZ NOT NULL,
        PRIMARY KEY (account_id, session_id, position),
        FOREIGN KEY (account_id, session_id)
          REFERENCES sessions(account_id, id) ON DELETE CASCADE
      )''',
      '''
      CREATE TABLE favorites (
        account_id BIGINT      NOT NULL REFERENCES accounts(id) ON DELETE CASCADE,
        topic_id   TEXT        NOT NULL,
        created_at TIMESTAMPTZ NOT NULL,
        PRIMARY KEY (account_id, topic_id)
      )''',
      // Жойылғанын басқа құрылғыларға жеткізу үшін: entity — topic,
      // session немесе favorite.
      '''
      CREATE TABLE tombstones (
        account_id BIGINT      NOT NULL REFERENCES accounts(id) ON DELETE CASCADE,
        entity     TEXT        NOT NULL CHECK (entity IN ('topic', 'session', 'favorite')),
        entity_id  TEXT        NOT NULL,
        deleted_at TIMESTAMPTZ NOT NULL,
        PRIMARY KEY (account_id, entity, entity_id)
      )''',
    ],
  };

  static int get latest => migrations.keys.reduce((a, b) => a > b ? a : b);

  /// Қолданылмаған көшірулерді ретімен орындайды. Бірнеше сервер бір уақытта
  /// іске қосылса, advisory lock біреуін ғана жібереді.
  static Future<int> migrate(SessionExecutor db) => db.runTx((tx) async {
    await tx.execute('SELECT pg_advisory_xact_lock(7302026)');
    await tx.execute('''
      CREATE TABLE IF NOT EXISTS schema_migrations (
        version    INTEGER     PRIMARY KEY,
        applied_at TIMESTAMPTZ NOT NULL DEFAULT now()
      )''');
    final rows = await tx.execute(
      'SELECT coalesce(max(version), 0) FROM schema_migrations',
    );
    final current = rows.first.first! as int;
    for (var v = current + 1; v <= latest; v++) {
      for (final statement in migrations[v] ?? const <String>[]) {
        await tx.execute(statement);
      }
      await tx.execute(
        Sql.named('INSERT INTO schema_migrations (version) VALUES (@v)'),
        parameters: {'v': v},
      );
    }
    return latest;
  });
}
