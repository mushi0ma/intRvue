import 'package:sqflite/sqflite.dart';

import '../../core/log.dart';
import 'app_database.dart';
import 'db_schema.dart';
import 'mappers.dart';

/// SQLite ↔ синхрондау суреті. Пішімі серверде де бірдей: кесте жолдары,
/// уақыт миллисекундпен, тізімдер JSON мәтін түрінде.
class SyncStore {
  SyncStore(this._database);

  final AppDatabase _database;

  Database get _db => _database.db;

  /// Пайдаланушының барлық өз деректері: қосқан тақырыптары, сессиялары,
  /// таңдаулылары және жойылғандар журналы.
  Future<Map<String, Object?>> export(int userId) async {
    final topics = await _db.query(
      DbSchema.topics,
      columns: _topicColumns,
      where: 'owner_id = ?',
      whereArgs: [userId],
    );
    final questions = await _db.rawQuery(
      'SELECT q.* FROM ${DbSchema.questions} q '
      'JOIN ${DbSchema.topics} t ON t.id = q.topic_id WHERE t.owner_id = ?',
      [userId],
    );
    final sessions = await _db.query(
      DbSchema.sessions,
      where: 'user_id = ?',
      whereArgs: [userId],
    );
    final answers = await _db.rawQuery(
      'SELECT a.* FROM ${DbSchema.answers} a '
      'JOIN ${DbSchema.sessions} s ON s.id = a.session_id WHERE s.user_id = ?',
      [userId],
    );
    final favorites = await _db.query(
      DbSchema.favorites,
      columns: ['topic_id', 'created_at'],
      where: 'user_id = ?',
      whereArgs: [userId],
    );
    final deleted = await _db.query(
      DbSchema.syncDeletions,
      where: 'user_id = ?',
      whereArgs: [userId],
    );

    List<Map<String, Object?>> children(
      List<Map<String, Object?>> rows,
      String key,
      Object? id,
      Set<String> drop,
    ) => [
      for (final r in rows)
        if (r[key] == id)
          {
            for (final e in r.entries)
              if (!drop.contains(e.key)) e.key: e.value,
          },
    ];

    return {
      'topics': [
        for (final t in topics)
          {
            ...t,
            'questions': children(questions, 'topic_id', t['id'], {'topic_id'}),
          },
      ],
      'sessions': [
        for (final s in sessions)
          {
            for (final e in s.entries)
              if (e.key != 'user_id') e.key: e.value,
            'answers': children(answers, 'session_id', s['id'], {
              'id',
              'session_id',
            }),
          },
      ],
      'favorites': favorites,
      'deleted': [
        for (final d in deleted)
          {
            'entity': d['entity'],
            'id': d['entity_id'],
            'deleted_at': d['deleted_at'],
          },
      ],
    };
  }

  /// Сервердің біріктірілген суретін жергілікті қорға жазады. Әр жазба
  /// жеке тексеріледі: бұзылған жазба қалғандарына кедергі болмайды.
  /// Қайтарады: өзгерген жазбалар саны.
  Future<int> apply(int userId, Map<String, Object?> snapshot) {
    return _db.transaction((txn) async {
      // Синхрондау кезінде жойылғандар әлі серверге жетпеген: оларды
      // сервердің суретінен қайта тірілтпейміз.
      final pending = {
        for (final r in await txn.query(
          DbSchema.syncDeletions,
          where: 'user_id = ?',
          whereArgs: [userId],
        ))
          '${r['entity']}:${r['entity_id']}',
      };
      bool isPending(String entity, Object? id) =>
          pending.contains('$entity:$id');

      var changed = 0;
      for (final d in _list(snapshot['deleted'])) {
        changed += await _guard(txn, () => _applyDeletion(txn, userId, d));
      }
      for (final t in _list(snapshot['topics'])) {
        if (isPending('topic', t['id'])) continue;
        changed += await _guard(txn, () => _applyTopic(txn, userId, t));
      }
      for (final s in _list(snapshot['sessions'])) {
        if (isPending('session', s['id'])) continue;
        changed += await _guard(txn, () => _applySession(txn, userId, s));
      }
      for (final f in _list(snapshot['favorites'])) {
        if (isPending('favorite', f['topic_id'])) continue;
        changed += await _guard(
          txn,
          () => txn
              .rawInsert(
                'INSERT OR IGNORE INTO ${DbSchema.favorites} '
                '(user_id, topic_id, created_at) '
                'SELECT ?, ?, ? WHERE EXISTS '
                '(SELECT 1 FROM ${DbSchema.topics} WHERE id = ?)',
                [userId, f['topic_id'], f['created_at'], f['topic_id']],
              )
              .then((id) => id > 0 ? 1 : 0),
        );
      }
      return changed;
    });
  }

  /// Серверге жеткен жою жазбаларын тазалау.
  Future<void> clearDeletions(int userId, int upTo) => _db.delete(
    DbSchema.syncDeletions,
    where: 'user_id = ? AND deleted_at <= ?',
    whereArgs: [userId, upTo],
  );

  Future<int> _applyDeletion(
    Transaction txn,
    int userId,
    Map<String, Object?> d,
  ) {
    final id = d['id'];
    final at = d['deleted_at'];
    return switch (d['entity']) {
      'topic' => txn.delete(
        DbSchema.topics,
        where: 'id = ? AND owner_id = ? AND updated_at <= ?',
        whereArgs: [id, userId, at],
      ),
      'session' => txn.delete(
        DbSchema.sessions,
        where: 'id = ? AND user_id = ?',
        whereArgs: [id, userId],
      ),
      _ => txn.delete(
        DbSchema.favorites,
        where: 'topic_id = ? AND user_id = ? AND created_at <= ?',
        whereArgs: [id, userId, at],
      ),
    };
  }

  Future<int> _applyTopic(
    Transaction txn,
    int userId,
    Map<String, Object?> t,
  ) async {
    final existing = await txn.query(
      DbSchema.topics,
      columns: ['owner_id', 'updated_at'],
      where: 'id = ?',
      whereArgs: [t['id']],
    );
    if (existing.isNotEmpty) {
      // Кірістірілген немесе басқа пайдаланушының тақырыбын өзгертпейміз.
      if (existing.first['owner_id'] != userId) return 0;
      if ((existing.first['updated_at']! as int) >= (t['updated_at']! as int)) {
        return 0;
      }
    }
    // Іздеу бағандарын қайта есептеу үшін модель арқылы өткіземіз.
    final topic = Mappers.topic({...t, 'owner_id': userId});
    final row = Mappers.topicRow(topic);
    if (existing.isEmpty) {
      await txn.insert(DbSchema.topics, row);
    } else {
      await txn.update(
        DbSchema.topics,
        row,
        where: 'id = ?',
        whereArgs: [t['id']],
      );
    }
    final keep = <Object?>{};
    for (final q in _list(t['questions'])) {
      keep.add(q['id']);
      final row = {..._only(q, _questionColumns), 'topic_id': t['id']};
      final n = await txn.update(
        DbSchema.questions,
        row,
        where: 'id = ?',
        whereArgs: [q['id']],
      );
      if (n == 0) await txn.insert(DbSchema.questions, row);
    }
    final old = await txn.query(
      DbSchema.questions,
      columns: ['id'],
      where: 'topic_id = ?',
      whereArgs: [t['id']],
    );
    for (final r in old.where((r) => !keep.contains(r['id']))) {
      // Сессияда қолданылған сұрақ қалады (ON DELETE RESTRICT).
      await _guard(
        txn,
        () => txn.delete(
          DbSchema.questions,
          where: 'id = ?',
          whereArgs: [r['id']],
        ),
      );
    }
    return 1;
  }

  Future<int> _applySession(
    Transaction txn,
    int userId,
    Map<String, Object?> s,
  ) async {
    final existing = await txn.query(
      DbSchema.sessions,
      columns: ['user_id', 'updated_at'],
      where: 'id = ?',
      whereArgs: [s['id']],
    );
    var changed = 0;
    final row = {..._only(s, _sessionColumns), 'user_id': userId};
    if (existing.isEmpty) {
      await txn.insert(DbSchema.sessions, row);
      changed = 1;
    } else {
      if (existing.first['user_id'] != userId) return 0;
      if ((existing.first['updated_at']! as int) < (s['updated_at']! as int)) {
        await txn.update(
          DbSchema.sessions,
          {
            'current_index': s['current_index'],
            'finished': s['finished'],
            'updated_at': s['updated_at'],
          },
          where: 'id = ?',
          whereArgs: [s['id']],
        );
        changed = 1;
      }
    }
    for (final a in _list(s['answers'])) {
      final row = {..._only(a, _answerColumns), 'session_id': s['id']};
      final local = await txn.query(
        DbSchema.answers,
        columns: ['updated_at'],
        where: 'session_id = ? AND position = ?',
        whereArgs: [s['id'], a['position']],
      );
      if (local.isEmpty) {
        await txn.insert(DbSchema.answers, row);
        changed = 1;
      } else if ((local.first['updated_at']! as int) <
          (a['updated_at']! as int)) {
        await txn.update(
          DbSchema.answers,
          row,
          where: 'session_id = ? AND position = ?',
          whereArgs: [s['id'], a['position']],
        );
        changed = 1;
      }
    }
    return changed;
  }

  /// Бір жазбаның қатесі (мысалы, құрылғыда жоқ сұраққа сілтеме) бүкіл
  /// синхрондауды тоқтатпайды. Savepoint сол жазбаның жартылай өзгерісін
  /// кері қайтарады.
  static Future<int> _guard(
    Transaction txn,
    Future<int> Function() body,
  ) async {
    await txn.execute('SAVEPOINT sync_record');
    try {
      final n = await body();
      await txn.execute('RELEASE sync_record');
      return n;
    } on DatabaseException catch (e) {
      Log.warn('sync', 'skipped record: $e');
      await txn.execute('ROLLBACK TO sync_record');
      await txn.execute('RELEASE sync_record');
      return 0;
    }
  }

  static List<Map<String, Object?>> _list(Object? v) => [
    if (v is List)
      for (final e in v)
        if (e is Map) e.cast<String, Object?>(),
  ];

  static Map<String, Object?> _only(
    Map<String, Object?> m,
    List<String> keys,
  ) => {for (final k in keys) k: m[k]};

  static const _topicColumns = [
    'id',
    'title',
    'summary',
    'direction',
    'level',
    'description',
    'review_points',
    'sample_question',
    'created_at',
    'updated_at',
  ];
  static const _questionColumns = [
    'id',
    'position',
    'text',
    'hint',
    'model_answer',
    'concepts',
  ];
  static const _sessionColumns = [
    'id',
    'direction',
    'level',
    'language',
    'topic_ids',
    'started_at',
    'current_index',
    'finished',
    'updated_at',
  ];
  static const _answerColumns = [
    'position',
    'question_id',
    'text',
    'status',
    'correctness',
    'completeness',
    'clarity',
    'headline',
    'advice',
    'evidence',
    'missing',
    'disputed',
    'dispute_reason',
    'dispute_comment',
    'updated_at',
  ];
}
