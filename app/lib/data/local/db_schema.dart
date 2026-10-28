/// SQLite схемасы: алты байланысқан кесте.
///
/// ```
/// users 1──* sessions 1──* answers *──1 questions *──1 topics
///   │                                                    │
///   ├──────────────* favorites *─────────────────────────┤
///   └──────────────* topics (owner_id: пайдаланушы қосқан тақырып)
/// ```
abstract final class DbSchema {
  /// 2 — answers кестесіне бағаға пікірдің себебі мен мәтіні қосылды.
  /// 3 — парольді қалпына келтіру токендері (password_resets).
  static const version = 3;
  static const fileName = 'intrvue.db';

  static const users = 'users';
  static const topics = 'topics';
  static const questions = 'questions';
  static const sessions = 'sessions';
  static const answers = 'answers';
  static const favorites = 'favorites';
  static const passwordResets = 'password_resets';

  // Бір реттік сілтеме: 15 минут жарамды, қолданылғаннан кейін used = 1.
  static const _passwordResetsTable =
      '''
    CREATE TABLE $passwordResets (
      token      TEXT    PRIMARY KEY,
      user_id    INTEGER NOT NULL REFERENCES $users(id) ON DELETE CASCADE,
      expires_at INTEGER NOT NULL,
      used       INTEGER NOT NULL DEFAULT 0
    )''';

  static const create = [
    '''
    CREATE TABLE $users (
      id                 INTEGER PRIMARY KEY AUTOINCREMENT,
      name               TEXT    NOT NULL,
      email              TEXT    NOT NULL UNIQUE,
      password_hash      TEXT    NOT NULL,
      password_salt      TEXT    NOT NULL,
      direction          TEXT    NOT NULL,
      level              TEXT    NOT NULL,
      interview_language TEXT    NOT NULL,
      created_at         INTEGER NOT NULL
    )''',
    // owner_id NULL — кірістірілген каталог, әйтпесе пайдаланушы қосқан тақырып.
    '''
    CREATE TABLE $topics (
      id              TEXT    PRIMARY KEY,
      owner_id        INTEGER REFERENCES $users(id) ON DELETE CASCADE,
      title           TEXT    NOT NULL,
      summary         TEXT    NOT NULL,
      direction       TEXT    NOT NULL,
      level           TEXT    NOT NULL,
      description     TEXT    NOT NULL,
      review_points   TEXT    NOT NULL,
      sample_question TEXT    NOT NULL,
      search_text     TEXT    NOT NULL,
      title_sort      TEXT    NOT NULL,
      created_at      INTEGER NOT NULL,
      updated_at      INTEGER NOT NULL
    )''',
    'CREATE INDEX idx_topics_owner ON $topics(owner_id)',
    'CREATE INDEX idx_topics_direction_level ON $topics(direction, level)',
    '''
    CREATE TABLE $questions (
      id           TEXT    PRIMARY KEY,
      topic_id     TEXT    NOT NULL REFERENCES $topics(id) ON DELETE CASCADE,
      position     INTEGER NOT NULL,
      text         TEXT    NOT NULL,
      hint         TEXT    NOT NULL,
      model_answer TEXT    NOT NULL,
      concepts     TEXT    NOT NULL
    )''',
    'CREATE INDEX idx_questions_topic ON $questions(topic_id, position)',
    '''
    CREATE TABLE $sessions (
      id            TEXT    PRIMARY KEY,
      user_id       INTEGER NOT NULL REFERENCES $users(id) ON DELETE CASCADE,
      direction     TEXT    NOT NULL,
      level         TEXT    NOT NULL,
      language      TEXT    NOT NULL,
      topic_ids     TEXT    NOT NULL,
      started_at    INTEGER NOT NULL,
      current_index INTEGER NOT NULL DEFAULT 0,
      finished      INTEGER NOT NULL DEFAULT 0
    )''',
    'CREATE INDEX idx_sessions_user ON $sessions(user_id, started_at)',
    // Сессияда қолданылған сұрақты жоюға болмайды (ON DELETE RESTRICT):
    // әйтпесе бұрынғы нәтижелер бұзылады.
    '''
    CREATE TABLE $answers (
      id            INTEGER PRIMARY KEY AUTOINCREMENT,
      session_id    TEXT    NOT NULL REFERENCES $sessions(id) ON DELETE CASCADE,
      question_id   TEXT    NOT NULL REFERENCES $questions(id) ON DELETE RESTRICT,
      position      INTEGER NOT NULL,
      text          TEXT    NOT NULL DEFAULT '',
      status        TEXT    NOT NULL,
      correctness   INTEGER,
      completeness  INTEGER,
      clarity       INTEGER,
      headline      TEXT,
      advice        TEXT,
      evidence      TEXT,
      missing       TEXT,
      disputed      INTEGER NOT NULL DEFAULT 0,
      dispute_reason  TEXT,
      dispute_comment TEXT,
      UNIQUE (session_id, position)
    )''',
    'CREATE INDEX idx_answers_question ON $answers(question_id)',
    '''
    CREATE TABLE $favorites (
      user_id    INTEGER NOT NULL REFERENCES $users(id) ON DELETE CASCADE,
      topic_id   TEXT    NOT NULL REFERENCES $topics(id) ON DELETE CASCADE,
      created_at INTEGER NOT NULL,
      PRIMARY KEY (user_id, topic_id)
    )''',
    _passwordResetsTable,
  ];

  /// Ескі нұсқадан жаңартқанда орындалатын өзгерістер.
  static const migrations = <int, List<String>>{
    2: [
      'ALTER TABLE $answers ADD COLUMN dispute_reason TEXT',
      'ALTER TABLE $answers ADD COLUMN dispute_comment TEXT',
    ],
    3: [_passwordResetsTable],
  };
}
