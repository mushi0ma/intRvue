# intRvue

Android-приложение для текстовой подготовки к IT-собеседованиям (интерфейс на казахском и русском).
Курсовой проект КМ07: практические работы №1–6.

| Папка | Что внутри |
|---|---|
| `app/` | Flutter-приложение: feature-based структура, Material 3 по Figma, go_router, SQLite, kk/ru |
| `server/` | REST API на Dart (shelf) + PostgreSQL: синхронизация и ресурс тем ([endpoint-ы](server/README.md)) |

## Быстрый старт

```bash
docker compose up -d db                     # PostgreSQL 17 на 127.0.0.1:5433
(cd server && dart run bin/server.dart)     # API на 127.0.0.1:8787
cd app && flutter run                       # эмулятор Android
```

Демо-аккаунт: `aidana@example.com` / `intrvue2026`. Без сервера приложение полностью работает офлайн.

## Проверка

```bash
cd app && flutter analyze && flutter test   # 276 тестов (e2e синхронизации — при запущенном PostgreSQL)
cd server && dart test                      # 19 интеграционных тестов на PostgreSQL
```

## Состояние и напоминания (№6)

**State management — Provider.** Репозитории (`AuthRepository`, `SessionRepository`, `TopicRepository`, `SettingsRepository`, `SyncRepository`) — это `ChangeNotifier`, которые раздаются через `MultiProvider` в `app/lib/app/app.dart`. Экраны подписываются через `context.watch`. Состояние приложения — это данные SQLite и настройки, а не сложные потоки событий, поэтому BLoC добавил бы шаблонный код без выгоды. Riverpod потребовал бы переписать уже покрытый тестами слой.

**Уведомления.** Используются `flutter_local_notifications`, `permission_handler` и `timezone`.
- Разрешение запрашивается в момент включения напоминаний. При отказе открывается экран с переходом в настройки Android; после возврата разрешение проверяется заново.
- Содержание напоминания строится из данных (`ReminderPlan`):
  - есть незавершённая сессия → предлагаем её продолжить;
  - иначе берём самую слабую тему последней полной сессии и открываем тренировку по ней;
  - если сессия уже была сегодня, сегодняшнее напоминание пропускается.
- `ReminderCoordinator` пересчитывает расписание при изменении сессий, настроек или аккаунта, а также при каждом запуске. При выходе из аккаунта все напоминания отменяются.
