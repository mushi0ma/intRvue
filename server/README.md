# intRvue server

REST API на Dart (shelf) с PostgreSQL 17. Приложение работает офлайн на SQLite,
а сервер хранит копию данных и связывает устройства одного аккаунта.

```bash
docker compose up -d db            # из корня репозитория: PostgreSQL на 127.0.0.1:5433
dart run bin/server.dart           # API на 127.0.0.1:8787 (эмулятор: http://10.0.2.2:8787)
dart test                          # интеграционные тесты на настоящем PostgreSQL
```

## Endpoint-ы

Все ответы — JSON. Ошибка: `{"error": "<код>", "message": "..."}`.
Защищённые маршруты требуют заголовок `Authorization: Bearer <token>`.

| Метод | Путь | Операция | Успех | Ошибки |
|---|---|---|---|---|
| GET | `/health` | состояние сервера и PostgreSQL | 200 | 500 |
| POST | `/v1/auth/register` | регистрация, выдача токена | 201 | 400, 409 `email_taken` |
| POST | `/v1/auth/login` | вход, выдача токена | 200 | 401 `invalid_credentials`, 429 |
| POST | `/v1/auth/logout` | отзыв токена | 204 | 401 |
| GET | `/v1/account` | профиль аккаунта | 200 | 401 |
| DELETE | `/v1/account` | удаление аккаунта и всех данных | 204 | 401 |
| POST | `/v1/sync` | слияние снимка устройства, ответ — полный снимок | 200 | 400, 401 |
| GET | `/v1/topics` | список тем пользователя с вопросами | 200 | 401 |
| GET | `/v1/topics/{id}` | одна тема | 200 | 401, 404 |
| POST | `/v1/topics` | создание темы, заголовок `Location` | 201 | 400, 401, 409 `conflict` / `title_taken` |
| PATCH | `/v1/topics/{id}` | частичное изменение: только переданные поля | 200 | 400, 401, 404, 409 `title_taken` |
| DELETE | `/v1/topics/{id}` | удаление темы и tombstone для синхронизации | 204 | 401, 404 |
| GET | `/v1/live` | WebSocket: синхронизация и уведомления `changed` в реальном времени | 101 | 401 (до upgrade) |

### Тема (`/v1/topics`)

```json
{
  "id": "u1-1761700000000",
  "title": "Docker негіздері",
  "summary": "Image, container, volume",
  "direction": "backend",
  "level": "junior",
  "description": "…",
  "review_points": ["Image", "Volume"],
  "sample_question": "Volume не үшін керек?",
  "questions": [
    {
      "id": "u1-…-q0",
      "position": 0,
      "text": "Volume не үшін керек?",
      "hint": "",
      "model_answer": "…",
      "concepts": [{ "label": "Volume", "keywords": ["volume"] }]
    }
  ],
  "created_at": "2026-10-29T10:00:00.000Z",
  "updated_at": "2026-10-30T12:30:00.123Z"
}
```

- `direction`: `frontend | backend | mobile | qa`; `level`: `beginner | junior | middle`.
- POST: `id` можно не передавать, тогда его создаст сервер. `updated_at` всегда ставит сервер.
- PATCH: передаются только изменяемые поля. Если передан `questions`, список заменяется целиком.

### Как REST связан с синхронизацией

Ресурс `/v1/topics` работает с теми же таблицами, что и `/v1/sync`:
- POST и PATCH ставят `updated_at` по часам сервера, поэтому по правилу «последнее изменение побеждает» при следующей синхронизации новая версия попадёт на все устройства.
- DELETE записывает tombstone, и устройство со старой копией не «воскресит» тему.

### WebSocket `/v1/live`

Заголовки: `Authorization: Bearer <token>`, необязательный `x-intrvue-device: <id>`.
Ping сервера — каждые 20 с. Сообщения — JSON-объекты с полем `type`.

| Направление | Сообщение | Смысл |
|---|---|---|
| сервер → клиент | `{"type":"ready"}` | соединение принято |
| клиент → сервер | `{"type":"sync","id":1,"body":{…снимок…}}` | то же, что `POST /v1/sync` |
| сервер → клиент | `{"type":"synced","id":1,"snapshot":{…}}` | полный снимок после слияния |
| сервер → клиент | `{"type":"error","id":1,"status":400,"error":"invalid_request","message":"…"}` | `status` и `error` — как в HTTP |
| сервер → клиент | `{"type":"changed"}` | данные аккаунта изменились на другом устройстве |
| клиент ↔ сервер | `{"type":"ping"}` / `{"type":"pong"}` | проверка связи |

- `changed` отправляется всем соединениям аккаунта, кроме устройства-источника, и только если снимок действительно изменился. Источником может быть сокет, `/v1/sync` или REST `/v1/topics`.
- Коды закрытия:
  - `4401` — токен отозван (выход, удаление аккаунта); клиент не переподключается;
  - `4503` — сервер перезапускается; клиент переподключается с паузой.
