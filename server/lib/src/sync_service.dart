import 'dart:convert';

import 'package:postgres/postgres.dart';

import 'auth_service.dart';
import 'errors.dart';

/// Құрылғы мен сервер арасындағы синхрондау.
///
/// Клиент өз деректерінің толық суретін (snapshot) және жойылған жазбалар
/// тізімін жібереді. Сервер бір транзакцияда біріктіреді:
/// * жазба деңгейінде «соңғы өзгеріс жеңеді» (updated_at бойынша);
/// * жойылған жазба (tombstone) өзінен ескі өзгерісті қайта тірілтпейді;
/// * таңдаулылар — жиын: қосылған уақыты жойылғаннан кейін болса ғана қалады.
///
/// Жауапта аккаунттың біріктірілген толық суреті қайтады — клиент оны
/// дәл сол ережелермен өз SQLite қорына жазады.
class SyncService {
  SyncService(this._db);

  final Pool _db;

  static const entities = {'topic', 'session', 'favorite'};

  Future<Map<String, Object?>> sync(int account, Map<String, Object?> body) {
    // Тексеру транзакцияға дейін: қате дерек серверге жартылай жазылмайды.
    final profile = body['profile'] is Map
        ? AuthService.profileFrom((body['profile']! as Map).cast())
        : null;
    final deleted = body.objects('deleted', max: 10000);
    final topics = body.objects('topics', max: 1000);
    final sessions = body.objects('sessions', max: 5000);
    final favorites = body.objects('favorites', max: 2000);
    for (final d in deleted) {
      if (!entities.contains(d['entity'])) {
        throw const ApiError.badRequest('Unknown entity in "deleted".');
      }
    }

    return _db.runTx((tx) async {
      final a = {'a': account};
      if (profile != null) {
        await tx.execute(
          Sql.named('''
            UPDATE accounts SET name = @name, direction = @direction,
              level = @level, interview_language = @language, updated_at = now()
            WHERE id = @a'''),
          parameters: {...a, ...profile},
        );
      }
      for (final d in deleted) {
        await _applyDeletion(tx, account, d);
      }
      for (final t in topics) {
        await _upsertTopic(tx, account, t);
      }
      for (final s in sessions) {
        await _upsertSession(tx, account, s);
      }
      for (final f in favorites) {
        await tx.execute(
          Sql.named('''
            INSERT INTO favorites (account_id, topic_id, created_at)
            SELECT @a::bigint, @topic::text, @created::timestamptz
            WHERE NOT EXISTS (
              SELECT 1 FROM tombstones WHERE account_id = @a
                AND entity = 'favorite' AND entity_id = @topic
                AND deleted_at >= @created)
            ON CONFLICT (account_id, topic_id) DO NOTHING'''),
          parameters: {
            ...a,
            'topic': f.str('topic_id', max: 200),
            'created': f.time('created_at'),
          },
        );
      }
      return snapshot(tx, account);
    });
  }

  Future<void> _applyDeletion(
    Session tx,
    int account,
    Map<String, Object?> d,
  ) async {
    final p = {
      'a': account,
      'entity': d['entity'],
      'id': d.str('id', max: 200),
      'at': d.time('deleted_at'),
    };
    await tx.execute(
      Sql.named(
        '''
        INSERT INTO tombstones (account_id, entity, entity_id, deleted_at)
        VALUES (@a, @entity, @id, @at)
        ON CONFLICT (account_id, entity, entity_id) DO UPDATE
          SET deleted_at = GREATEST(tombstones.deleted_at, EXCLUDED.deleted_at)''',
      ),
      parameters: p,
    );
    final sql = switch (d['entity']) {
      'topic' => 'DELETE FROM topics WHERE account_id = @a AND id = @id AND updated_at <= @at',
      'session' => 'DELETE FROM sessions WHERE account_id = @a AND id = @id',
      _ => 'DELETE FROM favorites WHERE account_id = @a AND topic_id = @id AND created_at <= @at',
    };
    p.remove('entity');
    if (d['entity'] == 'session') p.remove('at');
    await tx.execute(Sql.named(sql), parameters: p);
  }

  Future<void> _upsertTopic(
    Session tx,
    int account,
    Map<String, Object?> t,
  ) async {
    final id = t.str('id', max: 200);
    final written = await tx.execute(
      Sql.named('''
        INSERT INTO topics (account_id, id, title, summary, direction, level,
          description, review_points, sample_question, created_at, updated_at)
        SELECT @a::bigint, @id::text, @title::text, @summary::text,
          @direction::text, @level::text, @description::text,
          @review_points::jsonb, @sample_question::text,
          @created::timestamptz, @updated::timestamptz
        WHERE NOT EXISTS (
          SELECT 1 FROM tombstones WHERE account_id = @a AND entity = 'topic'
            AND entity_id = @id AND deleted_at >= @updated)
        ON CONFLICT (account_id, id) DO UPDATE SET
          title = EXCLUDED.title, summary = EXCLUDED.summary,
          direction = EXCLUDED.direction, level = EXCLUDED.level,
          description = EXCLUDED.description,
          review_points = EXCLUDED.review_points,
          sample_question = EXCLUDED.sample_question,
          updated_at = EXCLUDED.updated_at
        WHERE topics.updated_at < EXCLUDED.updated_at
        RETURNING id'''),
      parameters: {
        'a': account,
        'id': id,
        'title': t.str('title', max: 200),
        'summary': t.str('summary', max: 500, allowEmpty: true),
        'direction': t.str('direction', max: 20),
        'level': t.str('level', max: 20),
        'description': t.str('description', allowEmpty: true),
        'review_points': _json(t, 'review_points'),
        'sample_question': t.str('sample_question', allowEmpty: true),
        'created': t.time('created_at'),
        'updated': t.time('updated_at'),
      },
    );
    // Тақырып жаңармаса, оның сұрақтары да ескі нұсқада қалады.
    if (written.isEmpty) return;
    await tx.execute(
      Sql.named(
        'DELETE FROM questions WHERE account_id = @a AND topic_id = @t',
      ),
      parameters: {'a': account, 't': id},
    );
    for (final q in t.objects('questions', max: 200)) {
      await tx.execute(
        Sql.named(
          '''
          INSERT INTO questions (account_id, id, topic_id, position, text,
            hint, model_answer, concepts)
          VALUES (@a, @id, @t, @position, @text, @hint, @model_answer,
            @concepts::jsonb)
          ON CONFLICT (account_id, id) DO UPDATE SET
            topic_id = EXCLUDED.topic_id, position = EXCLUDED.position,
            text = EXCLUDED.text, hint = EXCLUDED.hint,
            model_answer = EXCLUDED.model_answer, concepts = EXCLUDED.concepts''',
        ),
        parameters: {
          'a': account,
          't': id,
          'id': q.str('id', max: 200),
          'position': q.integer('position'),
          'text': q.str('text'),
          'hint': q.str('hint', allowEmpty: true),
          'model_answer': q.str('model_answer', allowEmpty: true),
          'concepts': _json(q, 'concepts'),
        },
      );
    }
  }

  Future<void> _upsertSession(
    Session tx,
    int account,
    Map<String, Object?> s,
  ) async {
    final id = s.str('id', max: 200);
    final written = await tx.execute(
      Sql.named('''
        INSERT INTO sessions (account_id, id, direction, level, language,
          topic_ids, started_at, current_index, finished, updated_at)
        SELECT @a::bigint, @id::text, @direction::text, @level::text,
          @language::text, @topic_ids::jsonb, @started::timestamptz,
          @current_index::int, @finished::boolean, @updated::timestamptz
        WHERE NOT EXISTS (
          SELECT 1 FROM tombstones WHERE account_id = @a
            AND entity = 'session' AND entity_id = @id)
        ON CONFLICT (account_id, id) DO UPDATE SET
          current_index = EXCLUDED.current_index,
          finished = EXCLUDED.finished, updated_at = EXCLUDED.updated_at
        WHERE sessions.updated_at < EXCLUDED.updated_at
        RETURNING id'''),
      parameters: {
        'a': account,
        'id': id,
        'direction': s.str('direction', max: 20),
        'level': s.str('level', max: 20),
        'language': s.str('language', max: 5),
        'topic_ids': _json(s, 'topic_ids'),
        'started': s.time('started_at'),
        'current_index': s.integer('current_index'),
        'finished': s.flag('finished'),
        'updated': s.time('updated_at'),
      },
    );
    final exists =
        written.isNotEmpty ||
        (await tx.execute(
          Sql.named(
            'SELECT 1 FROM sessions WHERE account_id = @a AND id = @id',
          ),
          parameters: {'a': account, 'id': id},
        )).isNotEmpty;
    if (!exists) return; // басқа құрылғыда жойылған
    // Жауаптардың әрқайсысы өз updated_at-імен біріктіріледі.
    for (final x in s.objects('answers', max: 100)) {
      await tx.execute(
        Sql.named('''
          INSERT INTO answers (account_id, session_id, position, question_id,
            text, status, correctness, completeness, clarity, headline, advice,
            evidence, missing, disputed, dispute_reason, dispute_comment,
            updated_at)
          VALUES (@a, @s, @position, @question_id, @text, @status,
            @correctness, @completeness, @clarity, @headline, @advice,
            @evidence, @missing::jsonb, @disputed, @dispute_reason,
            @dispute_comment, @updated)
          ON CONFLICT (account_id, session_id, position) DO UPDATE SET
            question_id = EXCLUDED.question_id, text = EXCLUDED.text,
            status = EXCLUDED.status, correctness = EXCLUDED.correctness,
            completeness = EXCLUDED.completeness, clarity = EXCLUDED.clarity,
            headline = EXCLUDED.headline, advice = EXCLUDED.advice,
            evidence = EXCLUDED.evidence, missing = EXCLUDED.missing,
            disputed = EXCLUDED.disputed,
            dispute_reason = EXCLUDED.dispute_reason,
            dispute_comment = EXCLUDED.dispute_comment,
            updated_at = EXCLUDED.updated_at
          WHERE answers.updated_at < EXCLUDED.updated_at'''),
        parameters: {
          'a': account,
          's': id,
          'position': x.integer('position'),
          'question_id': x.str('question_id', max: 200),
          'text': x.str('text', allowEmpty: true),
          'status': x.str('status', max: 30),
          'correctness': x.optInt('correctness'),
          'completeness': x.optInt('completeness'),
          'clarity': x.optInt('clarity'),
          'headline': x.optStr('headline'),
          'advice': x.optStr('advice'),
          'evidence': x.optStr('evidence'),
          'missing': x['missing'] == null ? null : _json(x, 'missing'),
          'disputed': x.flag('disputed'),
          'dispute_reason': x.optStr('dispute_reason', max: 100),
          'dispute_comment': x.optStr('dispute_comment', max: 2000),
          'updated': x.time('updated_at'),
        },
      );
    }
  }

  /// Аккаунттың толық суреті — клиент SQLite-қа жазатын пішінде:
  /// уақыт миллисекундпен, JSON бағандары жол түрінде.
  Future<Map<String, Object?>> snapshot(Session tx, int account) async {
    final p = {'a': account};
    Future<List<Map<String, Object?>>> rows(String sql) async => [
      for (final r in await tx.execute(Sql.named(sql), parameters: p))
        {
          for (final e in r.toColumnMap().entries)
            e.key: switch (e.value) {
              final DateTime d => d.millisecondsSinceEpoch,
              final bool b => b ? 1 : 0,
              final v => v,
            },
        },
    ];

    final topics = await rows('''
      SELECT id, title, summary, direction, level, description,
        review_points::text AS review_points, sample_question, created_at,
        updated_at
      FROM topics WHERE account_id = @a ORDER BY created_at''');
    final questions = await rows('''
      SELECT topic_id, id, position, text, hint, model_answer,
        concepts::text AS concepts
      FROM questions WHERE account_id = @a ORDER BY topic_id, position''');
    final sessions = await rows('''
      SELECT id, direction, level, language, topic_ids::text AS topic_ids,
        started_at, current_index, finished, updated_at
      FROM sessions WHERE account_id = @a ORDER BY started_at''');
    final answers = await rows('''
      SELECT session_id, position, question_id, text, status, correctness,
        completeness, clarity, headline, advice, evidence,
        missing::text AS missing, disputed, dispute_reason, dispute_comment,
        updated_at
      FROM answers WHERE account_id = @a ORDER BY session_id, position''');

    List<Map<String, Object?>> childrenOf(
      List<Map<String, Object?>> all,
      String key,
      Object? id,
    ) => [
      for (final c in all)
        if (c[key] == id) Map.of(c)..remove(key),
    ];

    final account0 = await tx.execute(
      Sql.named('''
        SELECT id, email::text AS email, name, direction, level,
          interview_language, created_at
        FROM accounts WHERE id = @a'''),
      parameters: p,
    );
    final acc = account0.first.toColumnMap();
    return {
      'server_time': DateTime.now().millisecondsSinceEpoch,
      'account': {
        ...acc,
        'created_at': (acc['created_at']! as DateTime).millisecondsSinceEpoch,
      },
      'topics': [
        for (final t in topics)
          {...t, 'questions': childrenOf(questions, 'topic_id', t['id'])},
      ],
      'sessions': [
        for (final s in sessions)
          {...s, 'answers': childrenOf(answers, 'session_id', s['id'])},
      ],
      'favorites': await rows('''
        SELECT topic_id, created_at FROM favorites
        WHERE account_id = @a ORDER BY created_at'''),
      'deleted': [
        for (final d in await rows('''
          SELECT entity, entity_id, deleted_at FROM tombstones
          WHERE account_id = @a'''))
          {
            'entity': d['entity'],
            'id': d['entity_id'],
            'deleted_at': d['deleted_at'],
          },
      ],
    };
  }

  /// JSON бағанындағы мәтін шынымен JSON екенін тексереді.
  static String _json(Map<String, Object?> m, String key) {
    final raw = m.str(key, max: 100000);
    try {
      jsonDecode(raw);
    } on FormatException {
      throw ApiError.badRequest('"$key" must contain JSON.');
    }
    return raw;
  }
}
