import 'package:sqflite/sqflite.dart';

import 'db_schema.dart';
import 'mappers.dart';

/// Жойылған жазбалардың журналы: келесі синхрондауда серверге жіберіледі,
/// сонда басқа құрылғылар да оларды жояды.
abstract final class SyncJournal {
  static const topic = 'topic';
  static const session = 'session';
  static const favorite = 'favorite';

  static Future<void> deleted(
    DatabaseExecutor db,
    int userId,
    String entity,
    String id,
  ) => db.insert(DbSchema.syncDeletions, {
    'user_id': userId,
    'entity': entity,
    'entity_id': id,
    'deleted_at': Mappers.ms(DateTime.now()),
  }, conflictAlgorithm: ConflictAlgorithm.replace);

  /// Қайта қосылды (мысалы, таңдаулыға) — жою жазбасы енді керек емес.
  static Future<void> restored(
    DatabaseExecutor db,
    int userId,
    String entity,
    String id,
  ) => db.delete(
    DbSchema.syncDeletions,
    where: 'user_id = ? AND entity = ? AND entity_id = ?',
    whereArgs: [userId, entity, id],
  );
}
