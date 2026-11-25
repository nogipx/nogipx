# Личная страница nogipx

Сборка Jaspr создаёт `web/index.html`. Страница открывается локально. Для статического хостинга достаточно папки `web/`.

Из каталога `portfolio/`:

```sh
fvm dart pub get
fvm dart run --define=jaspr.flags.release=true tool/build.dart
```
