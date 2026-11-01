import 'dart:io';

import 'package:intrvue_server/intrvue_server.dart';
import 'package:postgres/postgres.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;

/// Іске қосу:
///   DATABASE_URL=postgresql://intrvue:intrvue_dev@localhost:5433/intrvue?sslmode=disable \
///   dart run bin/server.dart
Future<void> main() async {
  final env = Platform.environment;
  final url =
      env['DATABASE_URL'] ??
      'postgresql://intrvue:intrvue_dev@localhost:5433/intrvue?sslmode=disable';
  final host = env['HOST'] ?? '127.0.0.1';
  final port = int.tryParse(env['PORT'] ?? '') ?? 8787;

  final db = Pool.withUrl(url);
  final version = await Schema.migrate(db);
  stdout.writeln('PostgreSQL schema v$version');

  final api = Api(db);
  final handler = const Pipeline()
      .addMiddleware(logRequests())
      .addHandler(api.handler);
  final server = await io.serve(handler, host, port);
  stdout.writeln('intRvue API: http://${server.address.host}:${server.port}');

  ProcessSignal.sigint.watch().first.then((_) async {
    // Клиенттер кідіріспен қайта қосылады.
    api.live.closeWhere(
      (_) => true,
      code: LiveHub.restartCode,
      reason: 'restart',
    );
    await server.close();
    await db.close();
    exit(0);
  });
}
