# Пакеты-кандидаты для продукта уровня «Obsidian Sync» (по названиям + скачиваниям)

Ниже — shortlist из `package_downloads.csv` с фокусом на:
- синхронизацию между устройствами,
- работу с BaaS/готовыми backend,
- шифрование и безопасное хранение,
- офлайн-first и разрешение конфликтов.

> Важно: это **предварительный фильтр** по названиям и метрике скачиваний/мес. Финальный выбор нужно делать после проверки API, лицензии, активности репозитория и качества документации.

## 1) BaaS / готовые backend

| package | downloads/month | зачем смотреть |
|---|---:|---|
| firebase_core | 2,688,122 | Базовая интеграция Firebase, часто фундамент стека. |
| firebase_auth | 1,050,589 | Авторизация пользователей (email/social и т.д.). |
| supabase | 367,899 | Open-source BaaS, хорош для Postgres-first подхода. |
| supabase_flutter | 363,168 | Flutter-обвязка Supabase для мобильных/desktop клиентов. |
| amplify_flutter | 90,504 | AWS Amplify (Auth/API/Storage) для managed backend. |
| amplify_auth_cognito | 85,788 | Готовая auth-инфраструктура на AWS. |
| amplify_storage_s3 | 21,460 | Хранилище вложений/бэкапов (аналог storage-слоя sync). |
| appwrite | 13,965 | Open-source BaaS-опция с self-host возможностью. |
| dart_appwrite | 11,419 | Dart SDK для Appwrite. |
| pocketbase | 9,216 | Лёгкий self-host backend для MVP/малых команд. |
| brick_offline_first_with_supabase | 749 | Offline-first слой поверх Supabase. |
| brick_supabase | 736 | Потенциально полезен для data-sync паттернов. |
| pocketbase_drift | 647 | Связка PocketBase + локальная БД (дрейф/репликация). |

## 2) Шифрование, ключи, безопасность

| package | downloads/month | зачем смотреть |
|---|---:|---|
| flutter_secure_storage | 1,999,111 | Безопасное хранение ключей/токенов на устройстве. |
| encrypt | 618,323 | Простые сценарии прикладного шифрования данных. |
| jwt_decode | 483,954 | Разбор JWT (для auth/session flows). |
| cryptography | 265,501 | Набор криптопримитивов, более «низкоуровневый» контроль. |
| oauth2 | 248,851 | OAuth2 флоу для интеграции внешних провайдеров auth. |
| webcrypto | 17,541 | Криптография для web-рантайма. |
| flutter_keychain | 13,671 | Доступ к keychain/secure storage в iOS-сценариях. |

## 3) Sync / конфликт-резолв / offline-first

| package | downloads/month | зачем смотреть |
|---|---:|---|
| y_crdt | 513 | CRDT-подход для коллаборативного редактирования и merge без lock. |
| sqlite_crdt | 293 | Локальная БД + CRDT для устойчивой синхронизации. |
| crdt_sync | 183 | Узкоспециализированный слой синхронизации CRDT-данных. |
| postgres_crdt | 162 | Потенциальный серверный CRDT-бэкенд на Postgres. |
| drift_crdt | 160 | Сценарии CRDT поверх Drift в Flutter-экосистеме. |
| hive_crdt | 122 | CRDT-подход для Hive-based локального хранения. |
| drift_sync | 623 | Sync-ориентированная интеграция для Drift. |
| flutter_offline_sync_queue | 147 | Очередь офлайн-операций для последующей отправки. |
| flutter_offline_queue | 160 | Типовой offline queue-паттерн для запросов/ивентов. |

## 4) Локальное хранилище, транспорт и надёжность

| package | downloads/month | зачем смотреть |
|---|---:|---|
| sqlite3 | 910,238 | Надёжная локальная БД для кеша/реплик/локальных индексов. |
| hive | 877,086 | Быстрое локальное key-value хранение. |
| drift | 595,511 | Типобезопасный data-layer с миграциями и удобным API. |
| realm_dart | 28,839 | Альтернативный локальный движок с sync-потенциалом. |
| realm | 28,649 | Realm-экосистема для offline-oriented приложений. |
| mqtt_client | 59,098 | Realtime-транспорт (особенно для IoT/низкой связности). |
| sse_channel | 46,637 | SSE-транспорт для сервер→клиент потока обновлений. |
| queue | 41,645 | Управление очередями задач/операций sync-пайплайна. |
| concurrent_queue | 4,323 | Контроль конкурентности воркеров/репликации. |
| async_queue | 2,943 | Асинхронная очередь для фоновых операций. |
| drift_postgres | 2,486 | Мост между локальным Drift и Postgres-сервером. |
| websocket_universal | 1,441 | Универсальный websocket-транспорт для live sync. |
| retry | 1,664,938 | Базовый retry-механизм для нестабильной сети. |
| http_retry | 231 | Retry для HTTP-запросов в sync/job workflows. |
| retryable | 125 | Обобщённые retry-паттерны для платформенного слоя. |

## Рекомендованный «первый стек» для PoC

1. **Хранилище клиента**: `drift` + `sqlite3`.
2. **Безопасность**: `flutter_secure_storage` + `cryptography` (или `encrypt` для простого старта).
3. **Auth/BaaS**: `supabase_flutter` (или `firebase_auth`/`firebase_core`, если уже в Firebase-экосистеме).
4. **Sync-движок**: начать с queue + retry (`queue`, `retry`), затем добавить CRDT-слой (`y_crdt` / `drift_crdt`) при появлении коллаборативных конфликтов.
5. **Realtime**: `websocket_universal` или `sse_channel` в зависимости от backend-протокола.
