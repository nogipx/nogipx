import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import 'rpc_demo.dart';

const _github = 'https://github.com/nogipx';
const _telegram = 'https://t.me/nogipx';

class Portfolio extends StatelessComponent {
  const Portfolio({super.key});

  @override
  Component build(BuildContext context) => div(id: 'top', [
    a(href: '#main', classes: 'skip', [Component.text('К содержанию')]),
    header(classes: 'mast', [
      div(classes: 'width mast-inner', [
        a(href: '#top', classes: 'brand', [
          img(src: 'mark.svg', alt: ''),
          Component.text('nogipx'),
        ]),
        nav(
          attributes: {'aria-label': 'Навигация'},
          [
            a(href: '#projects', [Component.text('Проекты')]),
            a(href: '#work', [Component.text('Достижения')]),
            a(href: _github, classes: 'git', [Component.text('GitHub')]),
          ],
        ),
      ]),
    ]),
    main_(id: 'main', [
      section(classes: 'hero', [
        div(classes: 'width stage', [
          img(
            classes: 'optic',
            src: 'art/signal.webp',
            alt: '',
            attributes: {
              'fetchpriority': 'high',
              'width': '1536',
              'height': '1024',
            },
          ),
          div(classes: 'intro', [
            p(classes: 'role', [Component.text('Архитектор ПО')]),
            h1([Component.text('Карим'), br(), Component.text('Маматказин')]),
            p(classes: 'bio', [
              Component.text(
                'Пишу на Dart. Проектирую протоколы связи, инструменты для модульных приложений и синхронизацию заметок в Obsidian.',
              ),
            ]),
            div(classes: 'actions', [
              a(href: '#projects', classes: 'button', [
                Component.text('Смотреть проекты'),
              ]),
              a(href: _telegram, classes: 'quiet', [
                Component.text('Связаться'),
              ]),
            ]),
          ]),
        ]),
      ]),
      section(id: 'projects', classes: 'width catalog', [
        h2([Component.text('Избранные проекты')]),
        article(classes: 'featured', [
          div(classes: 'feature-copy', [
            p(classes: 'category', [Component.text('Библиотека для Dart')]),
            h3([Component.text('rpc_dart')]),
            p([
              Component.text(
                'Описываешь контракт один раз. Тот же вызов работает между изолятами в приложении и между браузером и сервером. Меняется только транспорт.',
              ),
            ]),
            div(classes: 'links', [
              a(href: 'https://pub.dev/packages/rpc_dart', [
                Component.text('Пакет на pub.dev'),
              ]),
              a(href: '$_github/rpc_dart', [Component.text('GitHub')]),
            ]),
          ]),
          const RpcDemo(),
        ]),
        div(classes: 'pair', [
          const ProjectCard(
            name: 'Parlance',
            area: 'Архитектура приложений',
            image: 'parlance',
            copy: 'Модули, плагины и агенты говорят на одном языке. У каждого состояния есть владелец, а журнал помогает проследить цепочку событий до исходной команды.',
            home: 'https://pub.dev/packages/parlance',
            homeLabel: 'Пакет на pub.dev',
            repo: 'parlance',
          ),
          const ProjectCard(
            name: 'Rhyolite Sync',
            area: 'Сервис для Obsidian',
            image: 'rhyolite',
            copy: 'Редактируешь одну заметку на телефоне и ноутбуке. Движок объединяет правки посимвольно, а содержимое шифруется ещё до отправки на сервер.',
            home: 'https://rhyolite.nogipx.dev/',
            homeLabel: 'Сайт проекта',
            repo: 'rhyolite_sync',
          ),
        ]),
      ]),
      section(id: 'work', classes: 'width work', [
        h2([Component.text('Достижения')]),
        div(classes: 'rows', [
          for (final (title, copy, linkText, url) in _milestones)
            details(open: title == _milestones.first.$1, [
              summary([Component.text(title)]),
              p([Component.text(copy)]),
              a(href: url, [Component.text(linkText)]),
            ]),
        ]),
      ]),
    ]),
    footer([
      div(classes: 'width foot', [
        p([Component.text('Карим Маматказин')]),
        div(classes: 'links', [
          a(href: _telegram, [Component.text('Telegram')]),
          a(href: _github, [Component.text('GitHub')]),
        ]),
      ]),
    ]),
  ]);
}

const _milestones = [
  (
    'Выпустил семейство RPC-пакетов',
    'Вынес транспорты в отдельные пакеты. Можно подключить к контракту HTTP, WebSocket или WebAssembly и выбрать нужный вид обмена сообщениями.',
    'Пакеты на pub.dev',
    'https://pub.dev/publishers/rpc.nogipx.dev/packages',
  ),
  (
    'Сделал журнал событий Parlance',
    'В просмотрщике можно раскрыть цепочку событий и воспроизвести её по шагам. Так видно, какая команда запустила изменение и какой модуль на него отреагировал.',
    'Просмотрщик журнала',
    '$_github/parlance/tree/main/apps/journal_viewer',
  ),
  (
    'Открыл сервер синхронизации для Obsidian',
    'Опубликовал движок Rhyolite Sync и сервер для самостоятельного развёртывания. Можно хранить зашифрованные заметки в своей инфраструктуре и подключать к ней устройства через плагин Obsidian.',
    'Инструкция по развёртыванию',
    '$_github/rhyolite_sync/blob/main/SELFHOST.md',
  ),
];

class ProjectCard extends StatelessComponent {
  const ProjectCard({
    required this.name,
    required this.area,
    required this.image,
    required this.copy,
    required this.home,
    required this.homeLabel,
    required this.repo,
    super.key,
  });
  final String name, area, image, copy, home, homeLabel, repo;

  @override
  Component build(BuildContext context) =>
      article(classes: 'project-card $image', [
        div(classes: 'cover', [
          img(src: 'art/$image.webp', alt: ''),
          div(classes: 'cover-type', [
            p(classes: 'category', [Component.text(area)]),
            h3([
              a(href: home, [Component.text(name)]),
            ]),
          ]),
        ]),
        p(classes: 'description', [Component.text(copy)]),
        div(classes: 'links', [
          a(href: home, [Component.text(homeLabel)]),
          a(href: '$_github/$repo', [Component.text('GitHub')]),
        ]),
      ]);
}
