// Негізгі экрандардың ашылуы мен өзара байланысын тексеру.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intrvue/core/constants/app_strings.dart';
import 'package:intrvue/data/models/enums.dart';
import 'package:intrvue/data/repositories/settings_repository.dart';
import 'package:intrvue/data/repositories/session_repository.dart';

import 'package:intrvue/data/remote/sync_api.dart';
import 'package:intrvue/data/repositories/sync_repository.dart';
import 'package:intrvue/data/repositories/topic_repository.dart';
import 'package:intrvue/data/services/reminder_scheduler.dart';

import 'helpers/fake_sync_api.dart';
import 'helpers/test_app.dart';

Future<void> tapText(WidgetTester tester, String text) async {
  await tester.pump();
  final finder = find.text(text).last;
  await tester.ensureVisible(finder);
  await tester.pump();
  await tester.tap(finder);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 600));
}

Future<void> back(WidgetTester tester) => tapText(tester, S.back);

void main() {
  testWidgets('Splash → Onboarding → Welcome → Login → Home', (tester) async {
    await pumpApp(
      tester,
      location: '/splash',
      loggedIn: false,
      prefs: {'onboarding.seen': false},
    );
    expect(find.text(S.splashTagline), findsOneWidget);
    await tester.pump(const Duration(seconds: 2));
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.text(S.onboarding1Title), findsOneWidget);
    await tapText(tester, S.next);
    expect(find.text(S.onboarding2Title), findsOneWidget);
    await tapText(tester, S.next);
    await tapText(tester, S.start);

    expect(find.text(S.welcomeHero), findsOneWidget);
    await tapText(tester, S.haveAccountLogin);
    expect(find.text(S.loginTitle), findsOneWidget);

    // Бос өрістер: түсінікті хабарламалар.
    await tapText(tester, S.loginAction);
    expect(find.text(S.emailEmpty), findsOneWidget);
    expect(find.text(S.passwordEmpty), findsOneWidget);

    // Қате email форматы.
    await tester.enterText(find.byType(TextFormField).at(0), 'aidana@');
    await tester.pump();
    expect(find.text(S.emailInvalid), findsOneWidget);

    // Қате пароль.
    await tester.enterText(
      find.byType(TextFormField).at(0),
      'aidana@example.com',
    );
    await tester.enterText(find.byType(TextFormField).at(1), 'wrong123');
    await tapText(tester, S.loginAction);
    expect(find.text(S.loginWrongCredentials), findsOneWidget);
    expect(find.text(S.loginErrorTitle), findsOneWidget);

    // Дұрыс деректер → басты бет.
    await tester.enterText(find.byType(TextFormField).at(1), 'intrvue2026');
    await tapText(tester, S.loginAction);
    expect(find.text(S.greeting('Айдана')), findsOneWidget);
  });

  testWidgets('Тіркелу: валидация → профиль баптау → басты бет', (
    tester,
  ) async {
    await pumpApp(tester, location: '/register', loggedIn: false);
    await tapText(tester, S.createAccount);
    expect(find.text(S.nameEmpty), findsOneWidget);
    expect(find.text(S.emailEmpty), findsOneWidget);
    expect(find.text(S.passwordEmpty), findsOneWidget);
    expect(find.text(S.privacyConsentRequired), findsOneWidget);

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'Ерлан');
    await tester.enterText(fields.at(1), 'erlan@example.com');
    await tester.enterText(fields.at(2), 'short');
    await tester.pump();
    expect(find.text(S.passwordWeak), findsOneWidget);

    await tester.enterText(fields.at(2), 'erlan2026');
    await tapText(tester, S.privacyConsent);
    await tapText(tester, S.createAccount);

    expect(find.text(S.setupTitle), findsOneWidget);
    await tapText(tester, 'QA');
    await tapText(tester, S.setupSave);
    expect(find.text(S.greeting('Ерлан')), findsOneWidget);
  });

  testWidgets('Home → List → Detail → таңдаулы → Profile → Edit', (
    tester,
  ) async {
    await pumpApp(tester, location: '/home', noFavorites: true);
    await tapText(tester, S.homeCatalog);
    expect(find.text(S.catalogTitle), findsOneWidget);

    await tapText(tester, 'Күйді басқару');
    expect(find.text(S.whatWeReview), findsOneWidget);
    await tapText(tester, S.addFavorite);
    expect(find.text(S.removeFavorite), findsOneWidget);
    expect(find.text(S.addedToFavorites), findsOneWidget);

    await tapText(tester, S.open);
    expect(find.text(S.favoritesTitle), findsOneWidget);
    expect(find.text('Күйді басқару'), findsOneWidget);

    await tapText(tester, S.toProfile);
    expect(find.text(S.profileTitle), findsOneWidget);
    await tapText(tester, S.editProfile);
    await tester.enterText(find.byType(TextFormField).first, '');
    await tapText(tester, S.saveChanges);
    expect(find.text(S.nameEmpty), findsOneWidget);
    await tester.enterText(find.byType(TextFormField).first, 'Айдана Н.');
    await tapText(tester, S.saveChanges);
    expect(find.text('Айдана Н.'), findsOneWidget);
    expect(find.text(S.profileTitle), findsOneWidget);
  });

  testWidgets('Іздеу: нәтиже және «табылмады»', (tester) async {
    await pumpApp(tester, location: '/search');
    await tester.enterText(find.byType(TextFormField), 'flutter');
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text(S.found(1)), findsOneWidget);
    await tester.enterText(find.byType(TextFormField), 'Kubernetes');
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text(S.notFoundTitle), findsOneWidget);
    await tapText(tester, S.clearSearch);
    expect(find.text(S.popularTopics), findsOneWidget);
  });

  testWidgets('Төменгі навигация: төрт бөлім', (tester) async {
    await pumpApp(tester, location: '/home');
    await tapText(tester, S.navHistory);
    expect(find.text(S.historySubtitle), findsOneWidget);
    await tapText(tester, S.navProgress);
    expect(find.text(S.progressSubtitle), findsOneWidget);
    await tapText(tester, S.navSettings);
    expect(find.text(S.settingsSubtitle), findsOneWidget);
    await tapText(tester, S.navHome);
    expect(find.text(S.homeNextTitle), findsOneWidget);
  });

  testWidgets('BUG-8.01: жүйелік «Артқа» бөлімнен Басты бетке қайтарады', (
    tester,
  ) async {
    await pumpApp(tester, location: '/home');
    await tapText(tester, S.navSettings);
    expect(find.text(S.settingsSubtitle), findsOneWidget);

    // Түзетуге дейін: маршрут жабылып, қосымша жабылатын (true емес → шығу).
    final handled = await tester.binding.handlePopRoute();
    await tester.pump(const Duration(milliseconds: 600));
    expect(handled, isTrue);
    expect(find.text(S.homeNextTitle), findsOneWidget);
    expect(find.text(S.settingsSubtitle), findsNothing);
  });

  testWidgets('Толық жаттығу сессиясы: 5 сұрақ → қорытынды → ұсыныс', (
    tester,
  ) async {
    await pumpApp(tester, location: '/home');
    await tester.runAsync(repo<SessionRepository>(tester).finishActive);
    await tester.pump();

    await tapText(tester, S.homeStartAction);
    expect(find.text(S.topicsPickTitle), findsOneWidget);
    await tapText(tester, S.continueWithTopics(2));
    expect(find.text(S.paramsTitle), findsOneWidget);
    await tapText(tester, S.paramsStart);
    expect(find.text(S.consentAccept), findsOneWidget);
    await tapText(tester, S.consentAccept);
    expect(find.text(S.preparingMotto), findsOneWidget);
    await tester.pump(const Duration(seconds: 2));
    await tester.pump(const Duration(milliseconds: 600));

    for (var i = 1; i <= 5; i++) {
      expect(find.text(S.progressOf(i, 5)), findsOneWidget);
      if (i == 3) {
        await tapText(tester, S.skipQuestion);
        await tapText(tester, S.skip);
        continue;
      }
      // Бос жауапты жіберуге болмайды.
      await tapText(tester, S.submitAnswer);
      expect(find.text(S.answerEmpty), findsOneWidget);

      await tester.enterText(
        find.byType(TextFormField),
        'Null safety және StatelessWidget State setState() мысалы. Future бір мән.',
      );
      await tapText(tester, S.submitAnswer);
      await tester.pump(const Duration(seconds: 1));
      await tester.pump(const Duration(milliseconds: 600));
      expect(find.text(S.evidenceTitle), findsOneWidget);

      if (i == 1) {
        await tapText(tester, S.readModelAnswer);
        expect(find.text(S.modelAnswerTitle), findsOneWidget);
        await tapText(tester, S.backToFeedback);
      }
      await tapText(tester, i == 5 ? S.finishSession : S.nextQuestion);
    }

    expect(find.text(S.summaryTitle), findsOneWidget);
    expect(find.text(S.statusComplete), findsOneWidget);
    await tapText(tester, S.whatToReview);
    expect(find.text(S.recommendTitle), findsOneWidget);
    await back(tester);
    await tapText(tester, S.reviewAnswers);
    expect(find.text(S.sessionAnswers), findsOneWidget);
    expect(find.text(S.skippedPoints), findsOneWidget);
  });

  testWidgets('Тарих: сессияны ашу және жою', (tester) async {
    await pumpApp(tester, location: '/history');
    final before = repo<SessionRepository>(tester).history.length;
    await tapText(tester, '80,0');
    expect(find.text(S.summaryTitle), findsOneWidget);
    await back(tester);
    await tester.tap(find.text(S.delete).first);
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text(S.deleteSessionTitle), findsOneWidget);
    await tester.tap(find.text(S.delete).last);
    await tester.pump(const Duration(milliseconds: 400));
    expect(repo<SessionRepository>(tester).history.length, before - 1);
  });

  testWidgets('Баптаулар: тақырып → қараңғы, шығу', (tester) async {
    await pumpApp(tester, location: '/settings');
    await tapText(tester, S.theme);
    await tapText(tester, S.themeDark);
    await tapText(tester, S.save);
    expect(
      Theme.of(tester.element(find.text(S.settingsSubtitle))).brightness,
      Brightness.dark,
    );

    await tapText(tester, S.logout);
    expect(find.text(S.logoutTitle), findsOneWidget);
    await tapText(tester, S.logoutAction);
    expect(find.text(S.loginTitle), findsOneWidget);
  });

  testWidgets('Аккаунтты жою: қате пароль', (tester) async {
    await pumpApp(tester, location: '/settings/delete-account');
    await tapText(tester, S.deleteAccountAction);
    expect(find.text(S.passwordEmpty), findsOneWidget);
    await tester.enterText(find.byType(TextFormField), 'wrong');
    await tapText(tester, S.deleteAccountAction);
    expect(find.text(S.deleteAccountWrongPassword), findsOneWidget);
  });

  testWidgets('Тақырып CRUD: Create → Read → Update → Delete', (tester) async {
    await pumpApp(tester, location: '/topics');
    await tester.pump(const Duration(milliseconds: 300));

    // Create: бос форма — міндетті өрістер хабарламалары.
    await tapText(tester, S.addTopic);
    expect(find.text(S.topicFormCreate), findsOneWidget);
    await tapText(tester, S.addTopic);
    expect(find.text(S.topicTitleEmpty), findsOneWidget);
    expect(find.text(S.summaryEmpty), findsOneWidget);
    expect(find.text(S.questionTextEmpty), findsOneWidget);
    expect(find.text(S.modelAnswerEmpty), findsOneWidget);

    Finder field(String label) => find.descendant(
      of: find
          .ancestor(of: find.text(label), matching: find.byType(Column))
          .first,
      matching: find.byType(TextFormField),
    );
    await tester.enterText(field(S.fieldTopicTitle), 'Тест тақырыбы');
    await tester.enterText(field(S.fieldSummary), 'Қысқа');
    await tester.enterText(field(S.fieldReviewPoints), 'Бірінші тармақ');
    await tester.enterText(field(S.fieldQuestionText), 'Тест сұрағы?');
    await tester.enterText(field(S.fieldModelAnswer), 'Үлгі жауап.');
    await tapText(tester, S.addTopic);
    await tester.pump(const Duration(milliseconds: 600));

    // Read: Detail экраны.
    expect(find.text('Тест тақырыбы'), findsWidgets);
    expect(find.text(S.edit), findsOneWidget);

    // Update. Алдыңғы хабарлама төменгі батырманы жаппауы үшін жабамыз.
    ScaffoldMessenger.of(tester.element(find.byType(Scaffold).first))
        .removeCurrentSnackBar();
    await tapText(tester, S.edit);
    expect(find.text(S.topicFormEdit), findsOneWidget);
    await tester.enterText(field(S.fieldTopicTitle), 'Өзгертілген тақырып');
    await tapText(tester, S.saveChanges);
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text('Өзгертілген тақырып'), findsWidgets);

    // Delete.
    ScaffoldMessenger.of(tester.element(find.byType(Scaffold).first))
        .removeCurrentSnackBar();
    await tapText(tester, S.edit);
    await tapText(tester, S.deleteTopic);
    expect(find.text(S.deleteTopicTitle), findsOneWidget);
    await tester.tap(find.text(S.delete).last);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text(S.catalogTitle), findsOneWidget);
    expect(find.text('Өзгертілген тақырып'), findsNothing);
  });

  testWidgets('Каталог: іздеу, «Менікі» сүзгісі және бос күй', (tester) async {
    await pumpApp(tester, location: '/topics');
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Dart негіздері'), findsOneWidget);

    await tester.enterText(find.byType(TextField).first, 'асинх');
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Асинхрондылық'), findsOneWidget);
    expect(find.text('Dart негіздері'), findsNothing);

    await tester.enterText(find.byType(TextField).first, '');
    await tester.pump(const Duration(milliseconds: 400));
    await tapText(tester, S.filterMine);
    expect(find.text(S.catalogEmptyTitle), findsOneWidget);
    await tapText(tester, S.resetFilters);
    expect(find.text('Frontend'), findsNothing);
    expect(find.text('HTML және CSS'), findsOneWidget);
  });

  testWidgets('BUG-8.03: «Еске салуды қосу» жазуын басу ауыстырады', (
    tester,
  ) async {
    await pumpApp(tester, location: '/settings/reminders');
    bool value() => tester.widget<Switch>(find.byType(Switch)).value;
    expect(value(), isFalse);
    // Түзетуге дейін: тек ауыстырғыштың өзі басылатын, жазу — жоқ.
    await tester.tap(find.text(S.remindersEnable));
    await tester.pump();
    expect(value(), isTrue);
    await tester.tap(find.text(S.remindersEnable));
    await tester.pump();
    expect(value(), isFalse);
  });

  testWidgets('BUG-8.04: уақытты мәтінмен енгізу 24 сағаттық пішімде', (
    tester,
  ) async {
    await pumpApp(tester, location: '/settings/reminders');
    // Жүйе 12 сағаттық (тест әдепкісі), қосымша тілі — kk.
    expect(tester.binding.platformDispatcher.alwaysUse24HourFormat, isFalse);
    Future<void> openInput(String time) async {
      await tester.ensureVisible(find.text(time));
      await tester.pumpAndSettle();
      await tester.tap(find.text(time));
      await tester.pumpAndSettle();
      final l = MaterialLocalizations.of(tester.element(find.byType(Dialog)));
      await tester.tap(find.byTooltip(l.inputTimeModeButtonLabel));
      await tester.pumpAndSettle();
    }

    await tester.tap(find.byType(Switch));
    await tester.pump();
    await openInput('19:00');

    final fields = find.descendant(
      of: find.byType(Dialog),
      matching: find.byType(TextField),
    );
    await tester.enterText(fields.at(0), '02');
    await tester.enterText(fields.at(1), '46');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Иә'));
    await tester.pumpAndSettle();
    // Түзетуге дейін: 14:46 (сағат 12 сағаттық «PM» ретінде оқылды).
    expect(find.text('02:46'), findsOneWidget);

    // Кешкі сағат та мәтінмен енгізіледі (бұрын «19» қабылданбайтын).
    await openInput('02:46');
    await tester.enterText(fields.at(0), '21');
    await tester.enterText(fields.at(1), '30');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Иә'));
    await tester.pumpAndSettle();
    expect(find.text('21:30'), findsOneWidget);
  });

  testWidgets('Еске салу: рұқсат бар → «Еске салу қосулы»', (tester) async {
    await pumpApp(tester, location: '/settings/reminders');
    await tester.tap(find.byType(Switch));
    await tester.pump();
    await tapText(tester, S.save);
    expect(find.text(S.remindersEnabledTitle), findsOneWidget);
    expect(find.textContaining('Дс'), findsOneWidget);
  });

  testWidgets('BUG-8.05: рұқсат бар болса — «рұқсат қажет» деп жазылмайды', (
    tester,
  ) async {
    await pumpApp(tester, location: '/settings/reminders');
    await tester.tap(find.byType(Switch));
    await tester.pump();
    // Күтілетін: рұқсат туралы дұрыс күй, батырма — жай «Сақтау».
    // Түзетуге дейін: «Хабарламаға рұқсат қажет», «Сақтау және рұқсат беру».
    expect(find.text(S.remindersPermissionGrantedTitle), findsOneWidget);
    expect(find.text(S.remindersPermissionTitle), findsNothing);
    expect(find.text(S.remindersSave), findsNothing);
    await tapText(tester, S.save);
    expect(find.text(S.remindersEnabledTitle), findsOneWidget);
  });

  testWidgets('Еске салу: рұқсат жоқ → «Хабарламалар өшірулі»', (tester) async {
    await pumpApp(
      tester,
      location: '/settings/reminders',
      reminders: const NoopReminderScheduler(permitted: false),
    );
    await tester.tap(find.byType(Switch));
    await tester.pump();
    await tapText(tester, S.remindersSave);
    expect(find.text(S.notificationsOffTitle), findsOneWidget);
    expect(find.text(S.openAndroidSettings), findsOneWidget);
    await tapText(tester, S.notNow);
    expect(find.text(S.settingsSubtitle), findsOneWidget);
  });

  testWidgets('Парольді ұмыттым → сілтеме → жаңа пароль → кіру', (
    tester,
  ) async {
    await pumpApp(tester, location: '/forgot-password', loggedIn: false);
    await tester.enterText(find.byType(TextFormField), 'aidana@example.com');
    await tapText(tester, S.resetSend);
    expect(find.text(S.resetSentTitle), findsOneWidget);
    await tapText(tester, S.resetDemoOpen);
    expect(find.text(S.newPasswordSubtitle), findsOneWidget);

    await tapText(tester, S.savePassword);
    expect(find.text(S.passwordEmpty), findsOneWidget);
    await tester.enterText(find.byType(TextFormField).at(0), 'jana2026pass');
    await tester.enterText(find.byType(TextFormField).at(1), 'basqa2026');
    await tapText(tester, S.savePassword);
    expect(find.text(S.passwordMismatch), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).at(1), 'jana2026pass');
    await tapText(tester, S.savePassword);
    expect(find.text(S.loginTitle), findsOneWidget);
    await tester.enterText(
      find.byType(TextFormField).at(0),
      'aidana@example.com',
    );
    await tester.enterText(find.byType(TextFormField).at(1), 'jana2026pass');
    await tapText(tester, S.loginAction);
    expect(find.text(S.greeting('Айдана')), findsOneWidget);
  });

  testWidgets('Тілді ауыстыру: қазақша → орысша, сақталады', (tester) async {
    await pumpApp(tester, location: '/settings/appearance');
    await tapText(tester, 'Русский');
    await tapText(tester, S.save);
    expect(find.text('Настройки'), findsWidgets);
    expect(find.text('Язык интерфейса'), findsOneWidget);
    expect(find.text('Главная'), findsOneWidget);
    expect(repo<SettingsRepository>(tester).language, InterfaceLanguage.ru);
    // Қайта ауыстыру.
    await tapText(tester, 'Язык интерфейса');
    await tapText(tester, 'Қазақша');
    await tapText(tester, 'Сохранить');
    expect(find.text('Баптаулар'), findsWidgets);
  });

  testWidgets('Бұлттық синхрондау: қосу → күйі → ажырату', (tester) async {
    final api = FakeSyncApi();
    await pumpApp(tester, location: '/settings', syncApi: (_) => api);
    expect(find.text(S.syncTitle), findsOneWidget);
    expect(find.text(S.syncOff), findsWidgets);
    await tapText(tester, S.syncTitle);

    // Бос пароль — валидация, серверге сұрау жоқ.
    await tapText(tester, S.syncConnect);
    expect(find.text(S.passwordEmpty), findsOneWidget);
    expect(api.pushed, isEmpty);

    await tester.enterText(find.byType(TextFormField).first, 'intrvue2026');
    await tapText(tester, S.syncConnect);
    expect(find.text(S.syncNow), findsOneWidget);
    expect(find.text(S.syncAccount), findsOneWidget);
    expect(api.pushed, hasLength(1));
    // Суретте демо аккаунттың сессиялары мен таңдаулысы бар.
    expect(api.pushed.single['sessions'], isNotEmpty);
    expect(api.pushed.single['favorites'], isNotEmpty);
    expect(repo<SyncRepository>(tester).link?.lastSyncAt, isNotNull);

    await tapText(tester, S.syncNow);
    expect(api.pushed, hasLength(2));

    await tapText(tester, S.syncDisconnect);
    expect(find.text(S.syncDisconnectTitle), findsOneWidget);
    await tapText(tester, S.syncDisconnect);
    expect(find.text(S.syncConnect), findsOneWidget);
    expect(repo<SyncRepository>(tester).link, isNull);
  });

  testWidgets('Синхрондау: сервер қолжетімсіз → түсінікті хабарлама', (
    tester,
  ) async {
    await pumpApp(
      tester,
      location: '/settings/sync',
      syncApi: (_) => FakeSyncApi(failure: SyncFailure.offline),
    );
    // Сервер мекенжайы әдепкіде жасырын — «Өзгерту» арқылы ашылады.
    expect(find.text(S.syncServer), findsNothing);
    await tapText(tester, S.edit);
    await tester.enterText(find.byType(TextFormField).last, 'ftp://x');
    await tester.enterText(find.byType(TextFormField).first, 'intrvue2026');
    await tapText(tester, S.syncConnect);
    expect(find.text(S.syncServerInvalid), findsOneWidget);

    await tester.enterText(
      find.byType(TextFormField).last,
      'http://192.168.1.10:8787',
    );
    await tapText(tester, S.syncConnect);
    expect(find.text(S.syncErrOffline), findsOneWidget);
    expect(repo<SyncRepository>(tester).link, isNull);
    expect(
      repo<SyncRepository>(tester).serverUrl.toString(),
      'http://192.168.1.10:8787',
    );
  });

  testWidgets('Жаңа құрылғыда кіру → деректер бұлттан қалпына келеді', (
    tester,
  ) async {
    const created = 1761700000000;
    final api = FakeSyncApi(
      accounts: {'erlan@example.com': 'qwerty2026'},
      remote: {
        'topics': [
          {
            'id': 'u7-1',
            'title': 'Kafka негіздері',
            'summary': 'Топик, партиция',
            'direction': 'backend',
            'level': 'junior',
            'description': '',
            'review_points': '["Партиция"]',
            'sample_question': 'Партиция деген не?',
            'created_at': created,
            'updated_at': created,
            'questions': [
              {
                'id': 'u7-1-q0',
                'position': 0,
                'text': 'Партиция деген не?',
                'hint': '',
                'model_answer': 'Топиктің реттелген бөлігі.',
                'concepts': '[]',
              },
            ],
          },
        ],
        'favorites': [
          {'topic_id': 'u7-1', 'created_at': created},
        ],
      },
    );
    await pumpApp(
      tester,
      location: '/login',
      loggedIn: false,
      syncApi: (_) => api,
    );
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.first, 'erlan@example.com');
    await tester.enterText(fields.last, 'qwerty2026');
    await tapText(tester, S.loginAction);
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.text(S.syncRestored), findsOneWidget);
    expect(find.text(S.greeting('Ерлан')), findsOneWidget);
    final topics = repo<TopicRepository>(tester);
    expect(topics.tryById('u7-1')?.title, 'Kafka негіздері');
    expect(topics.isFavorite('u7-1'), isTrue);
    expect(repo<SyncRepository>(tester).link?.email, 'erlan@example.com');
  });

  testWidgets('Жаңа құрылғы, сервер жоқ → «Кіру орындалмады»', (tester) async {
    await pumpApp(
      tester,
      location: '/login',
      loggedIn: false,
      syncApi: (_) => FakeSyncApi(failure: SyncFailure.offline),
    );
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.first, 'ghost@example.com');
    await tester.enterText(fields.last, 'qwerty2026');
    await tapText(tester, S.loginAction);
    expect(find.text(S.loginWrongCredentials), findsOneWidget);
  });
}
