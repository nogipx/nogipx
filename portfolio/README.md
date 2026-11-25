# Портфолио nogipx

Компоненты страницы находятся в `lib/`. Сборка использует серверный рендерер Jaspr и записывает HTML в `web/index.html`. Папку `web/` можно открыть локально или раздавать статическим веб-сервером.

Из каталога `portfolio/`:

```sh
fvm dart pub get
fvm dart run --define=jaspr.flags.release=true tool/build.dart
```
