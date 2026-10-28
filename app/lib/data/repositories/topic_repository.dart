import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';

import '../../core/constants/app_strings.dart';
import '../local/app_database.dart';
import '../local/db_errors.dart';
import '../local/db_schema.dart';
import '../local/mappers.dart';
import '../models/enums.dart';
import '../models/question.dart';
import '../models/topic.dart';
import '../models/user_profile.dart';
import 'user_scoped.dart';

/// Тақырыптар (CRUD), олардың сұрақтары, іздеу/сүзгі/сұрыптау және
/// таңдаулылар. Жиі қолданылатын тізім жадта кэштеледі, каталог сұраулары
/// тікелей SQLite-қа жіберіледі.
class TopicRepository extends ChangeNotifier implements UserScoped {
  TopicRepository(this._database);

  final AppDatabase _database;
  int? _userId;
  List<Topic> _topics = const [];
  Map<String, List<Question>> _questions = const {};

  /// Таңдаулылар қосылу ретімен.
  List<String> _favorites = const [];

  Database get _db => _database.db;

  @override
  Future<void> loadFor(UserProfile? user) async {
    _userId = user?.id;
    await _reload();
  }

  /// Read: кэшті деректер қорынан жаңарту.
  Future<void> _reload() async {
    final uid = _userId ?? -1;
    final (topics, questions, favorites) = await dbGuard(() async {
      final topicRows = await _db.query(
        DbSchema.topics,
        where: 'owner_id IS NULL OR owner_id = ?',
        whereArgs: [uid],
        orderBy: 'owner_id IS NOT NULL, created_at, rowid',
      );
      final questionRows = await _db.rawQuery(
        'SELECT q.* FROM ${DbSchema.questions} q '
        'JOIN ${DbSchema.topics} t ON t.id = q.topic_id '
        'WHERE t.owner_id IS NULL OR t.owner_id = ? '
        'ORDER BY q.topic_id, q.position',
        [uid],
      );
      final favoriteRows = await _db.query(
        DbSchema.favorites,
        columns: ['topic_id'],
        where: 'user_id = ?',
        whereArgs: [uid],
        orderBy: 'created_at',
      );
      return (topicRows, questionRows, favoriteRows);
    });
    _topics = topics.map(Mappers.topic).toList();
    final map = <String, List<Question>>{};
    for (final row in questions) {
      final q = Mappers.question(row);
      (map[q.topicId] ??= []).add(q);
    }
    _questions = map;
    _favorites = [for (final r in favorites) r['topic_id']! as String];
    notifyListeners();
  }

  List<Topic> get all => _topics;

  Topic byId(String id) => _topics.firstWhere((t) => t.id == id);

  Topic? tryById(String id) {
    for (final t in _topics) {
      if (t.id == id) return t;
    }
    return null;
  }

  List<Topic> byDirection(Direction direction) =>
      _topics.where((t) => t.direction == direction).toList();

  List<Question> questionsFor(String topicId) =>
      _questions[topicId] ?? const [];

  Question? questionById(String id) {
    for (final list in _questions.values) {
      for (final q in list) {
        if (q.id == id) return q;
      }
    }
    return null;
  }

  // ---------------------------------------------------------------- Іздеу

  /// Каталог сұрауы: іздеу + сүзгілер + сұрыптау бір SQL-да.
  Future<List<TopicListItem>> query(TopicQuery q) {
    final uid = _userId ?? -1;
    final where = <String>['(t.owner_id IS NULL OR t.owner_id = ?)'];
    final args = <Object?>[uid];

    if (q.direction != null) {
      where.add('t.direction = ?');
      args.add(q.direction!.name);
    }
    if (q.level != null) {
      where.add('t.level = ?');
      args.add(q.level!.name);
    }
    if (q.onlyMine) where.add('t.owner_id IS NOT NULL');
    if (q.onlyFavorites) {
      where.add(
        'EXISTS (SELECT 1 FROM ${DbSchema.favorites} f2 '
        'WHERE f2.topic_id = t.id AND f2.user_id = ?)',
      );
      args.add(uid);
    }
    // Әр сөз жеке ізделеді: «flutter күй» → екеуі де болуы керек.
    for (final word in q.search.toLowerCase().split(RegExp(r'\s+'))) {
      if (word.isEmpty) continue;
      where.add(r"t.search_text LIKE ? ESCAPE '\'");
      args.add(
        '%${word.replaceAllMapped(RegExp(r'[%_\\]'), (m) => '\\${m[0]}')}%',
      );
    }

    final orderBy = switch (q.sort) {
      TopicSort.titleAsc => 't.title_sort ASC',
      TopicSort.titleDesc => 't.title_sort DESC',
      TopicSort.newest => 't.updated_at DESC, t.title_sort',
      TopicSort.weakest => 'avg_score IS NULL, avg_score ASC, t.title_sort',
    };

    final sql =
        '''
      SELECT t.*,
        EXISTS (SELECT 1 FROM ${DbSchema.favorites} f
                 WHERE f.topic_id = t.id AND f.user_id = ?) AS is_favorite,
        (SELECT AVG((a.correctness + a.completeness + a.clarity) * 100.0 / 15)
           FROM ${DbSchema.answers} a
           JOIN ${DbSchema.questions} qq ON qq.id = a.question_id
           JOIN ${DbSchema.sessions} s ON s.id = a.session_id
          WHERE qq.topic_id = t.id AND s.user_id = ?
            AND a.status = 'assessed') AS avg_score,
        (SELECT COUNT(*) FROM ${DbSchema.questions} c
          WHERE c.topic_id = t.id) AS question_count
      FROM ${DbSchema.topics} t
      WHERE ${where.join(' AND ')}
      ORDER BY $orderBy''';

    // Алдымен SELECT ішіндегі екі параметр (is_favorite, avg_score), содан WHERE.
    return dbGuard(() async {
      final rows = await _db.rawQuery(sql, [uid, uid, ...args]);
      return [
        for (final r in rows)
          TopicListItem(
            topic: Mappers.topic(r),
            isFavorite: r['is_favorite'] == 1,
            averageScore: (r['avg_score'] as num?)?.toDouble(),
            questionCount: r['question_count']! as int,
          ),
      ];
    });
  }

  /// Атауы, сипаттамасы немесе бағыты бойынша іздеу.
  Future<List<Topic>> search(String text) async {
    if (text.trim().isEmpty) return const [];
    final items = await query(TopicQuery(search: text));
    return [for (final i in items) i.topic];
  }

  // ---------------------------------------------------------------- CRUD

  /// Create: пайдаланушының жаңа тақырыбы және сұрақтары.
  Future<Topic> create(TopicDraft draft) async {
    final uid = _requireUser();
    final now = DateTime.now();
    final id = 'u$uid-${now.microsecondsSinceEpoch}';
    final topic = _topicFrom(id, uid, draft, now, now);
    await dbGuard(() async {
      await _ensureUniqueTitle(draft.title, id);
      await _db.transaction((txn) async {
        await txn.insert(DbSchema.topics, Mappers.topicRow(topic));
        for (var i = 0; i < draft.questions.length; i++) {
          final q = _questionFrom(draft.questions[i], id, draft, i, now);
          await txn.insert(DbSchema.questions, Mappers.questionRow(q, i));
        }
      });
    }, unique: S.topicDuplicate);
    await _reload();
    return byId(id);
  }

  /// Update: тақырыпты және сұрақтар тізімін өзгерту.
  Future<Topic> update(String id, TopicDraft draft) async {
    final uid = _requireUser();
    final existing = byId(id);
    if (existing.ownerId != uid) throw AppException(S.topicReadOnly);
    final now = DateTime.now();
    final topic = _topicFrom(id, uid, draft, existing.createdAt ?? now, now);

    await dbGuard(
      () async {
        await _ensureUniqueTitle(draft.title, id);
        await _db.transaction((txn) async {
          await txn.update(
            DbSchema.topics,
            Mappers.topicRow(topic),
            where: 'id = ? AND owner_id = ?',
            whereArgs: [id, uid],
          );
          final keep = <String>{};
          for (var i = 0; i < draft.questions.length; i++) {
            final q = _questionFrom(draft.questions[i], id, draft, i, now);
            keep.add(q.id);
            await txn.insert(
              DbSchema.questions,
              Mappers.questionRow(q, i),
              conflictAlgorithm: ConflictAlgorithm.replace,
            );
          }
          final old = questionsFor(id)
              .map((q) => q.id)
              .where((q) => !keep.contains(q));
          for (final qid in old) {
            await txn.delete(
              DbSchema.questions,
              where: 'id = ?',
              whereArgs: [qid],
            );
          }
        });
      },
      unique: S.topicDuplicate,
      foreignKey: S.questionInUse,
    );
    await _reload();
    return byId(id);
  }

  /// Delete: тақырып пен оның сұрақтары (CASCADE). Сессияда қолданылған
  /// болса, SQLite сыртқы кілті жоюға жол бермейді.
  Future<void> delete(String id) async {
    final uid = _requireUser();
    await dbGuard(
      () => _db.delete(
        DbSchema.topics,
        where: 'id = ? AND owner_id = ?',
        whereArgs: [id, uid],
      ),
      foreignKey: S.topicInUse,
    );
    await _reload();
  }

  Future<void> _ensureUniqueTitle(String title, String id) async {
    final rows = await _db.query(
      DbSchema.topics,
      columns: ['id'],
      where:
          'title_sort = ? AND id != ? AND (owner_id IS NULL OR owner_id = ?)',
      whereArgs: [title.trim().toLowerCase(), id, _userId],
      limit: 1,
    );
    if (rows.isNotEmpty) throw AppException(S.topicDuplicate);
  }

  int _requireUser() {
    final uid = _userId;
    if (uid == null) throw AppException(S.dbNoUser);
    return uid;
  }

  Topic _topicFrom(
    String id,
    int ownerId,
    TopicDraft d,
    DateTime created,
    DateTime updated,
  ) {
    return Topic(
      id: id,
      ownerId: ownerId,
      title: d.title.trim(),
      summary: d.summary.trim(),
      description: d.description.trim().isEmpty
          ? d.summary.trim()
          : d.description.trim(),
      direction: d.direction,
      level: d.level,
      reviewPoints: d.reviewPoints,
      sampleQuestion: d.questions.first.text.trim(),
      createdAt: created,
      updatedAt: updated,
    );
  }

  Question _questionFrom(
    QuestionDraft d,
    String topicId,
    TopicDraft topic,
    int index,
    DateTime now,
  ) {
    return Question(
      id: d.id ?? '$topicId-q${now.microsecondsSinceEpoch}-$index',
      topicId: topicId,
      text: d.text.trim(),
      modelAnswer: d.modelAnswer.trim(),
      concepts: ConceptExtractor.from(topic.reviewPoints, d.modelAnswer),
    );
  }

  // ---------------------------------------------------------------- Таңдаулы

  List<Topic> get favorites =>
      _favorites.map(tryById).whereType<Topic>().toList();

  bool isFavorite(String id) => _favorites.contains(id);

  Future<void> toggleFavorite(String id) async {
    if (isFavorite(id)) {
      await removeFavorite(id);
    } else {
      await addFavorite(id);
    }
  }

  Future<void> addFavorite(String id, {DateTime? at}) async {
    final uid = _requireUser();
    await dbGuard(
      () => _db.insert(DbSchema.favorites, {
        'user_id': uid,
        'topic_id': id,
        'created_at': Mappers.ms(at ?? DateTime.now()),
      }, conflictAlgorithm: ConflictAlgorithm.ignore),
    );
    await _reload();
  }

  /// Алынған жазбаның уақытын қайтарады — «Қайтару» оны сол орынға қояды.
  Future<DateTime?> removeFavorite(String id) async {
    final uid = _requireUser();
    final rows = await dbGuard(
      () => _db.query(
        DbSchema.favorites,
        where: 'user_id = ? AND topic_id = ?',
        whereArgs: [uid, id],
      ),
    );
    await dbGuard(
      () => _db.delete(
        DbSchema.favorites,
        where: 'user_id = ? AND topic_id = ?',
        whereArgs: [uid, id],
      ),
    );
    await _reload();
    return rows.isEmpty ? null : Mappers.date(rows.first['created_at']);
  }
}

/// Пайдаланушы қосқан сұраққа бағалау ұғымдарын құрастыру:
/// «Нені қайталаймыз?» тармақтары немесе үлгі жауаптың сөйлемдері.
abstract final class ConceptExtractor {
  static List<Concept> from(List<String> reviewPoints, String modelAnswer) {
    final sources = reviewPoints.isNotEmpty
        ? reviewPoints
        : modelAnswer
              .split(RegExp(r'(?<=[.!?])\s+'))
              .where((s) => s.trim().isNotEmpty)
              .take(3)
              .toList();
    return [
      for (final s in sources)
        if (_stems(s).isNotEmpty) Concept(s.trim(), _stems(s)),
    ];
  }

  /// Қазақ тілі жалғамалы: сөздің алғашқы 5 әрпі жалғау өзгергенде де
  /// сәйкес келеді («күйді», «күйдің» → «күйді»).
  static List<String> _stems(String text) => {
    for (final w in text.toLowerCase().split(
      RegExp(r'[^\p{L}\p{N}]+', unicode: true),
    ))
      if (w.length >= 3) w.length > 5 ? w.substring(0, 5) : w,
  }.toList();
}
