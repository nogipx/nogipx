import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

class Profile extends StatelessComponent {
  const Profile({super.key});

  @override
  Component build(BuildContext context) => main_([
    header([
      div(classes: 'identity', [
        img(src: 'enso.png', alt: '', width: 96, height: 96, classes: 'enso'),
        h1([
          Component.text('Karmarov '),
          span(classes: 'handle', [Component.text('@nogipx')]),
        ]),
      ]),
      p([
        Component.text(
          'Архитектор ПО. Пишу приложения на Flutter и библиотеки на Dart.',
        ),
      ]),
    ]),
    nav(
      id: 'projects',
      attributes: {'aria-label': 'Мои проекты'},
      [
        for (final (name, purpose, url) in _projects)
          a(href: url, classes: 'entry', [
            strong([Component.text(name)]),
            span([Component.text(purpose)]),
          ]),
      ],
    ),
    footer(classes: 'contacts', [
      a(href: 'https://t.me/nogipx', [Component.text('Telegram')]),
      a(href: 'https://github.com/nogipx', [Component.text('GitHub')]),
      a(href: 'mailto:nogipx@gmail.com', [Component.text('Почта')]),
    ]),
  ]);
}

const _projects = [
  (
    'Rhyolite Sync',
    'Зашифрованная синхронизация заметок Obsidian',
    'https://rhyolite.nogipx.dev/',
  ),
  ('rpc_dart', 'Удалённые вызовы и потоки на Dart', 'https://rpc.nogipx.dev/'),
  (
    'Parlance',
    'Общий язык для модулей и плагинов',
    'https://pub.dev/packages/parlance',
  ),
];
