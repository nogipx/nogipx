# Недооценённые библиотеки (эвристика по названию)

Источник: `pub_audit_output/package_downloads.csv` (месячные скачивания).

> Критерий «недооценённости» здесь намеренно простой: **интересное/перспективное имя + сравнительно низкие скачивания**. Это не финальный технический due diligence, а shortlist для ручной проверки.

| package | downloads/month | почему может быть интересен (по названию) |
|---|---:|---|
| y_crdt | 513 | CRDT — горячая тема для offline-first и коллаборативных приложений. |
| sqlite_crdt | 293 | Комбинация SQLite + CRDT может закрывать сложные сценарии синхронизации на клиенте. |
| drift_crdt | 160 | Потенциально полезно для Flutter/Drift-экосистемы с конфликт-резолвом. |
| pgvector | 44 | Векторные сценарии/embeddings в тренде (RAG, semantic search). |
| realm_dart_vector_db | 47 | Векторное хранилище в Dart-стеке — ниша с высоким потенциалом. |
| wasm_wit_component | 514 | WASM/WIT-компоненты — перспективно для переносимых модулей. |
| pdfrx_wasm | 267 | PDF + WASM может быть полезно для web/desktop без нативных зависимостей. |
| wallet_core_bindings_wasm | 271 | Крипто/кошельки + WASM — интересная инфраструктурная связка. |
| task_scheduler | 65 | Планировщики задач часто становятся «скрытой» core-зависимостью. |
| pg_job_queue | 26 | Очереди на Postgres — практичный подход для бэкенд-задач. |
| auto_reconnect_websocket | 22 | Надёжные reconnect-стратегии полезны почти в любом real-time продукте. |
| dart_mqtt_broker | 23 | MQTT-инструменты важны для IoT и edge-сценариев. |
| http_retry | 231 | Retry-логика — must-have в сетевых клиентах, хороший utility-класс. |
| flutter_performance_monitor | 29 | Мониторинг перформанса в приложении — часто undervalued область. |
| memory_monitor_overlay | 21 | Lightweight overlay для памяти полезен в отладке на реальных девайсах. |
| fl_query_devtools | 35 | Devtools для data/query-слоя повышают DX в сложных приложениях. |
| koin_devtools | 49 | DI + devtools может сильно улучшить observability архитектуры. |
| markdown_syntax_highlighter | 24 | Утилиты вокруг Markdown стабильно востребованы в контентных продуктах. |
| docx_to_markdown | 22 | Конвертация DOCX→Markdown — практичный use-case для internal tooling. |
| redis_storage_plug | 67 | Storage abstraction для Redis часто переиспользуется в сервисах. |
| kafka_dart | 78 | Kafka в Dart-экосистеме всё ещё редкость, но потенциал большой. |
| sqlite3_driver | 21 | Низкоуровневые драйверы БД — важный фундамент для higher-level пакетов. |
| yaml_config | 21 | Простые config-пакеты могут вырасти в массовые зависимости. |
| benchmark_runner | 192 | Инструменты бенчмаркинга полезны для инженерных команд и библиотек. |
| retryable | 125 | Обобщённый retry-подход часто становится частью internal platform SDK. |

## Как использовать список дальше

1. Проверить README, дату последнего релиза, issue velocity.
2. Посмотреть конкурентов и API-эргономику.
3. Быстро протипировать в одном pet/internal проекте.
4. Если «зашло» — добавить в watchlist и отслеживать динамику скачиваний.
