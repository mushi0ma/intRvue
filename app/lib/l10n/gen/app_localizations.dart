import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_kk.dart';
import 'app_localizations_ru.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'gen/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('kk'),
    Locale('ru'),
  ];

  /// No description provided for @appName.
  ///
  /// In kk, this message translates to:
  /// **'intRvue'**
  String get appName;

  /// No description provided for @back.
  ///
  /// In kk, this message translates to:
  /// **'Артқа'**
  String get back;

  /// No description provided for @skip.
  ///
  /// In kk, this message translates to:
  /// **'Өткізу'**
  String get skip;

  /// No description provided for @next.
  ///
  /// In kk, this message translates to:
  /// **'Келесі'**
  String get next;

  /// No description provided for @start.
  ///
  /// In kk, this message translates to:
  /// **'Бастау'**
  String get start;

  /// No description provided for @cancel.
  ///
  /// In kk, this message translates to:
  /// **'Бас тарту'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In kk, this message translates to:
  /// **'Сақтау'**
  String get save;

  /// No description provided for @delete.
  ///
  /// In kk, this message translates to:
  /// **'Жою'**
  String get delete;

  /// No description provided for @continueAction.
  ///
  /// In kk, this message translates to:
  /// **'Жалғастыру'**
  String get continueAction;

  /// No description provided for @notNow.
  ///
  /// In kk, this message translates to:
  /// **'Қазір емес'**
  String get notNow;

  /// No description provided for @toHome.
  ///
  /// In kk, this message translates to:
  /// **'Басты бетке'**
  String get toHome;

  /// No description provided for @backToHome.
  ///
  /// In kk, this message translates to:
  /// **'Басты бетке оралу'**
  String get backToHome;

  /// No description provided for @outOf100.
  ///
  /// In kk, this message translates to:
  /// **'/ 100'**
  String get outOf100;

  /// No description provided for @aiDisclaimer.
  ///
  /// In kk, this message translates to:
  /// **'ЖИ бағасы — оқу ұсынымы.'**
  String get aiDisclaimer;

  /// No description provided for @notHiringDecision.
  ///
  /// In kk, this message translates to:
  /// **'Бұл жұмысқа қабылдау шешімі емес.'**
  String get notHiringDecision;

  /// No description provided for @draftSaved.
  ///
  /// In kk, this message translates to:
  /// **'Нобай сақталды'**
  String get draftSaved;

  /// No description provided for @comingSoon.
  ///
  /// In kk, this message translates to:
  /// **'Келесі нұсқада қолжетімді болады.'**
  String get comingSoon;

  /// No description provided for @navHome.
  ///
  /// In kk, this message translates to:
  /// **'Басты бет'**
  String get navHome;

  /// No description provided for @navHistory.
  ///
  /// In kk, this message translates to:
  /// **'Тарих'**
  String get navHistory;

  /// No description provided for @navProgress.
  ///
  /// In kk, this message translates to:
  /// **'Прогресс'**
  String get navProgress;

  /// No description provided for @navSettings.
  ///
  /// In kk, this message translates to:
  /// **'Баптаулар'**
  String get navSettings;

  /// No description provided for @splashTagline.
  ///
  /// In kk, this message translates to:
  /// **'Бір жауаптан басталады.'**
  String get splashTagline;

  /// No description provided for @splashFooter.
  ///
  /// In kk, this message translates to:
  /// **'IT сұхбатына жеке дайындық'**
  String get splashFooter;

  /// No description provided for @onboarding1Title.
  ///
  /// In kk, this message translates to:
  /// **'Жауапты\nмәтінмен жазыңыз'**
  String get onboarding1Title;

  /// No description provided for @onboarding1Body.
  ///
  /// In kk, this message translates to:
  /// **'Сұраққа өз сөзіңізбен жауап беріңіз.\nНобай әр кезде құрылғыда сақталады.'**
  String get onboarding1Body;

  /// No description provided for @onboarding2Title.
  ///
  /// In kk, this message translates to:
  /// **'Бағаның себебін\nкөріңіз'**
  String get onboarding2Title;

  /// No description provided for @onboarding2Body.
  ///
  /// In kk, this message translates to:
  /// **'ЖИ дұрыстық, толықтық және анықтықты\n0–5 бойынша бағалап, дәлелін көрсетеді.'**
  String get onboarding2Body;

  /// No description provided for @onboarding3Title.
  ///
  /// In kk, this message translates to:
  /// **'Әлсіз тақырыпты\nқайталаңыз'**
  String get onboarding3Title;

  /// No description provided for @onboarding3Body.
  ///
  /// In kk, this message translates to:
  /// **'Нәтижеден ең көбі үш әлсіз тақырып\nұсынылады — келесі жаттығуға бір қадам.'**
  String get onboarding3Body;

  /// No description provided for @onboardingYourAnswer.
  ///
  /// In kk, this message translates to:
  /// **'Жауабыңыз'**
  String get onboardingYourAnswer;

  /// No description provided for @onboardingWeakTopics.
  ///
  /// In kk, this message translates to:
  /// **'Әлсіз тақырыптар'**
  String get onboardingWeakTopics;

  /// No description provided for @onboardingPractice.
  ///
  /// In kk, this message translates to:
  /// **'Осы тақырыпты жаттықтыру'**
  String get onboardingPractice;

  /// No description provided for @welcomeHero.
  ///
  /// In kk, this message translates to:
  /// **'Біліміңізді\nжауапқа\nайналдырыңыз.'**
  String get welcomeHero;

  /// No description provided for @welcomeBody.
  ///
  /// In kk, this message translates to:
  /// **'IT сұхбатына мәтінмен жаттығыңыз.\nНені білетініңізді, нені толықтыру\nкерегін нақты көріңіз.'**
  String get welcomeBody;

  /// No description provided for @welcomeAssessmentTitle.
  ///
  /// In kk, this message translates to:
  /// **'Бір жауап. Үш өлшем.'**
  String get welcomeAssessmentTitle;

  /// No description provided for @haveAccountLogin.
  ///
  /// In kk, this message translates to:
  /// **'Аккаунт бар ма? Кіру'**
  String get haveAccountLogin;

  /// No description provided for @correctness.
  ///
  /// In kk, this message translates to:
  /// **'Дұрыстық'**
  String get correctness;

  /// No description provided for @completeness.
  ///
  /// In kk, this message translates to:
  /// **'Толықтық'**
  String get completeness;

  /// No description provided for @clarity.
  ///
  /// In kk, this message translates to:
  /// **'Анықтық'**
  String get clarity;

  /// No description provided for @fieldDefault.
  ///
  /// In kk, this message translates to:
  /// **'Өріс'**
  String get fieldDefault;

  /// No description provided for @nameEmpty.
  ///
  /// In kk, this message translates to:
  /// **'Атыңызды енгізіңіз.'**
  String get nameEmpty;

  /// No description provided for @nameTooShort.
  ///
  /// In kk, this message translates to:
  /// **'Аты кемінде 2 таңбадан тұрады.'**
  String get nameTooShort;

  /// No description provided for @nameTooLong.
  ///
  /// In kk, this message translates to:
  /// **'Аты 40 таңбадан аспауы керек.'**
  String get nameTooLong;

  /// No description provided for @emailEmpty.
  ///
  /// In kk, this message translates to:
  /// **'Email мекенжайын енгізіңіз.'**
  String get emailEmpty;

  /// No description provided for @emailInvalid.
  ///
  /// In kk, this message translates to:
  /// **'Email қате енгізілген. Үлгі: name@example.com'**
  String get emailInvalid;

  /// No description provided for @passwordEmpty.
  ///
  /// In kk, this message translates to:
  /// **'Парольді енгізіңіз.'**
  String get passwordEmpty;

  /// No description provided for @passwordWeak.
  ///
  /// In kk, this message translates to:
  /// **'Кемінде 8 таңба: әріп пен сан болуы керек.'**
  String get passwordWeak;

  /// No description provided for @passwordRepeat.
  ///
  /// In kk, this message translates to:
  /// **'Парольді қайталаңыз.'**
  String get passwordRepeat;

  /// No description provided for @passwordMismatch.
  ///
  /// In kk, this message translates to:
  /// **'Парольдер сәйкес болуы керек.'**
  String get passwordMismatch;

  /// No description provided for @answerEmpty.
  ///
  /// In kk, this message translates to:
  /// **'Жауап бос болмауы керек.'**
  String get answerEmpty;

  /// No description provided for @fieldName.
  ///
  /// In kk, this message translates to:
  /// **'Атыңыз'**
  String get fieldName;

  /// No description provided for @fieldEmail.
  ///
  /// In kk, this message translates to:
  /// **'Email'**
  String get fieldEmail;

  /// No description provided for @fieldPassword.
  ///
  /// In kk, this message translates to:
  /// **'Пароль'**
  String get fieldPassword;

  /// No description provided for @fieldDirection.
  ///
  /// In kk, this message translates to:
  /// **'Бағыт'**
  String get fieldDirection;

  /// No description provided for @fieldLevel.
  ///
  /// In kk, this message translates to:
  /// **'Деңгей'**
  String get fieldLevel;

  /// No description provided for @fieldInterviewLanguage.
  ///
  /// In kk, this message translates to:
  /// **'Сұхбат тілі'**
  String get fieldInterviewLanguage;

  /// No description provided for @showPassword.
  ///
  /// In kk, this message translates to:
  /// **'Парольді көрсету'**
  String get showPassword;

  /// No description provided for @hidePassword.
  ///
  /// In kk, this message translates to:
  /// **'Парольді жасыру'**
  String get hidePassword;

  /// No description provided for @loginTitle.
  ///
  /// In kk, this message translates to:
  /// **'Қайта қош келдіңіз'**
  String get loginTitle;

  /// No description provided for @loginSubtitle.
  ///
  /// In kk, this message translates to:
  /// **'Дайындықты тоқтаған жерден жалғастырыңыз.'**
  String get loginSubtitle;

  /// No description provided for @loginErrorTitle.
  ///
  /// In kk, this message translates to:
  /// **'Кіру орындалмады'**
  String get loginErrorTitle;

  /// No description provided for @loginErrorSubtitle.
  ///
  /// In kk, this message translates to:
  /// **'Email мен парольді тексеріңіз.'**
  String get loginErrorSubtitle;

  /// No description provided for @loginWrongCredentials.
  ///
  /// In kk, this message translates to:
  /// **'Email немесе пароль қате.'**
  String get loginWrongCredentials;

  /// No description provided for @forgotPassword.
  ///
  /// In kk, this message translates to:
  /// **'Парольді ұмыттыңыз ба?'**
  String get forgotPassword;

  /// No description provided for @resetPasswordLink.
  ///
  /// In kk, this message translates to:
  /// **'Парольді қалпына келтіру'**
  String get resetPasswordLink;

  /// No description provided for @loginAction.
  ///
  /// In kk, this message translates to:
  /// **'Кіру'**
  String get loginAction;

  /// No description provided for @loginRetry.
  ///
  /// In kk, this message translates to:
  /// **'Қайта кіру'**
  String get loginRetry;

  /// No description provided for @noAccount.
  ///
  /// In kk, this message translates to:
  /// **'Әлі аккаунт жоқ па?'**
  String get noAccount;

  /// No description provided for @registerAction.
  ///
  /// In kk, this message translates to:
  /// **'Тіркелу'**
  String get registerAction;

  /// No description provided for @dataPrivate.
  ///
  /// In kk, this message translates to:
  /// **'Деректеріңіз тек өзіңізге қолжетімді.'**
  String get dataPrivate;

  /// No description provided for @demoHint.
  ///
  /// In kk, this message translates to:
  /// **'Демо: aidana@example.com · intrvue2026'**
  String get demoHint;

  /// No description provided for @registerTitle.
  ///
  /// In kk, this message translates to:
  /// **'Алғашқы қадам'**
  String get registerTitle;

  /// No description provided for @registerSubtitle.
  ///
  /// In kk, this message translates to:
  /// **'Жаттығуларыңыз бен прогресті сақтаңыз.'**
  String get registerSubtitle;

  /// No description provided for @passwordRule.
  ///
  /// In kk, this message translates to:
  /// **'Кемінде 8 таңба: әріп пен сан.'**
  String get passwordRule;

  /// No description provided for @privacyConsent.
  ///
  /// In kk, this message translates to:
  /// **'Құпиялылық шарттарымен таныстым және келісемін.'**
  String get privacyConsent;

  /// No description provided for @privacyConsentRequired.
  ///
  /// In kk, this message translates to:
  /// **'Тіркелу үшін құпиялылық шарттарымен келісіңіз.'**
  String get privacyConsentRequired;

  /// No description provided for @aiConsentLater.
  ///
  /// In kk, this message translates to:
  /// **'ЖИ-ге жауап жіберуге келісім\nалғашқы жаттығу алдында сұралады.'**
  String get aiConsentLater;

  /// No description provided for @createAccount.
  ///
  /// In kk, this message translates to:
  /// **'Аккаунт ашу'**
  String get createAccount;

  /// No description provided for @emailTaken.
  ///
  /// In kk, this message translates to:
  /// **'Бұл email тіркелген. Кіріп көріңіз.'**
  String get emailTaken;

  /// No description provided for @resetTitle.
  ///
  /// In kk, this message translates to:
  /// **'Кіруді қалпына\nкелтіру'**
  String get resetTitle;

  /// No description provided for @resetSubtitle.
  ///
  /// In kk, this message translates to:
  /// **'Email-ге бір реттік сілтеме жібереміз.\nОл 15 минут жарамды болады.'**
  String get resetSubtitle;

  /// No description provided for @resetSend.
  ///
  /// In kk, this message translates to:
  /// **'Сілтеме жіберу'**
  String get resetSend;

  /// No description provided for @resetNoEmailTitle.
  ///
  /// In kk, this message translates to:
  /// **'Хатты таппадыңыз ба?'**
  String get resetNoEmailTitle;

  /// No description provided for @resetNoEmailBody.
  ///
  /// In kk, this message translates to:
  /// **'«Спам» бумасын тексеріңіз.\nEmail мекенжайын түзетіп,\nқайта сұрауға болады.'**
  String get resetNoEmailBody;

  /// No description provided for @backToLogin.
  ///
  /// In kk, this message translates to:
  /// **'Кіру экранына оралу'**
  String get backToLogin;

  /// No description provided for @resetSentTitle.
  ///
  /// In kk, this message translates to:
  /// **'Хат жіберілді'**
  String get resetSentTitle;

  /// No description provided for @resetSentBody.
  ///
  /// In kk, this message translates to:
  /// **'Сілтемені 15 минут ішінде ашыңыз.\nОны тек бір рет қолдануға болады.'**
  String get resetSentBody;

  /// No description provided for @resetResend.
  ///
  /// In kk, this message translates to:
  /// **'Хатты қайта сұрау'**
  String get resetResend;

  /// No description provided for @resetResent.
  ///
  /// In kk, this message translates to:
  /// **'Хат қайта жіберілді.'**
  String get resetResent;

  /// No description provided for @resetDemoTitle.
  ///
  /// In kk, this message translates to:
  /// **'Демо: хат орнына сілтеме'**
  String get resetDemoTitle;

  /// No description provided for @resetDemoBody.
  ///
  /// In kk, this message translates to:
  /// **'Пошта сервері әлі қосылмаған. Хаттағы сілтеме осында ашылады: ол 15 минут, бір рет жарамды.'**
  String get resetDemoBody;

  /// No description provided for @resetDemoOpen.
  ///
  /// In kk, this message translates to:
  /// **'Сілтемені ашу'**
  String get resetDemoOpen;

  /// No description provided for @newPasswordTitle.
  ///
  /// In kk, this message translates to:
  /// **'Жаңа пароль'**
  String get newPasswordTitle;

  /// No description provided for @newPasswordSubtitle.
  ///
  /// In kk, this message translates to:
  /// **'Қауіпсіз пароль таңдаңыз.'**
  String get newPasswordSubtitle;

  /// No description provided for @newPasswordField.
  ///
  /// In kk, this message translates to:
  /// **'Жаңа пароль'**
  String get newPasswordField;

  /// No description provided for @repeatPasswordField.
  ///
  /// In kk, this message translates to:
  /// **'Парольді қайталау'**
  String get repeatPasswordField;

  /// No description provided for @savePassword.
  ///
  /// In kk, this message translates to:
  /// **'Парольді сақтау'**
  String get savePassword;

  /// No description provided for @resetLinkExpired.
  ///
  /// In kk, this message translates to:
  /// **'Сілтеме ескірді ме? Жаңасын сұрау'**
  String get resetLinkExpired;

  /// No description provided for @resetLinkInvalid.
  ///
  /// In kk, this message translates to:
  /// **'Сілтеме жарамсыз немесе ескірген. Жаңа сілтеме сұраңыз.'**
  String get resetLinkInvalid;

  /// No description provided for @passwordChanged.
  ///
  /// In kk, this message translates to:
  /// **'Пароль өзгертілді. Жаңа парольмен кіріңіз.'**
  String get passwordChanged;

  /// No description provided for @resetSentHint.
  ///
  /// In kk, this message translates to:
  /// **'«Спам» бумасын тексеріңіз.\nСілтемені ашқаннан кейін\nжаңа пароль орнатасыз.'**
  String get resetSentHint;

  /// No description provided for @setupTitle.
  ///
  /// In kk, this message translates to:
  /// **'Сізге сай жаттығу'**
  String get setupTitle;

  /// No description provided for @setupSubtitle.
  ///
  /// In kk, this message translates to:
  /// **'Бұл параметрлерді кейін өзгерте аласыз.'**
  String get setupSubtitle;

  /// No description provided for @setupSave.
  ///
  /// In kk, this message translates to:
  /// **'Сақтау және жалғастыру'**
  String get setupSave;

  /// No description provided for @homeSubtitle.
  ///
  /// In kk, this message translates to:
  /// **'Бүгін бір қадам алға.'**
  String get homeSubtitle;

  /// No description provided for @homeResumeTitle.
  ///
  /// In kk, this message translates to:
  /// **'Жаттығуды\nжалғастырайық'**
  String get homeResumeTitle;

  /// No description provided for @homeStartTitle.
  ///
  /// In kk, this message translates to:
  /// **'Жаңа жаттығуды\nбастайық'**
  String get homeStartTitle;

  /// No description provided for @homeStartBody.
  ///
  /// In kk, this message translates to:
  /// **'Бағыт пен тақырыпты таңдап,\n5 сұрақтан бастаңыз.'**
  String get homeStartBody;

  /// No description provided for @homeStartAction.
  ///
  /// In kk, this message translates to:
  /// **'Жаңа жаттығу'**
  String get homeStartAction;

  /// No description provided for @homeNextTitle.
  ///
  /// In kk, this message translates to:
  /// **'Келесі жаттығу'**
  String get homeNextTitle;

  /// No description provided for @homeNextBody.
  ///
  /// In kk, this message translates to:
  /// **'Flutter, Dart немесе жаңа тақырып.\nБелсенді сессияны алдымен аяқтаңыз.'**
  String get homeNextBody;

  /// No description provided for @homeNextBodyFree.
  ///
  /// In kk, this message translates to:
  /// **'Каталогтан тақырып ашып, жаттығуды бастаңыз.'**
  String get homeNextBodyFree;

  /// No description provided for @homeCatalog.
  ///
  /// In kk, this message translates to:
  /// **'Тақырыптар каталогы'**
  String get homeCatalog;

  /// No description provided for @homeLastResult.
  ///
  /// In kk, this message translates to:
  /// **'Соңғы нәтиже'**
  String get homeLastResult;

  /// No description provided for @homeNoResult.
  ///
  /// In kk, this message translates to:
  /// **'Толық сессия әлі жоқ.'**
  String get homeNoResult;

  /// No description provided for @openProfile.
  ///
  /// In kk, this message translates to:
  /// **'Профильді ашу'**
  String get openProfile;

  /// No description provided for @topicsPickTitle.
  ///
  /// In kk, this message translates to:
  /// **'Нені жаттықтырамыз?'**
  String get topicsPickTitle;

  /// No description provided for @topicsPickSubtitle.
  ///
  /// In kk, this message translates to:
  /// **'Кемінде бір тақырып таңдаңыз.'**
  String get topicsPickSubtitle;

  /// No description provided for @pickTopicFirst.
  ///
  /// In kk, this message translates to:
  /// **'Тақырып таңдаңыз'**
  String get pickTopicFirst;

  /// No description provided for @paramsTitle.
  ///
  /// In kk, this message translates to:
  /// **'Жаттығу параметрлері'**
  String get paramsTitle;

  /// No description provided for @paramsLanguage.
  ///
  /// In kk, this message translates to:
  /// **'Сұхбат пен кері байланыс тілі'**
  String get paramsLanguage;

  /// No description provided for @paramsCount.
  ///
  /// In kk, this message translates to:
  /// **'Сұрақ саны'**
  String get paramsCount;

  /// No description provided for @paramsPaceTitle.
  ///
  /// In kk, this message translates to:
  /// **'Өзіңізге ыңғайлы қарқын'**
  String get paramsPaceTitle;

  /// No description provided for @paramsPaceBody.
  ///
  /// In kk, this message translates to:
  /// **'Уақыт шектеуі жоқ. Сессияны\nүзіліске қойып, кейін жалғастырыңыз.\nЖауап нобайы құрылғыда сақталады.'**
  String get paramsPaceBody;

  /// No description provided for @paramsStart.
  ///
  /// In kk, this message translates to:
  /// **'Жаттығуды бастау'**
  String get paramsStart;

  /// No description provided for @consentTitle.
  ///
  /// In kk, this message translates to:
  /// **'Жауапты ЖИ-ге\nжіберуге келісім'**
  String get consentTitle;

  /// No description provided for @consentWhatTitle.
  ///
  /// In kk, this message translates to:
  /// **'Бағалау үшін не жіберіледі?'**
  String get consentWhatTitle;

  /// No description provided for @consentWhatBody.
  ///
  /// In kk, this message translates to:
  /// **'Сұрақ, жауабыңыз және жаттығу\nпараметрлері. Атыңыз, email және\nпароліңіз ЖИ-ге жіберілмейді.'**
  String get consentWhatBody;

  /// No description provided for @consentAdviceTitle.
  ///
  /// In kk, this message translates to:
  /// **'Баға — оқу ұсынымы'**
  String get consentAdviceTitle;

  /// No description provided for @consentAdviceBody.
  ///
  /// In kk, this message translates to:
  /// **'ЖИ қателесуі мүмкін. Баға түсініксіз\nболса, пікір қалдыра аласыз.\nКеліспесеңіз, сессия басталмайды.'**
  String get consentAdviceBody;

  /// No description provided for @consentAccept.
  ///
  /// In kk, this message translates to:
  /// **'Келісемін, бастау'**
  String get consentAccept;

  /// No description provided for @preparingTitle.
  ///
  /// In kk, this message translates to:
  /// **'Сұрақтарды\nдайындап жатырмыз'**
  String get preparingTitle;

  /// No description provided for @preparingBody.
  ///
  /// In kk, this message translates to:
  /// **'ЖИ сұрақтарды құрастырып жатыр.\nҚайта басудың қажеті жоқ.'**
  String get preparingBody;

  /// No description provided for @preparingMotto.
  ///
  /// In kk, this message translates to:
  /// **'Бір сұрақтан, бір қадамнан.'**
  String get preparingMotto;

  /// No description provided for @prepareErrorTitle.
  ///
  /// In kk, this message translates to:
  /// **'Сұрақтар жүктелмеді'**
  String get prepareErrorTitle;

  /// No description provided for @prepareErrorSubtitle.
  ///
  /// In kk, this message translates to:
  /// **'Сессия параметрлері сақталды.'**
  String get prepareErrorSubtitle;

  /// No description provided for @prepareNoQuestions.
  ///
  /// In kk, this message translates to:
  /// **'Таңдалған тақырыптарда сұрақ жоқ. Басқа тақырып таңдаңыз немесе тақырыпқа сұрақ қосыңыз.'**
  String get prepareNoQuestions;

  /// No description provided for @backToParams.
  ///
  /// In kk, this message translates to:
  /// **'Параметрлерге оралу'**
  String get backToParams;

  /// No description provided for @preparingHint.
  ///
  /// In kk, this message translates to:
  /// **'30 секундта жауап келмесе,\nқайта сұрау ұсынылады.'**
  String get preparingHint;

  /// No description provided for @activeTitle.
  ///
  /// In kk, this message translates to:
  /// **'Бір сессия\nаяқталмаған'**
  String get activeTitle;

  /// No description provided for @activeBody.
  ///
  /// In kk, this message translates to:
  /// **'Жалғастыра аласыз немесе\nосы сессияны ерте аяқтап,\nжаңа жаттығу бастай аласыз.'**
  String get activeBody;

  /// No description provided for @activeWarning.
  ///
  /// In kk, this message translates to:
  /// **'Ерте аяқталған сессия «Толық емес»\nболып сақталады және орташа\nбалға кірмейді.'**
  String get activeWarning;

  /// No description provided for @activeResume.
  ///
  /// In kk, this message translates to:
  /// **'Сессияны жалғастыру'**
  String get activeResume;

  /// No description provided for @activeFinishAndNew.
  ///
  /// In kk, this message translates to:
  /// **'Аяқтап, жаңасын бастау'**
  String get activeFinishAndNew;

  /// No description provided for @draftStored.
  ///
  /// In kk, this message translates to:
  /// **'Нобай сақталған'**
  String get draftStored;

  /// No description provided for @pause.
  ///
  /// In kk, this message translates to:
  /// **'Үзіліс'**
  String get pause;

  /// No description provided for @yourAnswer.
  ///
  /// In kk, this message translates to:
  /// **'Жауабыңыз'**
  String get yourAnswer;

  /// No description provided for @answerHint.
  ///
  /// In kk, this message translates to:
  /// **'Жауабыңызды осында жазыңыз'**
  String get answerHint;

  /// No description provided for @submitAnswer.
  ///
  /// In kk, this message translates to:
  /// **'Жауапты жіберу'**
  String get submitAnswer;

  /// No description provided for @skipQuestion.
  ///
  /// In kk, this message translates to:
  /// **'Сұрақты өткізу'**
  String get skipQuestion;

  /// No description provided for @skipConfirmTitle.
  ///
  /// In kk, this message translates to:
  /// **'Сұрақты өткізесіз бе?'**
  String get skipConfirmTitle;

  /// No description provided for @skipConfirmBody.
  ///
  /// In kk, this message translates to:
  /// **'Өткізілген сұраққа 0 балл беріледі.\nОған кейін орала алмайсыз.'**
  String get skipConfirmBody;

  /// No description provided for @assessing.
  ///
  /// In kk, this message translates to:
  /// **'Жауап бағаланып жатыр…'**
  String get assessing;

  /// No description provided for @pauseSaved.
  ///
  /// In kk, this message translates to:
  /// **'Сессия үзіліске қойылды. Нобай сақталды.'**
  String get pauseSaved;

  /// No description provided for @evidenceTitle.
  ///
  /// In kk, this message translates to:
  /// **'Жауабыңыздағы дәлел'**
  String get evidenceTitle;

  /// No description provided for @missingTitle.
  ///
  /// In kk, this message translates to:
  /// **'Нені толықтыру керек'**
  String get missingTitle;

  /// No description provided for @nothingMissing.
  ///
  /// In kk, this message translates to:
  /// **'Негізгі ұғымдардың бәрі ашылған.'**
  String get nothingMissing;

  /// No description provided for @readModelAnswer.
  ///
  /// In kk, this message translates to:
  /// **'Үлгі жауапты оқу'**
  String get readModelAnswer;

  /// No description provided for @disagree.
  ///
  /// In kk, this message translates to:
  /// **'Бағамен келіспеймін'**
  String get disagree;

  /// No description provided for @nextQuestion.
  ///
  /// In kk, this message translates to:
  /// **'Келесі сұрақ'**
  String get nextQuestion;

  /// No description provided for @finishSession.
  ///
  /// In kk, this message translates to:
  /// **'Нәтижені көру'**
  String get finishSession;

  /// No description provided for @modelAnswerTitle.
  ///
  /// In kk, this message translates to:
  /// **'Үлгі жауап'**
  String get modelAnswerTitle;

  /// No description provided for @keyConcepts.
  ///
  /// In kk, this message translates to:
  /// **'Негізгі ұғымдар'**
  String get keyConcepts;

  /// No description provided for @backToFeedback.
  ///
  /// In kk, this message translates to:
  /// **'Талдауға оралу'**
  String get backToFeedback;

  /// No description provided for @disputeTitle.
  ///
  /// In kk, this message translates to:
  /// **'Бағаны белгілеу'**
  String get disputeTitle;

  /// No description provided for @disputeQuestion.
  ///
  /// In kk, this message translates to:
  /// **'Немен келіспейсіз?'**
  String get disputeQuestion;

  /// No description provided for @disputeWrong.
  ///
  /// In kk, this message translates to:
  /// **'Баға қате'**
  String get disputeWrong;

  /// No description provided for @disputeUnclear.
  ///
  /// In kk, this message translates to:
  /// **'Түсініксіз'**
  String get disputeUnclear;

  /// No description provided for @disputeComment.
  ///
  /// In kk, this message translates to:
  /// **'Түсіндірмеңіз'**
  String get disputeComment;

  /// No description provided for @disputeCommentHint.
  ///
  /// In kk, this message translates to:
  /// **'Неге келіспейтініңізді жазыңыз'**
  String get disputeCommentHint;

  /// No description provided for @disputeCommentRequired.
  ///
  /// In kk, this message translates to:
  /// **'Түсіндірмені жазыңыз.'**
  String get disputeCommentRequired;

  /// No description provided for @disputeNote.
  ///
  /// In kk, this message translates to:
  /// **'Пікір осы сұрақ пен баға нұсқасына\nтіркеледі. Бастапқы балл\nавтоматты түрде өзгермейді.'**
  String get disputeNote;

  /// No description provided for @disputeSend.
  ///
  /// In kk, this message translates to:
  /// **'Пікірді жіберу'**
  String get disputeSend;

  /// No description provided for @disputeSent.
  ///
  /// In kk, this message translates to:
  /// **'Пікір сақталды. Бастапқы балл өзгерген жоқ.'**
  String get disputeSent;

  /// No description provided for @yourFeedback.
  ///
  /// In kk, this message translates to:
  /// **'Сіздің пікіріңіз'**
  String get yourFeedback;

  /// No description provided for @disputeScoreUnchanged.
  ///
  /// In kk, this message translates to:
  /// **'Бастапқы балл өзгерген жоқ.'**
  String get disputeScoreUnchanged;

  /// No description provided for @summaryTitle.
  ///
  /// In kk, this message translates to:
  /// **'Жаттығу аяқталды'**
  String get summaryTitle;

  /// No description provided for @summaryIncompleteTitle.
  ///
  /// In kk, this message translates to:
  /// **'Нәтиже толық емес'**
  String get summaryIncompleteTitle;

  /// No description provided for @statusComplete.
  ///
  /// In kk, this message translates to:
  /// **'Толық'**
  String get statusComplete;

  /// No description provided for @statusIncomplete.
  ///
  /// In kk, this message translates to:
  /// **'Толық емес'**
  String get statusIncomplete;

  /// No description provided for @statusPending.
  ///
  /// In kk, this message translates to:
  /// **'Бағалау күтілуде'**
  String get statusPending;

  /// No description provided for @byTopic.
  ///
  /// In kk, this message translates to:
  /// **'Тақырып бойынша'**
  String get byTopic;

  /// No description provided for @whatToReview.
  ///
  /// In kk, this message translates to:
  /// **'Нені қайталау керек?'**
  String get whatToReview;

  /// No description provided for @reviewAnswers.
  ///
  /// In kk, this message translates to:
  /// **'Жауаптарды қарау'**
  String get reviewAnswers;

  /// No description provided for @scoreNotReady.
  ///
  /// In kk, this message translates to:
  /// **'Балл әлі дайын емес'**
  String get scoreNotReady;

  /// No description provided for @unassessedNotZero.
  ///
  /// In kk, this message translates to:
  /// **'Бағаланбаған жауап — нөл емес.'**
  String get unassessedNotZero;

  /// No description provided for @incompleteBody.
  ///
  /// In kk, this message translates to:
  /// **'Барлық баға келгенде нәтиже\nқайта есептеледі. Әзірге бұл\nсессия орташа балға кірмейді.\nӨткізілген сұраққа 0 балл беріледі.'**
  String get incompleteBody;

  /// No description provided for @toHistory.
  ///
  /// In kk, this message translates to:
  /// **'Тарихқа өту'**
  String get toHistory;

  /// No description provided for @retryAssessment.
  ///
  /// In kk, this message translates to:
  /// **'Бағалауды қайта сұрау'**
  String get retryAssessment;

  /// No description provided for @recommendTitle.
  ///
  /// In kk, this message translates to:
  /// **'Келесі қадам анық.'**
  String get recommendTitle;

  /// No description provided for @recommendSubtitle.
  ///
  /// In kk, this message translates to:
  /// **'Алдымен әлсіз тақырыпты бекітіңіз.'**
  String get recommendSubtitle;

  /// No description provided for @practiceThisTopic.
  ///
  /// In kk, this message translates to:
  /// **'Осы тақырыпты жаттықтыру'**
  String get practiceThisTopic;

  /// No description provided for @whyThisTopic.
  ///
  /// In kk, this message translates to:
  /// **'Неге осы тақырып?'**
  String get whyThisTopic;

  /// No description provided for @recommendLimit.
  ///
  /// In kk, this message translates to:
  /// **'Бір уақытта ең көбі 3 әлсіз тақырып\nұсынылады. Қарқынды өзіңіз таңдаңыз.'**
  String get recommendLimit;

  /// No description provided for @otherWeakTopics.
  ///
  /// In kk, this message translates to:
  /// **'Басқа әлсіз тақырыптар'**
  String get otherWeakTopics;

  /// No description provided for @noRecommendations.
  ///
  /// In kk, this message translates to:
  /// **'Ұсыныс жасауға бағаланған жауап жеткіліксіз.'**
  String get noRecommendations;

  /// No description provided for @historyTitle.
  ///
  /// In kk, this message translates to:
  /// **'Жаттығу тарихы'**
  String get historyTitle;

  /// No description provided for @historySubtitle.
  ///
  /// In kk, this message translates to:
  /// **'Сақталған сессияларды қайта қараңыз.'**
  String get historySubtitle;

  /// No description provided for @allDirections.
  ///
  /// In kk, this message translates to:
  /// **'Барлық бағыт'**
  String get allDirections;

  /// No description provided for @allStatuses.
  ///
  /// In kk, this message translates to:
  /// **'Барлығы'**
  String get allStatuses;

  /// No description provided for @allSessions.
  ///
  /// In kk, this message translates to:
  /// **'Барлық сессия'**
  String get allSessions;

  /// No description provided for @periodLabel.
  ///
  /// In kk, this message translates to:
  /// **'Кезең'**
  String get periodLabel;

  /// No description provided for @periodAll.
  ///
  /// In kk, this message translates to:
  /// **'Барлық уақыт'**
  String get periodAll;

  /// No description provided for @periodPick.
  ///
  /// In kk, this message translates to:
  /// **'Кезеңді таңдаңыз'**
  String get periodPick;

  /// No description provided for @periodClear.
  ///
  /// In kk, this message translates to:
  /// **'Кезеңді тазарту'**
  String get periodClear;

  /// No description provided for @apply.
  ///
  /// In kk, this message translates to:
  /// **'Қолдану'**
  String get apply;

  /// No description provided for @statusFilter.
  ///
  /// In kk, this message translates to:
  /// **'Сессия күйі'**
  String get statusFilter;

  /// No description provided for @historyHint.
  ///
  /// In kk, this message translates to:
  /// **'Сессияны ашып, жауаптарды қараңыз.'**
  String get historyHint;

  /// No description provided for @historyEmptyTitle.
  ///
  /// In kk, this message translates to:
  /// **'Сессия табылмады'**
  String get historyEmptyTitle;

  /// No description provided for @historyEmptyBody.
  ///
  /// In kk, this message translates to:
  /// **'Сүзгіні өзгертіңіз немесе жаңа жаттығу бастаңыз.'**
  String get historyEmptyBody;

  /// No description provided for @deleteSessionTitle.
  ///
  /// In kk, this message translates to:
  /// **'Сессияны жоясыз ба?'**
  String get deleteSessionTitle;

  /// No description provided for @deleteSessionBody.
  ///
  /// In kk, this message translates to:
  /// **'Жауаптар жойылып, прогресс\nқайта есептеледі. Аккаунт сақталады.'**
  String get deleteSessionBody;

  /// No description provided for @sessionDeleted.
  ///
  /// In kk, this message translates to:
  /// **'Сессия жойылды.'**
  String get sessionDeleted;

  /// No description provided for @sessionAnswers.
  ///
  /// In kk, this message translates to:
  /// **'Сессия жауаптары'**
  String get sessionAnswers;

  /// No description provided for @backToSummary.
  ///
  /// In kk, this message translates to:
  /// **'Қорытындыға оралу'**
  String get backToSummary;

  /// No description provided for @skippedPoints.
  ///
  /// In kk, this message translates to:
  /// **'Өткізілді · 0 / 15'**
  String get skippedPoints;

  /// No description provided for @pendingPoints.
  ///
  /// In kk, this message translates to:
  /// **'Бағалау күтілуде · балл жоқ'**
  String get pendingPoints;

  /// No description provided for @notAnswered.
  ///
  /// In kk, this message translates to:
  /// **'Жауап берілмеді'**
  String get notAnswered;

  /// No description provided for @questionList.
  ///
  /// In kk, this message translates to:
  /// **'Сұрақтар тізімі'**
  String get questionList;

  /// No description provided for @yourAnswerSaved.
  ///
  /// In kk, this message translates to:
  /// **'Сіздің жауабыңыз'**
  String get yourAnswerSaved;

  /// No description provided for @progressTitle.
  ///
  /// In kk, this message translates to:
  /// **'Ілгерілеуіңіз'**
  String get progressTitle;

  /// No description provided for @progressSubtitle.
  ///
  /// In kk, this message translates to:
  /// **'Бір бағыт пен деңгей ғана салыстырылады.'**
  String get progressSubtitle;

  /// No description provided for @scoreAxis.
  ///
  /// In kk, this message translates to:
  /// **'Балл / 100'**
  String get scoreAxis;

  /// No description provided for @incompleteExcluded.
  ///
  /// In kk, this message translates to:
  /// **'Толық емес сессиялар динамикаға\nжәне орташа балға кірмейді.'**
  String get incompleteExcluded;

  /// No description provided for @sampleData.
  ///
  /// In kk, this message translates to:
  /// **'Көрсетілген мәндер — үлгі деректер.'**
  String get sampleData;

  /// No description provided for @progressEmptyTitle.
  ///
  /// In kk, this message translates to:
  /// **'Әзірге толық сессия жоқ.'**
  String get progressEmptyTitle;

  /// No description provided for @progressEmptyBody.
  ///
  /// In kk, this message translates to:
  /// **'Бір жаттығуды аяқтаңыз.\nОсы бағыт пен деңгейдегі\nбалл динамикасы осында көрінеді.'**
  String get progressEmptyBody;

  /// No description provided for @progressEmptyHint.
  ///
  /// In kk, this message translates to:
  /// **'Дайындықты 5 сұрақтан бастаңыз.\nУақыт шектеуі жоқ.'**
  String get progressEmptyHint;

  /// No description provided for @progressEmptyAction.
  ///
  /// In kk, this message translates to:
  /// **'Алғашқы жаттығуды бастау'**
  String get progressEmptyAction;

  /// No description provided for @weakTopicsTitle.
  ///
  /// In kk, this message translates to:
  /// **'Әлсіз тақырыптар'**
  String get weakTopicsTitle;

  /// No description provided for @settingsTitle.
  ///
  /// In kk, this message translates to:
  /// **'Баптаулар'**
  String get settingsTitle;

  /// No description provided for @settingsSubtitle.
  ///
  /// In kk, this message translates to:
  /// **'Дайындықты өзіңізге бейімдеңіз.'**
  String get settingsSubtitle;

  /// No description provided for @profileLink.
  ///
  /// In kk, this message translates to:
  /// **'Профиль'**
  String get profileLink;

  /// No description provided for @interfaceLanguage.
  ///
  /// In kk, this message translates to:
  /// **'Интерфейс тілі'**
  String get interfaceLanguage;

  /// No description provided for @theme.
  ///
  /// In kk, this message translates to:
  /// **'Тақырып'**
  String get theme;

  /// No description provided for @reminders.
  ///
  /// In kk, this message translates to:
  /// **'Еске салу'**
  String get reminders;

  /// No description provided for @remindersOff.
  ///
  /// In kk, this message translates to:
  /// **'Өшірулі'**
  String get remindersOff;

  /// No description provided for @privacy.
  ///
  /// In kk, this message translates to:
  /// **'Құпиялылық'**
  String get privacy;

  /// No description provided for @logout.
  ///
  /// In kk, this message translates to:
  /// **'Аккаунттан шығу'**
  String get logout;

  /// No description provided for @deleteAccount.
  ///
  /// In kk, this message translates to:
  /// **'Аккаунтты жою'**
  String get deleteAccount;

  /// No description provided for @settingsFooter.
  ///
  /// In kk, this message translates to:
  /// **'intRvue · Жеке дайындық кеңістігі'**
  String get settingsFooter;

  /// No description provided for @themeSystem.
  ///
  /// In kk, this message translates to:
  /// **'Жүйедегідей'**
  String get themeSystem;

  /// No description provided for @themeLight.
  ///
  /// In kk, this message translates to:
  /// **'Ашық'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In kk, this message translates to:
  /// **'Қараңғы'**
  String get themeDark;

  /// No description provided for @logoutTitle.
  ///
  /// In kk, this message translates to:
  /// **'Аккаунттан шығу?'**
  String get logoutTitle;

  /// No description provided for @logoutBody.
  ///
  /// In kk, this message translates to:
  /// **'Тарих аккаунтта сақталады.\nДайындықты жалғастыру үшін\nқайта кіру қажет.'**
  String get logoutBody;

  /// No description provided for @logoutAction.
  ///
  /// In kk, this message translates to:
  /// **'Шығу'**
  String get logoutAction;

  /// No description provided for @appearanceTitle.
  ///
  /// In kk, this message translates to:
  /// **'Көрініс пен тіл'**
  String get appearanceTitle;

  /// No description provided for @appearanceSubtitle.
  ///
  /// In kk, this message translates to:
  /// **'Таңдау барлық экранға қолданылады.'**
  String get appearanceSubtitle;

  /// No description provided for @appearanceNote.
  ///
  /// In kk, this message translates to:
  /// **'Тақырып барлық экранға бірден қолданылады.\nБұрынғы сұхбаттардың тілі өзгермейді.'**
  String get appearanceNote;

  /// No description provided for @systemColors.
  ///
  /// In kk, this message translates to:
  /// **'Жүйелік түстер'**
  String get systemColors;

  /// No description provided for @systemColorsHint.
  ///
  /// In kk, this message translates to:
  /// **'Android 12+: тұсқағаз түстері. Ескі нұсқаларда intRvue палитрасы.'**
  String get systemColorsHint;

  /// No description provided for @appearanceSaved.
  ///
  /// In kk, this message translates to:
  /// **'Көрініс сақталды.'**
  String get appearanceSaved;

  /// No description provided for @remindersTitle.
  ///
  /// In kk, this message translates to:
  /// **'Дайындыққа уақыт'**
  String get remindersTitle;

  /// No description provided for @remindersSubtitle.
  ///
  /// In kk, this message translates to:
  /// **'Еске салу құрылғыда жергілікті іске асады.'**
  String get remindersSubtitle;

  /// No description provided for @remindersEnable.
  ///
  /// In kk, this message translates to:
  /// **'Еске салуды қосу'**
  String get remindersEnable;

  /// No description provided for @remindersDays.
  ///
  /// In kk, this message translates to:
  /// **'Күндер'**
  String get remindersDays;

  /// No description provided for @remindersTime.
  ///
  /// In kk, this message translates to:
  /// **'Жергілікті уақыт'**
  String get remindersTime;

  /// No description provided for @remindersPermissionTitle.
  ///
  /// In kk, this message translates to:
  /// **'Хабарламаға рұқсат қажет'**
  String get remindersPermissionTitle;

  /// No description provided for @remindersPermissionBody.
  ///
  /// In kk, this message translates to:
  /// **'Android рұқсатын бергеннен кейін таңдалған күндері еске саламыз. Өшірсеңіз, хабарламалар тоқтайды.'**
  String get remindersPermissionBody;

  /// No description provided for @remindersSave.
  ///
  /// In kk, this message translates to:
  /// **'Сақтау және рұқсат беру'**
  String get remindersSave;

  /// No description provided for @remindersTurnedOff.
  ///
  /// In kk, this message translates to:
  /// **'Еске салу өшірілді.'**
  String get remindersTurnedOff;

  /// No description provided for @remindersScheduleFailed.
  ///
  /// In kk, this message translates to:
  /// **'Хабарламаны жоспарлау мүмкін болмады. Қайталап көріңіз.'**
  String get remindersScheduleFailed;

  /// No description provided for @reminderNotificationTitle.
  ///
  /// In kk, this message translates to:
  /// **'Дайындыққа уақыт'**
  String get reminderNotificationTitle;

  /// No description provided for @reminderNotificationBody.
  ///
  /// In kk, this message translates to:
  /// **'Бір сұрақтан бастаңыз — бес минут жеткілікті.'**
  String get reminderNotificationBody;

  /// No description provided for @remindersEnabledTitle.
  ///
  /// In kk, this message translates to:
  /// **'Еске салу қосулы'**
  String get remindersEnabledTitle;

  /// No description provided for @remindersEnabledSubtitle.
  ///
  /// In kk, this message translates to:
  /// **'Хабарламаларға рұқсат берілген.'**
  String get remindersEnabledSubtitle;

  /// No description provided for @remindersEnabledBody.
  ///
  /// In kk, this message translates to:
  /// **'Құрылғының жергілікті уақытымен дайындықты еске саламыз.'**
  String get remindersEnabledBody;

  /// No description provided for @remindersChange.
  ///
  /// In kk, this message translates to:
  /// **'Күн мен уақытты өзгерту'**
  String get remindersChange;

  /// No description provided for @backToSettings.
  ///
  /// In kk, this message translates to:
  /// **'Баптауларға оралу'**
  String get backToSettings;

  /// No description provided for @notificationsOffTitle.
  ///
  /// In kk, this message translates to:
  /// **'Хабарламалар өшірулі'**
  String get notificationsOffTitle;

  /// No description provided for @notificationsOffSubtitle.
  ///
  /// In kk, this message translates to:
  /// **'Жаттығулар әдеттегідей қолжетімді.'**
  String get notificationsOffSubtitle;

  /// No description provided for @notificationsOffBody.
  ///
  /// In kk, this message translates to:
  /// **'Android хабарламаларына рұқсат берілмеген. Еске салу жіберілмейді. Жаттығуды бұғаттамаймыз.'**
  String get notificationsOffBody;

  /// No description provided for @openAndroidSettings.
  ///
  /// In kk, this message translates to:
  /// **'Android баптауларын ашу'**
  String get openAndroidSettings;

  /// No description provided for @remindersPickDay.
  ///
  /// In kk, this message translates to:
  /// **'Кемінде бір күн таңдаңыз.'**
  String get remindersPickDay;

  /// No description provided for @remindersSaved.
  ///
  /// In kk, this message translates to:
  /// **'Еске салу сақталды.'**
  String get remindersSaved;

  /// No description provided for @pickTime.
  ///
  /// In kk, this message translates to:
  /// **'Уақытты таңдау'**
  String get pickTime;

  /// No description provided for @privacySubtitle.
  ///
  /// In kk, this message translates to:
  /// **'Деректеріңіз қалай қолданылатыны.'**
  String get privacySubtitle;

  /// No description provided for @privacyAiTitle.
  ///
  /// In kk, this message translates to:
  /// **'ЖИ-ге не жіберіледі'**
  String get privacyAiTitle;

  /// No description provided for @privacyAiBody.
  ///
  /// In kk, this message translates to:
  /// **'Сұрақ, жауабыңыз және жаттығу\nпараметрлері. Атыңыз, email және\nпароліңіз жіберілмейді.'**
  String get privacyAiBody;

  /// No description provided for @privacyStoredTitle.
  ///
  /// In kk, this message translates to:
  /// **'Не сақталады'**
  String get privacyStoredTitle;

  /// No description provided for @privacyStoredBody.
  ///
  /// In kk, this message translates to:
  /// **'Жауаптар, бағалар және прогресс\nаккаунтта сақталады. Нобай тек\nқұрылғыда тұрады.'**
  String get privacyStoredBody;

  /// No description provided for @privacyManageTitle.
  ///
  /// In kk, this message translates to:
  /// **'Деректерді басқару'**
  String get privacyManageTitle;

  /// No description provided for @privacyManageBody.
  ///
  /// In kk, this message translates to:
  /// **'Сессияны тарихтан, аккаунтты\nбаптаулардан жоюға болады.'**
  String get privacyManageBody;

  /// No description provided for @deleteAccountTitle.
  ///
  /// In kk, this message translates to:
  /// **'Аккаунтты жоясыз ба?'**
  String get deleteAccountTitle;

  /// No description provided for @deleteAccountSubtitle.
  ///
  /// In kk, this message translates to:
  /// **'Бұл әрекетті қайтару мүмкін емес.'**
  String get deleteAccountSubtitle;

  /// No description provided for @deleteAccountBody.
  ///
  /// In kk, this message translates to:
  /// **'Сессиялар мен прогресс жойылады.\nКіру дереу тоқтайды; негізгі дерек\n24 сағат ішінде, резервтік көшірме\n30 күн ішінде тазартылады.'**
  String get deleteAccountBody;

  /// No description provided for @deleteAccountPassword.
  ///
  /// In kk, this message translates to:
  /// **'Растау үшін пароль'**
  String get deleteAccountPassword;

  /// No description provided for @deleteAccountNote.
  ///
  /// In kk, this message translates to:
  /// **'Қате пароль болса,\nаккаунт жойылмайды.'**
  String get deleteAccountNote;

  /// No description provided for @deleteAccountAction.
  ///
  /// In kk, this message translates to:
  /// **'Аккаунтты біржола жою'**
  String get deleteAccountAction;

  /// No description provided for @deleteAccountWrongPassword.
  ///
  /// In kk, this message translates to:
  /// **'Пароль қате. Қайта енгізіңіз.'**
  String get deleteAccountWrongPassword;

  /// No description provided for @accountDeleted.
  ///
  /// In kk, this message translates to:
  /// **'Аккаунт жойылды.'**
  String get accountDeleted;

  /// No description provided for @catalogTitle.
  ///
  /// In kk, this message translates to:
  /// **'Тақырыптар'**
  String get catalogTitle;

  /// No description provided for @searchTopics.
  ///
  /// In kk, this message translates to:
  /// **'Тақырып іздеу'**
  String get searchTopics;

  /// No description provided for @newTraining.
  ///
  /// In kk, this message translates to:
  /// **'Жаңа жаттығу'**
  String get newTraining;

  /// No description provided for @otherDirections.
  ///
  /// In kk, this message translates to:
  /// **'Басқа бағыттар'**
  String get otherDirections;

  /// No description provided for @whatWeReview.
  ///
  /// In kk, this message translates to:
  /// **'Нені қайталаймыз?'**
  String get whatWeReview;

  /// No description provided for @sampleQuestion.
  ///
  /// In kk, this message translates to:
  /// **'Үлгі сұрақ'**
  String get sampleQuestion;

  /// No description provided for @addFavorite.
  ///
  /// In kk, this message translates to:
  /// **'Таңдаулыға қосу'**
  String get addFavorite;

  /// No description provided for @removeFavorite.
  ///
  /// In kk, this message translates to:
  /// **'Таңдаулыдан алу'**
  String get removeFavorite;

  /// No description provided for @practiceWithTopic.
  ///
  /// In kk, this message translates to:
  /// **'Осы тақырыппен жаттығу'**
  String get practiceWithTopic;

  /// No description provided for @addedToFavorites.
  ///
  /// In kk, this message translates to:
  /// **'Таңдаулыға қосылды'**
  String get addedToFavorites;

  /// No description provided for @removedFromFavorites.
  ///
  /// In kk, this message translates to:
  /// **'Таңдаулыдан алынды'**
  String get removedFromFavorites;

  /// No description provided for @open.
  ///
  /// In kk, this message translates to:
  /// **'Ашу'**
  String get open;

  /// No description provided for @searchTitle.
  ///
  /// In kk, this message translates to:
  /// **'Тақырып іздеу'**
  String get searchTitle;

  /// No description provided for @searchSubtitle.
  ///
  /// In kk, this message translates to:
  /// **'Бағыт немесе тақырып атауын жазыңыз.'**
  String get searchSubtitle;

  /// No description provided for @searchLabel.
  ///
  /// In kk, this message translates to:
  /// **'Іздеу'**
  String get searchLabel;

  /// No description provided for @searchHint.
  ///
  /// In kk, this message translates to:
  /// **'Тақырып атауы'**
  String get searchHint;

  /// No description provided for @popularTopics.
  ///
  /// In kk, this message translates to:
  /// **'Жиі ізделетін тақырыптар'**
  String get popularTopics;

  /// No description provided for @searchAllDirections.
  ///
  /// In kk, this message translates to:
  /// **'Frontend · Backend · Mobile · QA\nбойынша іздеуге болады.'**
  String get searchAllDirections;

  /// No description provided for @clearSearch.
  ///
  /// In kk, this message translates to:
  /// **'Іздеуді тазарту'**
  String get clearSearch;

  /// No description provided for @toCatalog.
  ///
  /// In kk, this message translates to:
  /// **'Каталогқа өту'**
  String get toCatalog;

  /// No description provided for @notFoundTitle.
  ///
  /// In kk, this message translates to:
  /// **'Тақырып табылмады'**
  String get notFoundTitle;

  /// No description provided for @notFoundBody.
  ///
  /// In kk, this message translates to:
  /// **'Атауын қысқартып көріңіз немесе\nбағыттар каталогын ашыңыз.\nІздеу басқа деректерді өзгертпейді.'**
  String get notFoundBody;

  /// No description provided for @favoritesTitle.
  ///
  /// In kk, this message translates to:
  /// **'Таңдаулы'**
  String get favoritesTitle;

  /// No description provided for @favoritesSubtitle.
  ///
  /// In kk, this message translates to:
  /// **'Қайталауға сақталған тақырыптар'**
  String get favoritesSubtitle;

  /// No description provided for @remove.
  ///
  /// In kk, this message translates to:
  /// **'Алу'**
  String get remove;

  /// No description provided for @undo.
  ///
  /// In kk, this message translates to:
  /// **'Қайтару'**
  String get undo;

  /// No description provided for @topicRemoved.
  ///
  /// In kk, this message translates to:
  /// **'Тақырып алынды'**
  String get topicRemoved;

  /// No description provided for @favoritesNote.
  ///
  /// In kk, this message translates to:
  /// **'Тақырыпты ашып, жаңа жаттығу\nбастаңыз. Тізімнен алу бұрынғы\nнәтижелеріңізді жоймайды.'**
  String get favoritesNote;

  /// No description provided for @toProfile.
  ///
  /// In kk, this message translates to:
  /// **'Профильге өту'**
  String get toProfile;

  /// No description provided for @favoritesEmptyTitle.
  ///
  /// In kk, this message translates to:
  /// **'Әзірге сақталған тақырып жоқ'**
  String get favoritesEmptyTitle;

  /// No description provided for @favoritesEmptyBody.
  ///
  /// In kk, this message translates to:
  /// **'Каталогтан тақырып ашып,\n«Таңдаулыға қосу» әрекетін\nтаңдаңыз.'**
  String get favoritesEmptyBody;

  /// No description provided for @profileTitle.
  ///
  /// In kk, this message translates to:
  /// **'Менің профилім'**
  String get profileTitle;

  /// No description provided for @profileSubtitle.
  ///
  /// In kk, this message translates to:
  /// **'Дайындық параметрлері'**
  String get profileSubtitle;

  /// No description provided for @editProfile.
  ///
  /// In kk, this message translates to:
  /// **'Профильді өзгерту'**
  String get editProfile;

  /// No description provided for @favoriteTopics.
  ///
  /// In kk, this message translates to:
  /// **'Таңдаулы тақырыптар'**
  String get favoriteTopics;

  /// No description provided for @toSettings.
  ///
  /// In kk, this message translates to:
  /// **'Баптауларға өту'**
  String get toSettings;

  /// No description provided for @editProfileSubtitle.
  ///
  /// In kk, this message translates to:
  /// **'Жаңа сессияларға бастапқы параметр'**
  String get editProfileSubtitle;

  /// No description provided for @saveChanges.
  ///
  /// In kk, this message translates to:
  /// **'Өзгерістерді сақтау'**
  String get saveChanges;

  /// No description provided for @profileSaved.
  ///
  /// In kk, this message translates to:
  /// **'Өзгерістер сақталды. Жаңа сессияларға қолданылады.'**
  String get profileSaved;

  /// No description provided for @discardTitle.
  ///
  /// In kk, this message translates to:
  /// **'Өзгерістерді сақтамайсыз ба?'**
  String get discardTitle;

  /// No description provided for @discardBody.
  ///
  /// In kk, this message translates to:
  /// **'Енгізген өзгерістеріңіз жойылады.'**
  String get discardBody;

  /// No description provided for @discardAction.
  ///
  /// In kk, this message translates to:
  /// **'Сақтамау'**
  String get discardAction;

  /// No description provided for @dbDuplicate.
  ///
  /// In kk, this message translates to:
  /// **'Мұндай жазба бұрыннан бар.'**
  String get dbDuplicate;

  /// No description provided for @dbInUse.
  ///
  /// In kk, this message translates to:
  /// **'Жазба басқа деректерде қолданылып тұр, сондықтан өзгертілмейді.'**
  String get dbInUse;

  /// No description provided for @dbClosed.
  ///
  /// In kk, this message translates to:
  /// **'Деректер қоры жабық. Қосымшаны қайта ашыңыз.'**
  String get dbClosed;

  /// No description provided for @dbGeneric.
  ///
  /// In kk, this message translates to:
  /// **'Деректерді сақтау мүмкін болмады. Қайталап көріңіз.'**
  String get dbGeneric;

  /// No description provided for @dbNoUser.
  ///
  /// In kk, this message translates to:
  /// **'Алдымен аккаунтқа кіріңіз.'**
  String get dbNoUser;

  /// No description provided for @loadError.
  ///
  /// In kk, this message translates to:
  /// **'Деректерді жүктеу мүмкін болмады.'**
  String get loadError;

  /// No description provided for @retry.
  ///
  /// In kk, this message translates to:
  /// **'Қайталау'**
  String get retry;

  /// No description provided for @startupErrorTitle.
  ///
  /// In kk, this message translates to:
  /// **'Деректер қоры ашылмады'**
  String get startupErrorTitle;

  /// No description provided for @startupErrorBody.
  ///
  /// In kk, this message translates to:
  /// **'Құрылғыдағы деректерді оқу мүмкін болмады. Қайталап көріңіз — сақталған деректеріңіз жойылмайды.'**
  String get startupErrorBody;

  /// No description provided for @topicDuplicate.
  ///
  /// In kk, this message translates to:
  /// **'Мұндай атаулы тақырып бар. Басқа атау таңдаңыз.'**
  String get topicDuplicate;

  /// No description provided for @topicReadOnly.
  ///
  /// In kk, this message translates to:
  /// **'Кірістірілген тақырыпты өзгертуге болмайды.'**
  String get topicReadOnly;

  /// No description provided for @questionInUse.
  ///
  /// In kk, this message translates to:
  /// **'Сессияда қолданылған сұрақты жоюға болмайды. Оның мәтінін өзгертуге болады.'**
  String get questionInUse;

  /// No description provided for @topicInUse.
  ///
  /// In kk, this message translates to:
  /// **'Бұл тақырып бойынша сессиялар бар. Алдымен оларды тарихтан жойыңыз.'**
  String get topicInUse;

  /// No description provided for @allLevels.
  ///
  /// In kk, this message translates to:
  /// **'Барлық деңгей'**
  String get allLevels;

  /// No description provided for @filterFavorites.
  ///
  /// In kk, this message translates to:
  /// **'Таңдаулы'**
  String get filterFavorites;

  /// No description provided for @filterMine.
  ///
  /// In kk, this message translates to:
  /// **'Менікі'**
  String get filterMine;

  /// No description provided for @sortLabel.
  ///
  /// In kk, this message translates to:
  /// **'Сұрыптау'**
  String get sortLabel;

  /// No description provided for @resetFilters.
  ///
  /// In kk, this message translates to:
  /// **'Сүзгіні тазарту'**
  String get resetFilters;

  /// No description provided for @catalogEmptyTitle.
  ///
  /// In kk, this message translates to:
  /// **'Сәйкес тақырып жоқ'**
  String get catalogEmptyTitle;

  /// No description provided for @catalogEmptyBody.
  ///
  /// In kk, this message translates to:
  /// **'Іздеу сөзін немесе сүзгілерді өзгертіңіз.'**
  String get catalogEmptyBody;

  /// No description provided for @catalogMineEmptyBody.
  ///
  /// In kk, this message translates to:
  /// **'Әзірге өз тақырыбыңыз жоқ. «Тақырып қосу» арқылы жасаңыз.'**
  String get catalogMineEmptyBody;

  /// No description provided for @addTopic.
  ///
  /// In kk, this message translates to:
  /// **'Тақырып қосу'**
  String get addTopic;

  /// No description provided for @edit.
  ///
  /// In kk, this message translates to:
  /// **'Өзгерту'**
  String get edit;

  /// No description provided for @myTopic.
  ///
  /// In kk, this message translates to:
  /// **'Менің тақырыбым'**
  String get myTopic;

  /// No description provided for @topicFormCreate.
  ///
  /// In kk, this message translates to:
  /// **'Жаңа тақырып'**
  String get topicFormCreate;

  /// No description provided for @topicFormEdit.
  ///
  /// In kk, this message translates to:
  /// **'Тақырыпты өзгерту'**
  String get topicFormEdit;

  /// No description provided for @topicFormSubtitle.
  ///
  /// In kk, this message translates to:
  /// **'Тақырып пен сұрақтар тек сізге көрінеді.'**
  String get topicFormSubtitle;

  /// No description provided for @fieldTopicTitle.
  ///
  /// In kk, this message translates to:
  /// **'Атауы'**
  String get fieldTopicTitle;

  /// No description provided for @fieldSummary.
  ///
  /// In kk, this message translates to:
  /// **'Қысқа сипаттама'**
  String get fieldSummary;

  /// No description provided for @fieldDescription.
  ///
  /// In kk, this message translates to:
  /// **'Толық сипаттама (міндетті емес)'**
  String get fieldDescription;

  /// No description provided for @fieldReviewPoints.
  ///
  /// In kk, this message translates to:
  /// **'Нені қайталаймыз?'**
  String get fieldReviewPoints;

  /// No description provided for @reviewPointsHelper.
  ///
  /// In kk, this message translates to:
  /// **'Әр жолға бір тармақ. Олар бойынша жауап бағаланады.'**
  String get reviewPointsHelper;

  /// No description provided for @questionsSection.
  ///
  /// In kk, this message translates to:
  /// **'Сұрақтар'**
  String get questionsSection;

  /// No description provided for @fieldQuestionText.
  ///
  /// In kk, this message translates to:
  /// **'Сұрақ мәтіні'**
  String get fieldQuestionText;

  /// No description provided for @fieldModelAnswer.
  ///
  /// In kk, this message translates to:
  /// **'Үлгі жауап'**
  String get fieldModelAnswer;

  /// No description provided for @addQuestion.
  ///
  /// In kk, this message translates to:
  /// **'Сұрақ қосу'**
  String get addQuestion;

  /// No description provided for @removeQuestion.
  ///
  /// In kk, this message translates to:
  /// **'Сұрақты алып тастау'**
  String get removeQuestion;

  /// No description provided for @topicCreated.
  ///
  /// In kk, this message translates to:
  /// **'Тақырып қосылды.'**
  String get topicCreated;

  /// No description provided for @topicUpdated.
  ///
  /// In kk, this message translates to:
  /// **'Өзгерістер сақталды.'**
  String get topicUpdated;

  /// No description provided for @topicDeleted.
  ///
  /// In kk, this message translates to:
  /// **'Тақырып жойылды.'**
  String get topicDeleted;

  /// No description provided for @deleteTopic.
  ///
  /// In kk, this message translates to:
  /// **'Тақырыпты жою'**
  String get deleteTopic;

  /// No description provided for @deleteTopicTitle.
  ///
  /// In kk, this message translates to:
  /// **'Тақырыпты жоясыз ба?'**
  String get deleteTopicTitle;

  /// No description provided for @deleteTopicBody.
  ///
  /// In kk, this message translates to:
  /// **'Тақырып, оның сұрақтары және таңдаулыдағы жазбасы жойылады. Бұл әрекетті қайтару мүмкін емес.'**
  String get deleteTopicBody;

  /// No description provided for @topicTitleEmpty.
  ///
  /// In kk, this message translates to:
  /// **'Тақырып атауын енгізіңіз.'**
  String get topicTitleEmpty;

  /// No description provided for @topicTitleTooLong.
  ///
  /// In kk, this message translates to:
  /// **'Атауы 60 таңбадан аспауы керек.'**
  String get topicTitleTooLong;

  /// No description provided for @summaryEmpty.
  ///
  /// In kk, this message translates to:
  /// **'Қысқа сипаттаманы енгізіңіз.'**
  String get summaryEmpty;

  /// No description provided for @questionTextEmpty.
  ///
  /// In kk, this message translates to:
  /// **'Сұрақ мәтінін енгізіңіз.'**
  String get questionTextEmpty;

  /// No description provided for @modelAnswerEmpty.
  ///
  /// In kk, this message translates to:
  /// **'Үлгі жауапты енгізіңіз.'**
  String get modelAnswerEmpty;

  /// No description provided for @atLeastOneQuestion.
  ///
  /// In kk, this message translates to:
  /// **'Кемінде бір сұрақ қалуы керек.'**
  String get atLeastOneQuestion;

  /// No description provided for @privacyOfflineTitle.
  ///
  /// In kk, this message translates to:
  /// **'Интернетсіз жұмыс'**
  String get privacyOfflineTitle;

  /// No description provided for @privacyOfflineBody.
  ///
  /// In kk, this message translates to:
  /// **'Тақырыптар, сессиялар, жауаптар және таңдаулылар құрылғыдағы SQLite қорында сақталады. Қосымша интернетсіз толық жұмыс істейді.'**
  String get privacyOfflineBody;

  /// No description provided for @syncTitle.
  ///
  /// In kk, this message translates to:
  /// **'Бұлттық синхрондау'**
  String get syncTitle;

  /// No description provided for @syncSubtitle.
  ///
  /// In kk, this message translates to:
  /// **'Деректер құрылғыда тұрады, сервер — қосымша көшірме.'**
  String get syncSubtitle;

  /// No description provided for @syncOff.
  ///
  /// In kk, this message translates to:
  /// **'Өшірулі'**
  String get syncOff;

  /// No description provided for @syncIntro.
  ///
  /// In kk, this message translates to:
  /// **'Қоссаңыз, өз тақырыптарыңыз, сессиялар мен таңдаулылар intRvue серверіне көшіріледі. Телефонды ауыстырсаңыз немесе қосымшаны қайта орнатсаңыз, сол email мен парольмен кіріп, бәрін қалпына келтіресіз.'**
  String get syncIntro;

  /// No description provided for @syncServer.
  ///
  /// In kk, this message translates to:
  /// **'Сервер мекенжайы'**
  String get syncServer;

  /// No description provided for @syncServerInvalid.
  ///
  /// In kk, this message translates to:
  /// **'Мекенжай http:// немесе https:// деп басталуы керек.'**
  String get syncServerInvalid;

  /// No description provided for @syncPassword.
  ///
  /// In kk, this message translates to:
  /// **'Аккаунт паролі'**
  String get syncPassword;

  /// No description provided for @syncPasswordHint.
  ///
  /// In kk, this message translates to:
  /// **'Серверде аккаунт болмаса, осы парольмен жасалады.'**
  String get syncPasswordHint;

  /// No description provided for @syncConnect.
  ///
  /// In kk, this message translates to:
  /// **'Синхрондауды қосу'**
  String get syncConnect;

  /// No description provided for @syncNow.
  ///
  /// In kk, this message translates to:
  /// **'Қазір синхрондау'**
  String get syncNow;

  /// No description provided for @syncDisconnect.
  ///
  /// In kk, this message translates to:
  /// **'Ажырату'**
  String get syncDisconnect;

  /// No description provided for @syncDisconnectTitle.
  ///
  /// In kk, this message translates to:
  /// **'Синхрондауды ажырату керек пе?'**
  String get syncDisconnectTitle;

  /// No description provided for @syncDisconnectBody.
  ///
  /// In kk, this message translates to:
  /// **'Құрылғыдағы деректер өзгермейді. Сервердегі көшірме қалады — қайта қосқанда жаңартылады.'**
  String get syncDisconnectBody;

  /// No description provided for @syncAccount.
  ///
  /// In kk, this message translates to:
  /// **'Аккаунт'**
  String get syncAccount;

  /// No description provided for @syncLast.
  ///
  /// In kk, this message translates to:
  /// **'Соңғы синхрондау'**
  String get syncLast;

  /// No description provided for @syncNever.
  ///
  /// In kk, this message translates to:
  /// **'Әлі болған жоқ'**
  String get syncNever;

  /// No description provided for @syncInProgress.
  ///
  /// In kk, this message translates to:
  /// **'Синхрондалуда…'**
  String get syncInProgress;

  /// No description provided for @syncDone.
  ///
  /// In kk, this message translates to:
  /// **'Синхрондалды.'**
  String get syncDone;

  /// No description provided for @syncAuto.
  ///
  /// In kk, this message translates to:
  /// **'Өзгерістер желі болғанда өздігінен жіберіледі.'**
  String get syncAuto;

  /// No description provided for @syncErrOffline.
  ///
  /// In kk, this message translates to:
  /// **'Сервер қолжетімсіз. Деректер құрылғыда сақталды — желі пайда болғанда қайталаймыз.'**
  String get syncErrOffline;

  /// No description provided for @syncErrCredentials.
  ///
  /// In kk, this message translates to:
  /// **'Серверде бұл email басқа парольмен тіркелген.'**
  String get syncErrCredentials;

  /// No description provided for @syncErrUnauthorized.
  ///
  /// In kk, this message translates to:
  /// **'Сеанс ескірді. Синхрондауды қайта қосыңыз.'**
  String get syncErrUnauthorized;

  /// No description provided for @syncErrWeak.
  ///
  /// In kk, this message translates to:
  /// **'Сервер бұл парольді қабылдамайды: кемінде 8 таңба, әріп пен сан.'**
  String get syncErrWeak;

  /// No description provided for @syncErrRateLimited.
  ///
  /// In kk, this message translates to:
  /// **'Тым көп әрекет. 15 минуттан кейін қайталаңыз.'**
  String get syncErrRateLimited;

  /// No description provided for @syncErrServer.
  ///
  /// In kk, this message translates to:
  /// **'Серверде қате болды. Кейінірек қайталаңыз.'**
  String get syncErrServer;

  /// No description provided for @syncDeleteRemoteFailed.
  ///
  /// In kk, this message translates to:
  /// **'Сервердегі көшірмені жою мүмкін болмады — желіні тексеріңіз. Тек құрылғыдан жою үшін алдымен синхрондауды ажыратыңыз.'**
  String get syncDeleteRemoteFailed;

  /// No description provided for @syncRestored.
  ///
  /// In kk, this message translates to:
  /// **'Деректер бұлттан қалпына келтірілді.'**
  String get syncRestored;

  /// No description provided for @privacySyncTitle.
  ///
  /// In kk, this message translates to:
  /// **'Бұлттық көшірме'**
  String get privacySyncTitle;

  /// No description provided for @privacySyncBody.
  ///
  /// In kk, this message translates to:
  /// **'Тек өзіңіз қоссаңыз ғана: деректер\nintRvue серверіне жіберіледі. Пароль\nсерверде PBKDF2 хэшімен сақталады.'**
  String get privacySyncBody;

  /// No description provided for @syncErrTimeout.
  ///
  /// In kk, this message translates to:
  /// **'Сервер тым ұзақ жауап бермеді. Қайталап көріңіз.'**
  String get syncErrTimeout;

  /// No description provided for @syncErrNotFound.
  ///
  /// In kk, this message translates to:
  /// **'Тақырып серверде жоқ — басқа құрылғыда жойылған болуы мүмкін.'**
  String get syncErrNotFound;

  /// No description provided for @syncErrTitleTaken.
  ///
  /// In kk, this message translates to:
  /// **'Серверде осындай атаулы тақырып бар.'**
  String get syncErrTitleTaken;

  /// No description provided for @syncErrConflict.
  ///
  /// In kk, this message translates to:
  /// **'Бұл тақырып серверде бұрыннан бар.'**
  String get syncErrConflict;

  /// No description provided for @syncErrInvalid.
  ///
  /// In kk, this message translates to:
  /// **'Сервер деректі қабылдамады. Өрістерді тексеріңіз.'**
  String get syncErrInvalid;

  /// No description provided for @cloudTitle.
  ///
  /// In kk, this message translates to:
  /// **'Бұлттағы тақырыптар'**
  String get cloudTitle;

  /// No description provided for @cloudSubtitle.
  ///
  /// In kk, this message translates to:
  /// **'Сервердегі көшірме: тізімді жаңартып, тақырыпты жіберіп, өзгертіп не жоя аласыз.'**
  String get cloudSubtitle;

  /// No description provided for @cloudLoading.
  ///
  /// In kk, this message translates to:
  /// **'Серверден жүктелуде…'**
  String get cloudLoading;

  /// No description provided for @cloudEmpty.
  ///
  /// In kk, this message translates to:
  /// **'Серверде әзірге өз тақырыптарыңыз жоқ.'**
  String get cloudEmpty;

  /// No description provided for @cloudAccount.
  ///
  /// In kk, this message translates to:
  /// **'Сервердегі аккаунт'**
  String get cloudAccount;

  /// No description provided for @cloudRegistered.
  ///
  /// In kk, this message translates to:
  /// **'Тіркелген'**
  String get cloudRegistered;

  /// No description provided for @cloudLoadedAt.
  ///
  /// In kk, this message translates to:
  /// **'Жаңартылды'**
  String get cloudLoadedAt;

  /// No description provided for @cloudRefresh.
  ///
  /// In kk, this message translates to:
  /// **'Жаңарту'**
  String get cloudRefresh;

  /// No description provided for @cloudOnServer.
  ///
  /// In kk, this message translates to:
  /// **'Серверде'**
  String get cloudOnServer;

  /// No description provided for @cloudDeviceOnly.
  ///
  /// In kk, this message translates to:
  /// **'Тек осы құрылғыда'**
  String get cloudDeviceOnly;

  /// No description provided for @cloudSynced.
  ///
  /// In kk, this message translates to:
  /// **'Синхрондалған'**
  String get cloudSynced;

  /// No description provided for @cloudNewerInCloud.
  ///
  /// In kk, this message translates to:
  /// **'Серверде жаңарақ'**
  String get cloudNewerInCloud;

  /// No description provided for @cloudNewerOnDevice.
  ///
  /// In kk, this message translates to:
  /// **'Құрылғыда жаңарақ'**
  String get cloudNewerOnDevice;

  /// No description provided for @cloudOnlyRemote.
  ///
  /// In kk, this message translates to:
  /// **'Тек серверде'**
  String get cloudOnlyRemote;

  /// No description provided for @cloudUpload.
  ///
  /// In kk, this message translates to:
  /// **'Серверге жіберу'**
  String get cloudUpload;

  /// No description provided for @cloudRename.
  ///
  /// In kk, this message translates to:
  /// **'Атауын өзгерту'**
  String get cloudRename;

  /// No description provided for @cloudRenameField.
  ///
  /// In kk, this message translates to:
  /// **'Сервердегі атауы'**
  String get cloudRenameField;

  /// No description provided for @cloudDelete.
  ///
  /// In kk, this message translates to:
  /// **'Серверден жою'**
  String get cloudDelete;

  /// No description provided for @cloudDeleteTitle.
  ///
  /// In kk, this message translates to:
  /// **'Тақырыпты серверден жою керек пе?'**
  String get cloudDeleteTitle;

  /// No description provided for @cloudDeleteBody.
  ///
  /// In kk, this message translates to:
  /// **'Тақырып серверден, ал синхрондаудан кейін барлық құрылғыдан жойылады.'**
  String get cloudDeleteBody;

  /// No description provided for @cloudUploaded.
  ///
  /// In kk, this message translates to:
  /// **'Серверге жіберілді.'**
  String get cloudUploaded;

  /// No description provided for @cloudRenamed.
  ///
  /// In kk, this message translates to:
  /// **'Атауы өзгертілді.'**
  String get cloudRenamed;

  /// No description provided for @cloudDeleted.
  ///
  /// In kk, this message translates to:
  /// **'Серверден жойылды.'**
  String get cloudDeleted;

  /// No description provided for @cloudSent.
  ///
  /// In kk, this message translates to:
  /// **'Серверге де жіберілді.'**
  String get cloudSent;

  /// No description provided for @cloudDeferred.
  ///
  /// In kk, this message translates to:
  /// **'Серверге кейін жіберіледі.'**
  String get cloudDeferred;

  /// No description provided for @cloudActions.
  ///
  /// In kk, this message translates to:
  /// **'Әрекеттер'**
  String get cloudActions;

  /// No description provided for @levelBeginner.
  ///
  /// In kk, this message translates to:
  /// **'Бастапқы'**
  String get levelBeginner;

  /// No description provided for @levelJunior.
  ///
  /// In kk, this message translates to:
  /// **'Junior'**
  String get levelJunior;

  /// No description provided for @levelMiddle.
  ///
  /// In kk, this message translates to:
  /// **'Middle'**
  String get levelMiddle;

  /// No description provided for @sortTitleAsc.
  ///
  /// In kk, this message translates to:
  /// **'Атауы: А–Я'**
  String get sortTitleAsc;

  /// No description provided for @sortTitleDesc.
  ///
  /// In kk, this message translates to:
  /// **'Атауы: Я–А'**
  String get sortTitleDesc;

  /// No description provided for @sortNewest.
  ///
  /// In kk, this message translates to:
  /// **'Жаңасы алдымен'**
  String get sortNewest;

  /// No description provided for @sortWeakest.
  ///
  /// In kk, this message translates to:
  /// **'Әлсізі алдымен'**
  String get sortWeakest;

  /// No description provided for @historyNewest.
  ///
  /// In kk, this message translates to:
  /// **'Жаңасы алдымен'**
  String get historyNewest;

  /// No description provided for @historyOldest.
  ///
  /// In kk, this message translates to:
  /// **'Ескісі алдымен'**
  String get historyOldest;

  /// No description provided for @historyScoreHigh.
  ///
  /// In kk, this message translates to:
  /// **'Балы: жоғарыдан'**
  String get historyScoreHigh;

  /// No description provided for @historyScoreLow.
  ///
  /// In kk, this message translates to:
  /// **'Балы: төменнен'**
  String get historyScoreLow;

  /// No description provided for @month1.
  ///
  /// In kk, this message translates to:
  /// **'қаңтар'**
  String get month1;

  /// No description provided for @month2.
  ///
  /// In kk, this message translates to:
  /// **'ақпан'**
  String get month2;

  /// No description provided for @month3.
  ///
  /// In kk, this message translates to:
  /// **'наурыз'**
  String get month3;

  /// No description provided for @month4.
  ///
  /// In kk, this message translates to:
  /// **'сәуір'**
  String get month4;

  /// No description provided for @month5.
  ///
  /// In kk, this message translates to:
  /// **'мамыр'**
  String get month5;

  /// No description provided for @month6.
  ///
  /// In kk, this message translates to:
  /// **'маусым'**
  String get month6;

  /// No description provided for @month7.
  ///
  /// In kk, this message translates to:
  /// **'шілде'**
  String get month7;

  /// No description provided for @month8.
  ///
  /// In kk, this message translates to:
  /// **'тамыз'**
  String get month8;

  /// No description provided for @month9.
  ///
  /// In kk, this message translates to:
  /// **'қыркүйек'**
  String get month9;

  /// No description provided for @month10.
  ///
  /// In kk, this message translates to:
  /// **'қазан'**
  String get month10;

  /// No description provided for @month11.
  ///
  /// In kk, this message translates to:
  /// **'қараша'**
  String get month11;

  /// No description provided for @month12.
  ///
  /// In kk, this message translates to:
  /// **'желтоқсан'**
  String get month12;

  /// No description provided for @weekdayShort1.
  ///
  /// In kk, this message translates to:
  /// **'Дс'**
  String get weekdayShort1;

  /// No description provided for @weekdayFull1.
  ///
  /// In kk, this message translates to:
  /// **'Дүйсенбі'**
  String get weekdayFull1;

  /// No description provided for @weekdayShort2.
  ///
  /// In kk, this message translates to:
  /// **'Сс'**
  String get weekdayShort2;

  /// No description provided for @weekdayFull2.
  ///
  /// In kk, this message translates to:
  /// **'Сейсенбі'**
  String get weekdayFull2;

  /// No description provided for @weekdayShort3.
  ///
  /// In kk, this message translates to:
  /// **'Ср'**
  String get weekdayShort3;

  /// No description provided for @weekdayFull3.
  ///
  /// In kk, this message translates to:
  /// **'Сәрсенбі'**
  String get weekdayFull3;

  /// No description provided for @weekdayShort4.
  ///
  /// In kk, this message translates to:
  /// **'Бс'**
  String get weekdayShort4;

  /// No description provided for @weekdayFull4.
  ///
  /// In kk, this message translates to:
  /// **'Бейсенбі'**
  String get weekdayFull4;

  /// No description provided for @weekdayShort5.
  ///
  /// In kk, this message translates to:
  /// **'Жм'**
  String get weekdayShort5;

  /// No description provided for @weekdayFull5.
  ///
  /// In kk, this message translates to:
  /// **'Жұма'**
  String get weekdayFull5;

  /// No description provided for @weekdayShort6.
  ///
  /// In kk, this message translates to:
  /// **'Сб'**
  String get weekdayShort6;

  /// No description provided for @weekdayFull6.
  ///
  /// In kk, this message translates to:
  /// **'Сенбі'**
  String get weekdayFull6;

  /// No description provided for @weekdayShort7.
  ///
  /// In kk, this message translates to:
  /// **'Жс'**
  String get weekdayShort7;

  /// No description provided for @weekdayFull7.
  ///
  /// In kk, this message translates to:
  /// **'Жексенбі'**
  String get weekdayFull7;

  /// No description provided for @fieldRequired.
  ///
  /// In kk, this message translates to:
  /// **'{field} толтырылуы керек.'**
  String fieldRequired(String field);

  /// No description provided for @answerTooLong.
  ///
  /// In kk, this message translates to:
  /// **'Жауап {max} таңбадан аспауы керек.'**
  String answerTooLong(int max);

  /// No description provided for @greeting.
  ///
  /// In kk, this message translates to:
  /// **'Сәлем, {name}!'**
  String greeting(String name);

  /// No description provided for @directionTopics.
  ///
  /// In kk, this message translates to:
  /// **'{direction} тақырыптары'**
  String directionTopics(String direction);

  /// No description provided for @continueWithTopics.
  ///
  /// In kk, this message translates to:
  /// **'Жалғастыру · {n} тақырып'**
  String continueWithTopics(int n);

  /// No description provided for @questionsCount.
  ///
  /// In kk, this message translates to:
  /// **'{n} сұрақ'**
  String questionsCount(int n);

  /// No description provided for @progressOf.
  ///
  /// In kk, this message translates to:
  /// **'{current} / {total} сұрақ'**
  String progressOf(int current, int total);

  /// No description provided for @feedbackHeader.
  ///
  /// In kk, this message translates to:
  /// **'{n} / {total} · Жауап талдауы'**
  String feedbackHeader(int n, int total);

  /// No description provided for @disputeSubtitle.
  ///
  /// In kk, this message translates to:
  /// **'{n}-сұрақ · {topic}'**
  String disputeSubtitle(int n, String topic);

  /// No description provided for @summaryCounts.
  ///
  /// In kk, this message translates to:
  /// **'{answered} жауап · {skipped} өткізу · {assessed} бағаланды'**
  String summaryCounts(int answered, int skipped, int assessed);

  /// No description provided for @summaryFormula.
  ///
  /// In kk, this message translates to:
  /// **'Нәтиже: {earned} / {max} × 100 = {score}.'**
  String summaryFormula(int earned, int max, String score);

  /// No description provided for @incompleteCounts.
  ///
  /// In kk, this message translates to:
  /// **'{answered} жауап · {skipped} өткізу\n{assessed} бағаланды · {pending} бағалау күтілуде'**
  String incompleteCounts(int answered, int skipped, int assessed, int pending);

  /// No description provided for @recommendScore.
  ///
  /// In kk, this message translates to:
  /// **'{score} / 100 · Осы сессияда'**
  String recommendScore(String score);

  /// No description provided for @whyLowest.
  ///
  /// In kk, this message translates to:
  /// **'{n} жауаптағы ең төмен балл осы тақырыпта.'**
  String whyLowest(int n);

  /// No description provided for @whyMissing.
  ///
  /// In kk, this message translates to:
  /// **'{n} жауапта толық ашылмаған: {missing}.'**
  String whyMissing(int n, String missing);

  /// No description provided for @filters.
  ///
  /// In kk, this message translates to:
  /// **'Сүзгілер · {n}'**
  String filters(int n);

  /// No description provided for @assessedPoints.
  ///
  /// In kk, this message translates to:
  /// **'Бағаланды · {total} / 15'**
  String assessedPoints(int total);

  /// No description provided for @savedAnswerHeader.
  ///
  /// In kk, this message translates to:
  /// **'{n} / {total} · Сақталған жауап'**
  String savedAnswerHeader(int n, int total);

  /// No description provided for @lastSessions.
  ///
  /// In kk, this message translates to:
  /// **'Соңғы {n} толық сессия'**
  String lastSessions(int n);

  /// No description provided for @completeSessions.
  ///
  /// In kk, this message translates to:
  /// **'{n} толық сессия'**
  String completeSessions(int n);

  /// No description provided for @averageScore.
  ///
  /// In kk, this message translates to:
  /// **'Орташа балл: {score}'**
  String averageScore(String score);

  /// No description provided for @catalogSubtitle.
  ///
  /// In kk, this message translates to:
  /// **'{direction} · Дайындық кітапханасы'**
  String catalogSubtitle(String direction);

  /// No description provided for @found.
  ///
  /// In kk, this message translates to:
  /// **'{n} тақырып табылды'**
  String found(int n);

  /// No description provided for @averageShort.
  ///
  /// In kk, this message translates to:
  /// **'орт. {score}'**
  String averageShort(String score);

  /// No description provided for @topicCount.
  ///
  /// In kk, this message translates to:
  /// **'{n} тақырып'**
  String topicCount(int n);

  /// No description provided for @questionN.
  ///
  /// In kk, this message translates to:
  /// **'{n}-сұрақ'**
  String questionN(int n);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['kk', 'ru'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'kk':
      return AppLocalizationsKk();
    case 'ru':
      return AppLocalizationsRu();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
