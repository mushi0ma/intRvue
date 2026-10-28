# intRvue

Android-приложение для текстовой подготовки к IT-собеседованиям (интерфейс на казахском и русском).
Курсовой проект КМ07: практические работы №1–4.

| Папка | Что внутри |
|---|---|
| `app/` | Flutter-приложение: feature-based структура, Material 3 по Figma, go_router, SQLite, kk/ru |
| `server/` | Сервер синхронизации на Dart (shelf) + PostgreSQL |
| `design/figma-export/` | экспорт макетов Figma |
| `deliverables/` | отчёты по практическим, сверка требований, аудит UI/UX, сравнение с Figma |

## Быстрый старт

```bash
docker compose up -d db                     # PostgreSQL 17 на 127.0.0.1:5433
(cd server && dart run bin/server.dart)     # API на 127.0.0.1:8787
cd app && flutter run                       # эмулятор Android
```

Демо-аккаунт: `aidana@example.com` / `intrvue2026`. Без сервера приложение полностью работает офлайн.

## Проверка

```bash
cd app && flutter analyze && flutter test   # 239 тестов (e2e синхронизации — при запущенном PostgreSQL)
cd server && dart test                      # 12 интеграционных тестов на PostgreSQL
```

Документы: [сверка требований](deliverables/requirements-check.md) ·
[синхронизация](deliverables/sync/README.md) · [практическая №4](deliverables/practical-4/README.md) ·
[аудит UI/UX](deliverables/ui-ux-audit/README.md) · [Figma vs Flutter](deliverables/figma-vs-flutter/README.md)
