# intRvue — Flutter қосымшасы

Практикалық жұмыс №3: мобильді қосымшаның құрылымы мен навигациясы.
Figma макеттері (`da7ZdVRSLL9qiknZN6Ngrd`) негізінде жасалған Android қосымшасы.

## Іске қосу

```bash
cd app
flutter pub get
flutter run            # Android құрылғы немесе эмулятор
flutter test           # валидация, навигация және экран скриншоттары
```

Демо аккаунт: `aidana@example.com` / `intrvue2026`. Жаңа аккаунт тіркеуге де болады.
Деректер құрылғыдағы SQLite қорында (`intrvue.db`, `sqflite`) сақталады, интернет қажет емес.
ЖИ бағасы — жергілікті имитация.

## Құрылым (feature-based)

```
lib/
├── main.dart                 SharedPreferences → IntRvueApp
├── app/                      MaterialApp.router, Provider, маршруттар
│   ├── app.dart
│   ├── router.dart           go_router: барлық экран, redirect (кіру тексерісі)
│   ├── routes.dart           маршрут атаулары
│   └── app_shell.dart        NavigationBar / NavigationRail (≥ 600 dp)
├── core/                     барлық экранға ортақ
│   ├── constants/app_strings.dart   интерфейстің барлық мәтіні
│   ├── theme/                түстер (M3, жарық/қараңғы), Inter типографикасы, өлшемдер
│   ├── utils/                validators.dart, formatters.dart
│   └── widgets/              reusable виджеттер (AppPage, AppButton, AppTextField, …)
├── data/
│   ├── local/                SQLite: схема (6 кесте), ашу/толтыру, мапперлер, қателер
│   ├── models/               UserProfile, Topic, Question, Assessment, InterviewSession
│   ├── mock/                 бірінші іске қосудағы бастапқы деректер
│   ├── repositories/         Auth, Topic, Session (SQLite), Settings (prefs)
│   └── services/             AssessmentService — ЖИ бағасының имитациясы
└── features/                 әр экран өз бумасында
    ├── splash/  onboarding/  auth/  profile/  home/
    ├── topics/               List, Detail, Search, Favorites
    ├── interview/            тақырып → параметр → келісім → сұхбат → талдау
    ├── results/              қорытынды, ұсыным, сақталған жауаптар
    ├── history/  progress/  settings/
```

## Экрандар мен маршруттар

| Тапсырма | Экран | Маршрут |
|---|---|---|
| Splash | S00 | `/splash` |
| Onboarding | O1–O3 | `/onboarding` |
| Login / Registration | S02, S03, S04 | `/login`, `/register`, `/forgot-password` |
| Home | S06 | `/home` (төменгі навигация) |
| List / Detail | S16, S17 | `/topics`, `/topics/:id` |
| Create / Edit | S05, S22, тақырып формасы | `/profile-setup`, `/profile/edit`, `/topics/new`, `/topics/:id/edit` |
| Search / Favorites | S18, S19 | `/search`, `/favorites` |
| Profile / Settings | S20, S15 | `/profile`, `/settings` |
| Сұхбат сценарийі | S07–S12 | `/practice/*`, `/interview`, `/sessions/:id/*` |
| Тарих / Прогресс | S13, S14 | `/history`, `/progress` |

Төменгі навигация: `StatefulShellRoute.indexedStack` — төрт бөлім өз стегін сақтайды.

## Валидация

`core/utils/validators.dart`: бос өріс, email форматы, бос пароль, пароль ережесі
(8 таңба, әріп пен сан), парольдерді салыстыру, жауап ұзындығы (1–4000).
Хабарламалар `S` класында, өріс астында көрсетіледі.

## Бейімділік

- Мазмұн ені ≤ 560 dp, кең экранда ортада; ≥ 600 dp — NavigationRail.
- Барлық экран айналады, төменгі батырмалар пернетақтадан жоғары тұрады.
- 360 dp + 200% мәтін және 800 dp тесттері (`test/screens_golden_test.dart`).

## Figma-мен салыстыру

`flutter test --update-goldens test/screens_golden_test.dart` әр экранды 412 × 892
өлшемде салады (`test/goldens/light|dark|adaptive`).

## Локализация (kk / ru)

Мәтіндердің көзі — `tool/l10n/kk.json` және `tool/l10n/ru.json` (параметрлі
мәтіндер `tool/l10n/gen_arb.py` ішіндегі `FUNCS` тізімінде). Өзгерткен соң:

```bash
python3 tool/l10n/gen_arb.py && flutter gen-l10n
```

Скрипт `lib/l10n/app_*.arb` пен `lib/core/constants/app_strings.dart` (S фасады)
файлдарын жасайды. Тіл «Көрініс пен тіл» экранында немесе таныстыру экранында ауысады.

## Еске салу, жүйелік түстер, парольді қалпына келтіру

- Еске салу: `lib/data/services/reminder_scheduler.dart` (Android-та
  flutter_local_notifications, басқа платформада — Noop).
- Material You: `dynamic_color`, «Жүйелік түстер» қосқышы.
- Сілтеме: `intrvue://app/reset-password?token=…` → «Жаңа пароль» экраны.
