import 'dart:convert';

import 'package:postgres/postgres.dart';

import 'auth_service.dart';
import 'errors.dart';

/// Пайдаланушы тақырыптары — REST ресурсы (`/v1/topics`).
///
/// Синхрондау ([SyncService]) қолданатын кестелермен жұмыс істейді, сондықтан
/// осы жерде жасалған, өзгертілген немесе жойылған тақырып келесі
/// синхрондауда барлық құрылғыға жетеді:
/// * POST, PATCH `updated_at`-ті сервер уақытына қояды — «соңғы өзгеріс
///   жеңеді» ережесімен құрылғыдағы ескі нұсқаны ауыстырады;
/// * DELETE tombstone жазады — басқа құрылғы тақырыпты қайта тірілтпейді.
///
/// JSON: уақыт ISO 8601 (UTC), тізімдер — нағыз JSON массивтері.
class TopicsService {
  TopicsService(this._db);

  final Pool _db;

  static const maxQuestions = 200;

  Future<List<Map<String, Object?>>> list(int account) async {
    final topics = await _db.execute(
      Sql.named('$_selectTopic WHERE account_id = @a ORDER BY created_at, id'),
      parameters: {'a': account},
    );
    final questions = await _questions(_db, account);
    return [for (final t in topics) _topicJson(t.toColumnMap(), questions)];
  }

  Future<Map<String, Object?>> get(int account, String id, [Session? s]) async {
    final rows = await (s ?? _db).execute(
      Sql.named('$_selectTopic WHERE account_id = @a AND id = @id'),
      parameters: {'a': account, 'id': id},
    );
    if (rows.isEmpty) throw _notFound;
    return _topicJson(
      rows.first.toColumnMap(),
      await _questions(s ?? _db, account, id),
    );
  }

  /// Жаңа тақырып. `id` берілмесе, сервер жасайды; берілсе (құрылғыдағы
  /// тақырыпты жіберу), бос болуы керек — әйтпесе 409.
  Future<Map<String, Object?>> create(int account, Map<String, Object?> body) {
    final fields = _fields(body, partial: false);
    final questions = _questionsFrom(body, required: true)!;
    final id =
        body.optStr('id', max: 200)?.trim() ??
        's$account-${DateTime.now().microsecondsSinceEpoch}';
    if (id.isEmpty) throw const ApiError.badRequest('"id" must not be empty.');
    final createdAt = body['created_at'] == null
        ? null
        : _parseTime(body, 'created_at');

    return _db.runTx((tx) async {
      final taken = await tx.execute(
        Sql.named('SELECT 1 FROM topics WHERE account_id = @a AND id = @id'),
        parameters: {'a': account, 'id': id},
      );
      if (taken.isNotEmpty) {
        throw const ApiError(409, 'conflict', 'Topic id already exists.');
      }
      await _ensureUniqueTitle(tx, account, fields['title']! as String, id);
      // Бұрын жойылған id қайта жасалса — ескі жою белгісі енді кедергі.
      await tx.execute(
        Sql.named('''
          DELETE FROM tombstones
          WHERE account_id = @a AND entity = 'topic' AND entity_id = @id'''),
        parameters: {'a': account, 'id': id},
      );
      await tx.execute(
        Sql.named('''
          INSERT INTO topics (account_id, id, title, summary, direction, level,
            description, review_points, sample_question, created_at, updated_at)
          VALUES (@a, @id, @title, @summary, @direction, @level, @description,
            @review_points::jsonb, @sample_question,
            coalesce(@created::timestamptz, now()), now())'''),
        parameters: {
          'a': account,
          'id': id,
          'created': createdAt,
          ...fields,
          'description': fields['description'] ?? fields['summary'],
          'sample_question': questions.first['text'],
        },
      );
      await _replaceQuestions(tx, account, id, questions);
      return get(account, id, tx);
    });
  }

  /// Ішінара өзгерту: тек жіберілген өрістер. `questions` берілсе, тізім
  /// толығымен ауысады (id сақталған сұрақтар — сол сұрақтар).
  Future<Map<String, Object?>> update(
    int account,
    String id,
    Map<String, Object?> body,
  ) {
    final fields = _fields(body, partial: true);
    final questions = _questionsFrom(body, required: false);
    if (fields.isEmpty && questions == null) {
      throw const ApiError.badRequest('Nothing to update.');
    }
    return _db.runTx((tx) async {
      final exists = await tx.execute(
        Sql.named(
          'SELECT 1 FROM topics WHERE account_id = @a AND id = @id FOR UPDATE',
        ),
        parameters: {'a': account, 'id': id},
      );
      if (exists.isEmpty) throw _notFound;
      if (fields['title'] case final String title) {
        await _ensureUniqueTitle(tx, account, title, id);
      }
      final set = [
        for (final k in fields.keys)
          k == 'review_points' ? '$k = @$k::jsonb' : '$k = @$k',
        if (questions != null) 'sample_question = @sample_question',
        'updated_at = now()',
      ];
      await tx.execute(
        Sql.named(
          'UPDATE topics SET ${set.join(', ')} '
          'WHERE account_id = @a AND id = @id',
        ),
        parameters: {
          'a': account,
          'id': id,
          ...fields,
          if (questions != null) 'sample_question': questions.first['text'],
        },
      );
      if (questions != null) {
        await _replaceQuestions(tx, account, id, questions);
      }
      return get(account, id, tx);
    });
  }

  /// Жою + tombstone. Тақырып жоқ болса — 404.
  Future<void> delete(int account, String id) => _db.runTx((tx) async {
    final deleted = await tx.execute(
      Sql.named(
        'DELETE FROM topics WHERE account_id = @a AND id = @id RETURNING id',
      ),
      parameters: {'a': account, 'id': id},
    );
    if (deleted.isEmpty) throw _notFound;
    await tx.execute(
      Sql.named('''
        INSERT INTO tombstones (account_id, entity, entity_id, deleted_at)
        VALUES (@a, 'topic', @id, now())
        ON CONFLICT (account_id, entity, entity_id)
          DO UPDATE SET deleted_at = EXCLUDED.deleted_at'''),
      parameters: {'a': account, 'id': id},
    );
    // Тақырып таңдаулыда болса, ол да жойылады.
    await tx.execute(
      Sql.named(
        'DELETE FROM favorites WHERE account_id = @a AND topic_id = @id',
      ),
      parameters: {'a': account, 'id': id},
    );
  });

  // ------------------------------------------------------------- көмекшілер

  static const _notFound = ApiError(404, 'not_found', 'Topic not found.');

  static const _selectTopic = '''
    SELECT id, title, summary, direction, level, description, review_points,
      sample_question, created_at, updated_at
    FROM topics''';

  static Future<Map<String, List<Map<String, Object?>>>> _questions(
    Session db,
    int account, [
    String? topicId,
  ]) async {
    final rows = await db.execute(
      Sql.named('''
        SELECT topic_id, id, position, text, hint, model_answer, concepts
        FROM questions WHERE account_id = @a
          ${topicId == null ? '' : 'AND topic_id = @t'}
        ORDER BY topic_id, position'''),
      parameters: {'a': account, 't': ?topicId},
    );
    final byTopic = <String, List<Map<String, Object?>>>{};
    for (final r in rows) {
      final q = r.toColumnMap();
      (byTopic[q.remove('topic_id')! as String] ??= []).add(q);
    }
    return byTopic;
  }

  static Map<String, Object?> _topicJson(
    Map<String, Object?> t,
    Map<String, List<Map<String, Object?>>> questions,
  ) => {
    ...t,
    'created_at': _iso(t['created_at']),
    'updated_at': _iso(t['updated_at']),
    'questions': questions[t['id']] ?? const [],
  };

  static String _iso(Object? v) => (v! as DateTime).toUtc().toIso8601String();

  static DateTime _parseTime(Map<String, Object?> body, String key) {
    final v = body[key];
    final parsed = v is String ? DateTime.tryParse(v) : null;
    if (parsed == null) {
      throw ApiError.badRequest('"$key" must be an ISO 8601 date-time.');
    }
    return parsed.toUtc();
  }

  /// Тақырып өрістері. [partial] болса — тек берілгендері тексеріледі.
  static Map<String, Object?> _fields(
    Map<String, Object?> body, {
    required bool partial,
  }) {
    bool has(String k) => !partial || body.containsKey(k);
    final out = <String, Object?>{};
    if (has('title')) {
      final title = body.str('title', max: 120).trim();
      if (title.length < 3) {
        throw const ApiError.badRequest('"title" needs at least 3 chars.');
      }
      out['title'] = title;
    }
    if (has('summary')) out['summary'] = body.str('summary', max: 500).trim();
    if (has('direction')) {
      out['direction'] = _oneOf(body, 'direction', AuthService.directions);
    }
    if (has('level')) out['level'] = _oneOf(body, 'level', AuthService.levels);
    if (body.containsKey('description')) {
      out['description'] = body.str('description', allowEmpty: true).trim();
    }
    if (has('review_points')) {
      final points = body['review_points'];
      if (points is! List ||
          points.length > 30 ||
          points.any((p) => p is! String || p.trim().isEmpty)) {
        throw const ApiError.badRequest(
          '"review_points" must be a list of non-empty strings (≤ 30).',
        );
      }
      out['review_points'] = jsonEncode(points);
    }
    return out;
  }

  static String _oneOf(Map<String, Object?> body, String key, Set<String> ok) {
    final v = body.str(key, max: 20);
    if (!ok.contains(v)) {
      throw ApiError.badRequest('"$key" must be one of ${ok.join(', ')}.');
    }
    return v;
  }

  static List<Map<String, Object?>>? _questionsFrom(
    Map<String, Object?> body, {
    required bool required,
  }) {
    if (!required && !body.containsKey('questions')) return null;
    final list = body.objects('questions', max: maxQuestions);
    if (list.isEmpty) {
      throw const ApiError.badRequest('"questions" must not be empty.');
    }
    return [
      for (final q in list)
        {
          'id': q.optStr('id', max: 200),
          'text': q.str('text', max: 2000).trim(),
          'hint': q.optStr('hint', max: 500) ?? '',
          'model_answer': q.str('model_answer', max: 20000).trim(),
          'concepts': _concepts(q['concepts']),
        },
    ];
  }

  static String _concepts(Object? v) {
    final list = v ?? const [];
    final ok =
        list is List &&
        list.every(
          (c) =>
              c is Map &&
              c['label'] is String &&
              c['keywords'] is List &&
              (c['keywords'] as List).every((k) => k is String),
        );
    if (!ok) {
      throw const ApiError.badRequest(
        '"concepts" must be a list of {label, keywords[]}.',
      );
    }
    return jsonEncode(list);
  }

  static Future<void> _ensureUniqueTitle(
    Session tx,
    int account,
    String title,
    String id,
  ) async {
    final rows = await tx.execute(
      Sql.named(
        '''
        SELECT 1 FROM topics
        WHERE account_id = @a AND id <> @id AND lower(title) = lower(@title)''',
      ),
      parameters: {'a': account, 'id': id, 'title': title},
    );
    if (rows.isNotEmpty) {
      throw const ApiError(
        409,
        'title_taken',
        'A topic with this title already exists.',
      );
    }
  }

  static Future<void> _replaceQuestions(
    Session tx,
    int account,
    String topicId,
    List<Map<String, Object?>> questions,
  ) async {
    await tx.execute(
      Sql.named(
        'DELETE FROM questions WHERE account_id = @a AND topic_id = @t',
      ),
      parameters: {'a': account, 't': topicId},
    );
    final stamp = DateTime.now().microsecondsSinceEpoch;
    for (var i = 0; i < questions.length; i++) {
      final q = questions[i];
      await tx.execute(
        Sql.named('''
          INSERT INTO questions (account_id, id, topic_id, position, text,
            hint, model_answer, concepts)
          VALUES (@a, @id, @t, @position, @text, @hint, @model_answer,
            @concepts::jsonb)'''),
        parameters: {
          'a': account,
          't': topicId,
          'id': q['id'] ?? '$topicId-q$stamp-$i',
          'position': i,
          'text': q['text'],
          'hint': q['hint'],
          'model_answer': q['model_answer'],
          'concepts': q['concepts'],
        },
      );
    }
  }
}
