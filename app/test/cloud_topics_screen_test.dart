// Практикалық №5: «Бұлттағы тақырыптар» экраны — Loading / Success / Error
// күйлері және PATCH, DELETE-тен кейін интерфейстің жаңаруы.
import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intrvue/app/routes.dart';
import 'package:intrvue/core/constants/app_strings.dart';
import 'package:intrvue/data/local/app_database.dart';
import 'package:intrvue/data/remote/dto.dart';
import 'package:intrvue/data/remote/sync_api.dart';

import 'helpers/fake_sync_api.dart';
import 'helpers/test_app.dart';

Map<String, Object?> _topicJson() => {
  'id': 'u1-100',
  'title': 'Docker негіздері',
  'summary': 'Image, container',
  'direction': 'backend',
  'level': 'junior',
  'description': 'Сипаттама',
  'review_points': ['Image', 'Volume'],
  'sample_question': 'Volume не үшін керек?',
  'created_at': '2026-10-29T10:00:00.000Z',
  'updated_at': '2026-10-30T12:30:00.123456Z',
  'questions': [
    {
      'id': 'u1-100-q1',
      'position': 0,
      'text': 'Volume не үшін керек?',
      'hint': '',
      'model_answer': 'Деректерді сақтау үшін.',
      'concepts': [
        {
          'label': 'Volume',
          'keywords': ['volume'],
        },
      ],
    },
  ],
};

/// Синхрондау нақты SQLite-пен жұмыс істейді — оған нақты уақыт береміз.
Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 3; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 100)),
    );
    await tester.pump();
  }
}

void main() {
  group('«Бұлттағы тақырыптар» экраны', () {
    // Демо аккаунт (id = 1) серверге қосылған.
    final linked = {
      'sync.link.1': jsonEncode({
        'email': AppDatabase.demoEmail,
        'token': 'token-${AppDatabase.demoEmail}',
        'lastSyncAt': null,
      }),
    };

    TopicDto remote(String id, String title) =>
        TopicDto.fromJson({..._topicJson(), 'id': id, 'title': title});

    testWidgets('Loading → Success: сервер деректері тізімде', (tester) async {
      final api = FakeSyncApi()
        ..cloudTopics['u9-1'] = remote('u9-1', 'Kubernetes')
        ..hold = Completer<void>();
      await pumpApp(
        tester,
        location: Routes.cloudTopics,
        prefs: linked,
        syncApi: (_) => api,
      );
      await tester.pump();
      expect(find.text(S.cloudLoading), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsWidgets);

      api.hold!.complete();
      await settle(tester);
      expect(find.text(S.cloudLoading), findsNothing);
      expect(find.text('Kubernetes'), findsOneWidget);
      expect(find.text(S.cloudOnlyRemote), findsOneWidget);
      expect(find.textContaining(AppDatabase.demoEmail), findsOneWidget);
    });

    for (final (failure, text) in [
      // Бұл экран кейін өзі қайталамайды — «сақталды, қайталаймыз» демейді.
      (SyncFailure.offline, () => S.cloudOffline),
      (SyncFailure.timeout, () => S.syncErrTimeout),
      (SyncFailure.server, () => S.syncErrServer),
    ]) {
      testWidgets('Error: $failure → түсінікті хабар', (tester) async {
        await pumpApp(
          tester,
          location: Routes.cloudTopics,
          prefs: linked,
          syncApi: (_) => FakeSyncApi(failure: failure),
        );
        await settle(tester);
        expect(find.text(text()), findsOneWidget);
        expect(find.text(S.cloudRefresh), findsOneWidget);
      });
    }

    testWidgets('PATCH: атау өзгерсе, тізім жаңарады', (tester) async {
      final api = FakeSyncApi()
        ..cloudTopics['u9-1'] = remote('u9-1', 'Kubernetes');
      await pumpApp(
        tester,
        location: Routes.cloudTopics,
        prefs: linked,
        syncApi: (_) => api,
      );
      await settle(tester);

      await tester.tap(find.byTooltip(S.cloudActions));
      await tester.pumpAndSettle();
      await tester.tap(find.text(S.cloudRename));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byType(TextFormField),
        'Kubernetes және Helm',
      );
      await tester.tap(find.text(S.save));
      await settle(tester);
      // Диалогтың жабылу анимациясы.
      await tester.pump(const Duration(milliseconds: 400));

      expect(api.cloudTopics['u9-1']!.title, 'Kubernetes және Helm');
      expect(find.text('Kubernetes және Helm'), findsOneWidget);
      expect(find.text(S.cloudRenamed), findsOneWidget);
    });

    testWidgets('DELETE: растағаннан кейін тізімнен жоғалады', (tester) async {
      final api = FakeSyncApi()
        ..cloudTopics['u9-1'] = remote('u9-1', 'Kubernetes');
      await pumpApp(
        tester,
        location: Routes.cloudTopics,
        prefs: linked,
        syncApi: (_) => api,
      );
      await settle(tester);

      await tester.tap(find.byTooltip(S.cloudActions));
      await tester.pumpAndSettle();
      await tester.tap(find.text(S.cloudDelete));
      await tester.pumpAndSettle();
      await tester.tap(find.text(S.delete));
      await settle(tester);

      expect(api.cloudTopics, isEmpty);
      expect(find.text('Kubernetes'), findsNothing);
      expect(find.text(S.cloudEmpty), findsOneWidget);
    });
  });
}
