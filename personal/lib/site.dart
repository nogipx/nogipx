import 'package:jaspr/dom.dart';
import 'package:jaspr/server.dart';

class PersonalSite extends StatelessComponent {
  const PersonalSite({super.key});

  @override
  Component build(BuildContext context) {
    return Document(
      lang: 'ru',
      title: 'Nogipx · Разработчик',
      meta: const {
        'description':
            'Портфолио разработчика nogipx: продуктовые сервисы, Dart, архитектура, девопс.',
      },
      styles: _styles,
      body: const _Page(),
    );
  }
}

class _Page extends StatelessComponent {
  const _Page();

  @override
  Component build(BuildContext context) {
    return Component.element(
      tag: 'main',
      classes: 'page',
      children: const [
        HeroSection(),
        HighlightsSection(),
        ProjectsSection(),
        TrajectorySection(),
        ContactSection(),
      ],
    );
  }
}

class HeroSection extends StatelessComponent {
  const HeroSection({super.key});

  @override
  Component build(BuildContext context) {
    return section([
      div([
        span([Component.text('Привет! Я')], classes: 'pill'),
        h1([
          Component.text('nogipx — разработчик, который тащит продукты в прод'),
        ], classes: 'title'),
        p([
          Component.text(
            'Работаю на стыке бэкенда, фронтенда и инфраструктуры: проектирую архитектуру, пишу чистый код и '
            'довожу сервисы до стабильного продакшена.',
          ),
        ], classes: 'lead'),
        div([
          a(
            [Component.text('Связаться')],
            classes: 'btn primary',
            href: 'mailto:hi@nogipx.dev',
            attributes: {'rel': 'noopener'},
          ),
          a(
            [Component.text('Посмотреть проекты')],
            classes: 'btn ghost',
            href: '#projects',
          ),
        ], classes: 'cta-row'),
        div([
          _StatCard(title: 'Фокус', value: 'Dart · Flutter · Shelf · Jaspr'),
          _StatCard(
            title: 'Подход',
            value: 'Продуктовая разработка, много автоматизации',
          ),
          _StatCard(
            title: 'Формат',
            value: 'Remote-first, прозрачные процессы',
          ),
        ], classes: 'hero-meta'),
      ], classes: 'hero'),
      div([
        Component.text('Стек:'),
        ..._stack.map((item) => span([Component.text(item)], classes: 'chip')),
      ], classes: 'stack-line'),
    ], classes: 'section hero-section');
  }
}

class HighlightsSection extends StatelessComponent {
  const HighlightsSection({super.key});

  @override
  Component build(BuildContext context) {
    return section([
      div([
        span([Component.text('Как работаю')], classes: 'pill'),
        h2([Component.text('Строю систему, а не просто фичи')]),
        p([
          Component.text(
            'От идеи и прототипа до поддерживаемого продукта — люблю оформлять процессы, автоматику и понятные '
            'контракты между сервисами.',
          ),
        ], classes: 'muted'),
      ], classes: 'section-header'),
      div([
        for (final highlight in _highlights)
          _HighlightCard(highlight: highlight),
      ], classes: 'card-grid'),
    ], classes: 'section');
  }
}

class ProjectsSection extends StatelessComponent {
  const ProjectsSection({super.key});

  @override
  Component build(BuildContext context) {
    return section([
      div([
        span([Component.text('Проекты')], classes: 'pill'),
        h2([Component.text('Выжимка свежих инициатив')]),
        p([
          Component.text(
            'Ниже — подборка, которая показывает мой стиль и любимые задачи.',
          ),
        ], classes: 'muted'),
      ], classes: 'section-header'),
      div(
        [for (final project in _projects) _ProjectCard(project: project)],
        classes: 'card-grid',
        attributes: {'id': 'projects'},
      ),
    ], classes: 'section');
  }
}

class TrajectorySection extends StatelessComponent {
  const TrajectorySection({super.key});

  @override
  Component build(BuildContext context) {
    return section([
      div([
        span([Component.text('Подход к росту')], classes: 'pill'),
        h2([Component.text('Что держит мою скорость')]),
        p([
          Component.text(
            'Комбинирую глубину в разработке с инженерной дисциплиной: аккуратные API, метрики, прогрев продакшена.',
          ),
        ], classes: 'muted'),
      ], classes: 'section-header'),
      ul([
        for (final item in _trajectory) _TrajectoryItem(item: item),
      ], classes: 'timeline'),
    ], classes: 'section');
  }
}

class ContactSection extends StatelessComponent {
  const ContactSection({super.key});

  @override
  Component build(BuildContext context) {
    return section([
      div([
        span([Component.text('Контакты')], classes: 'pill'),
        h2([Component.text('Есть идея? Напиши мне')]),
        p([
          Component.text(
            'Помогу собрать дорожную карту, ускорить разработку и довести фичу до релиза без лишней бюрократии.',
          ),
        ], classes: 'muted'),
      ], classes: 'section-header'),
      div([
        _ContactCard(
          title: 'Почта',
          value: 'hi@nogipx.dev',
          href: 'mailto:hi@nogipx.dev',
          hint: 'Отвечаю в течение рабочего дня',
        ),
        _ContactCard(
          title: 'GitHub',
          value: 'github.com/nogipx',
          href: 'https://github.com/nogipx',
          hint: 'Код, пет-проекты и сниппеты',
        ),
        _ContactCard(
          title: 'Telegram',
          value: '@nogipx',
          href: 'https://t.me/nogipx',
          hint: 'Быстрые созвоны и синки',
        ),
      ], classes: 'contact-grid'),
    ], classes: 'section');
  }
}

class _HighlightCard extends StatelessComponent {
  const _HighlightCard({required this.highlight});

  final _Highlight highlight;

  @override
  Component build(BuildContext context) {
    return article([
      div([Component.text(highlight.title)], classes: 'card-title'),
      p([Component.text(highlight.description)], classes: 'muted'),
      div([
        for (final tag in highlight.tags)
          span([Component.text(tag)], classes: 'chip subtle'),
      ], classes: 'tag-row'),
    ], classes: 'card');
  }
}

class _ProjectCard extends StatelessComponent {
  const _ProjectCard({required this.project});

  final _Project project;

  @override
  Component build(BuildContext context) {
    return article([
      div([
        div([Component.text(project.title)], classes: 'card-title'),
        if (project.link != null)
          a(
            [Component.text('Открыть')],
            classes: 'btn ghost small',
            href: project.link!,
            target: Target.blank,
            attributes: {'rel': 'noopener'},
          ),
      ], classes: 'card-header'),
      p([Component.text(project.description)], classes: 'muted'),
      div([
        for (final tag in project.tags)
          span([Component.text(tag)], classes: 'chip subtle'),
      ], classes: 'tag-row'),
    ], classes: 'card project');
  }
}

class _TrajectoryItem extends StatelessComponent {
  const _TrajectoryItem({required this.item});

  final _Trajectory item;

  @override
  Component build(BuildContext context) {
    return li([
      div([
        span([Component.text(item.period)], classes: 'pill muted-pill'),
        div([Component.text(item.title)], classes: 'card-title'),
      ], classes: 'timeline-header'),
      p([Component.text(item.description)], classes: 'muted'),
    ], classes: 'timeline-item');
  }
}

class _ContactCard extends StatelessComponent {
  const _ContactCard({
    required this.title,
    required this.value,
    required this.href,
    required this.hint,
  });

  final String title;
  final String value;
  final String href;
  final String hint;

  @override
  Component build(BuildContext context) {
    return div([
      div([Component.text(title)], classes: 'card-title'),
      a([Component.text(value)], classes: 'link-strong', href: href),
      p([Component.text(hint)], classes: 'muted'),
    ], classes: 'card contact');
  }
}

class _StatCard extends StatelessComponent {
  const _StatCard({required this.title, required this.value});

  final String title;
  final String value;

  @override
  Component build(BuildContext context) {
    return div([
      span([Component.text(title)], classes: 'muted'),
      div([Component.text(value)], classes: 'stat-value'),
    ], classes: 'stat-card');
  }
}

class _Highlight {
  const _Highlight({
    required this.title,
    required this.description,
    required this.tags,
  });

  final String title;
  final String description;
  final List<String> tags;
}

class _Project {
  const _Project({
    required this.title,
    required this.description,
    required this.tags,
    this.link,
  });

  final String title;
  final String description;
  final List<String> tags;
  final String? link;
}

class _Trajectory {
  const _Trajectory({
    required this.period,
    required this.title,
    required this.description,
  });

  final String period;
  final String title;
  final String description;
}

const _stack = [
  'Dart',
  'Flutter',
  'Shelf',
  'Jaspr',
  'PostgreSQL',
  'gRPC/REST',
  'CI/CD',
  'Docker',
];

const _highlights = [
  _Highlight(
    title: 'Довожу продукт до релиза',
    description:
        'Планирую релизы с метриками, прогреваю продакшен, автоматизирую проверки и катю фичи без простоя.',
    tags: ['релиз-менеджмент', 'метрики', 'канареечные выкладки'],
  ),
  _Highlight(
    title: 'Проектирую понятные API',
    description:
        'Ставлю контракты между сервисами, документирую через OpenAPI, держу стабильность версий.',
    tags: ['api-first', 'версионирование', 'документация'],
  ),
  _Highlight(
    title: 'Укладываю сложность в архитектуру',
    description:
        'Чищу зависимости, ввожу модульность, настраиваю сборку и тестовую пирамиду под команду.',
    tags: ['архитектура', 'тесты', 'обслуживаемость'],
  ),
];

const _projects = [
  _Project(
    title: 'Developer Dashboard',
    description:
        'Веб-панель на Jaspr + Shelf, которая агрегирует health-check, метрики и статус задач в одном окне.',
    tags: ['jaspr', 'shelf', 'observability'],
    link: 'https://github.com/nogipx',
  ),
  _Project(
    title: 'Feature Flags Toolkit',
    description:
        'Лёгкий сервис фичефлагов с REST/gRPC API, роллбэком и прогревом кеша для фронтенда и мобилок.',
    tags: ['dart', 'grpc', 'redis'],
    link: 'https://github.com/nogipx',
  ),
  _Project(
    title: 'Automation Playbook',
    description:
        'Набор CI/CD шаблонов (Docker, тесты, линтеры), чтобы новые сервисы сразу уходили в прод предсказуемо.',
    tags: ['ci/cd', 'docker', 'quality gates'],
    link: 'https://github.com/nogipx',
  ),
];

const _trajectory = [
  _Trajectory(
    period: 'Сейчас',
    title: 'Выстраиваю продуктовые сервисы на Dart',
    description:
        'Собираю стек вокруг Shelf и Jaspr, закрываю интеграции, CI/CD и наблюдаемость под бизнес-задачу.',
  ),
  _Trajectory(
    period: 'Ранее',
    title: 'Склеивал команды и процессы',
    description:
        'Запускал delivery-практики, документировал API, вводил code review и чёткие SLA на поддержку.',
  ),
  _Trajectory(
    period: 'С самого старта',
    title: 'Решал задачи end-to-end',
    description:
        'Люблю, когда идея доезжает до пользователей: быстро прототипирую, валидирую и довожу до стабильной версии.',
  ),
];

final _styles = [
  css.import(
    'https://fonts.googleapis.com/css2?family=Space+Grotesk:wght@400;500;600;700&family=JetBrains+Mono:wght@500&display=swap',
  ),
  css('body').styles(
    margin: Spacing.zero,
    padding: Spacing.zero,
    backgroundColor: const Color('#050915'),
    color: const Color('#e8edf7'),
    fontFamily: const FontFamily.list([
      FontFamily('Space Grotesk'),
      FontFamilies.uiSansSerif,
    ]),
    lineHeight: 1.7.em,
    raw: {
      'background':
          'radial-gradient(circle at 20% 20%, rgba(87,133,255,0.18), transparent 30%), radial-gradient(circle at 80% 0%, rgba(102,223,207,0.16), transparent 28%), linear-gradient(180deg, #050915 0%, #060a12 45%, #050915 100%)',
      '-webkit-font-smoothing': 'antialiased',
    },
  ),
  css('h1').styles(fontSize: 42.px, margin: Spacing.zero, lineHeight: 1.2.em),
  css('h2').styles(fontSize: 28.px, margin: Spacing.zero, lineHeight: 1.3.em),
  css('p').styles(margin: Spacing.zero),
  css(
    'a',
  ).styles(textDecoration: TextDecoration.none, color: const Color('#c8d7ff')),
  css('.page').styles(
    minHeight: 100.vh,
    display: Display.flex,
    flexDirection: FlexDirection.column,
    gap: Gap.all(32.px),
    padding: Padding.symmetric(vertical: 40.px, horizontal: 24.px),
  ),
  css('.section').styles(
    width: Unit.percent(100),
    maxWidth: 1100.px,
    margin: Spacing.symmetric(horizontal: Unit.auto),
    padding: Padding.all(24.px),
    backgroundColor: const Color.rgba(12, 15, 27, 0.78),
    border: Border.all(color: Color.rgba(255, 255, 255, 0.06), width: 1.px),
    radius: BorderRadius.all(Radius.circular(18.px)),
    shadow: BoxShadow.combine([
      BoxShadow(
        offsetX: 0.px,
        offsetY: 14.px,
        blur: 30.px,
        color: Color.rgba(0, 0, 0, 0.35),
      ),
      BoxShadow(
        offsetX: 0.px,
        offsetY: 1.px,
        blur: 0.px,
        spread: 1.px,
        color: Color.rgba(255, 255, 255, 0.02),
      ),
    ]),
    backdropFilter: Filter.blur(16.px),
  ),
  css('.section-header').styles(
    display: Display.flex,
    flexDirection: FlexDirection.column,
    gap: Gap.all(12.px),
    margin: Spacing.only(bottom: 16.px),
  ),
  css('.pill').styles(
    display: Display.inlineFlex,
    alignItems: AlignItems.center,
    gap: Gap.all(8.px),
    padding: Padding.symmetric(vertical: 6.px, horizontal: 12.px),
    backgroundColor: const Color.rgba(101, 117, 255, 0.12),
    border: Border.all(color: Color.rgba(124, 167, 255, 0.35), width: 1.px),
    radius: BorderRadius.circular(999.px),
    fontSize: 13.px,
    letterSpacing: 0.5.px,
    textTransform: TextTransform.upperCase,
    color: const Color('#c4d1ff'),
  ),
  css('.muted').styles(color: const Color('#9da8bb')),
  css('.muted-pill').styles(
    backgroundColor: const Color.rgba(255, 255, 255, 0.06),
    border: Border.all(color: Color.rgba(255, 255, 255, 0.15), width: 1.px),
    color: const Color('#d8deea'),
  ),
  css('.title').styles(fontSize: 42.px, fontWeight: FontWeight.w700),
  css('.lead').styles(fontSize: 18.px, color: const Color('#cdd7e6')),
  css(
    '.cta-row',
  ).styles(display: Display.flex, flexWrap: FlexWrap.wrap, gap: Gap.all(12.px)),
  css('.btn').styles(
    display: Display.inlineFlex,
    alignItems: AlignItems.center,
    gap: Gap.all(10.px),
    padding: Padding.symmetric(vertical: 12.px, horizontal: 16.px),
    border: Border.all(color: Color.rgba(255, 255, 255, 0.08), width: 1.px),
    radius: BorderRadius.circular(12.px),
    fontWeight: FontWeight.w600,
    textDecoration: TextDecoration.none,
    color: const Color('#e8edf7'),
    backgroundColor: const Color.rgba(255, 255, 255, 0.04),
    shadow: BoxShadow(
      offsetX: 0.px,
      offsetY: 6.px,
      blur: 16.px,
      color: Color.rgba(0, 0, 0, 0.3),
    ),
  ),
  css('.btn.primary').styles(
    backgroundColor: const Color('#76e4c2'),
    color: const Color('#041221'),
    shadow: BoxShadow(
      offsetX: 0.px,
      offsetY: 14.px,
      blur: 28.px,
      color: Color.rgba(118, 228, 194, 0.32),
    ),
  ),
  css(
    '.btn.ghost',
  ).styles(backgroundColor: const Color.rgba(255, 255, 255, 0.05)),
  css('.btn.small').styles(
    padding: Padding.symmetric(vertical: 8.px, horizontal: 12.px),
  ),
  css('.hero').styles(
    display: Display.flex,
    flexDirection: FlexDirection.column,
    gap: Gap.all(18.px),
  ),
  css('.hero-meta').styles(
    display: Display.grid,
    gridTemplate: GridTemplate(
      columns: GridTracks([
        GridTrack.repeat(TrackRepeat.autoFit, [
          GridTrack(TrackSize.minmax(TrackSize(220.px), const TrackSize.fr(1))),
        ]),
      ]),
    ),
    gap: Gap.all(12.px),
  ),
  css('.stat-card').styles(
    padding: Padding.all(14.px),
    border: Border.all(color: Color.rgba(255, 255, 255, 0.08), width: 1.px),
    radius: BorderRadius.circular(12.px),
    backgroundColor: const Color.rgba(255, 255, 255, 0.02),
    display: Display.flex,
    flexDirection: FlexDirection.column,
    gap: Gap.all(6.px),
  ),
  css('.stat-value').styles(fontSize: 16.px, fontWeight: FontWeight.w600),
  css('.stack-line').styles(
    display: Display.flex,
    alignItems: AlignItems.center,
    gap: Gap.all(8.px),
    flexWrap: FlexWrap.wrap,
    margin: Spacing.only(top: 4.px),
    fontSize: 14.px,
    color: const Color('#b6c3d8'),
  ),
  css('.chip').styles(
    display: Display.inlineFlex,
    alignItems: AlignItems.center,
    padding: Padding.symmetric(vertical: 6.px, horizontal: 10.px),
    border: Border.all(color: Color.rgba(255, 255, 255, 0.12), width: 1.px),
    radius: BorderRadius.circular(10.px),
    backgroundColor: const Color.rgba(255, 255, 255, 0.04),
    fontSize: 13.px,
    color: const Color('#d3def0'),
  ),
  css('.chip.subtle').styles(
    border: Border.all(color: Color.rgba(255, 255, 255, 0.08), width: 1.px),
    backgroundColor: const Color.rgba(255, 255, 255, 0.02),
  ),
  css('.card-grid').styles(
    display: Display.grid,
    gridTemplate: GridTemplate(
      columns: GridTracks([
        GridTrack.repeat(TrackRepeat.autoFit, [
          GridTrack(TrackSize.minmax(TrackSize(260.px), const TrackSize.fr(1))),
        ]),
      ]),
    ),
    gap: Gap.all(14.px),
  ),
  css('.card').styles(
    padding: Padding.all(16.px),
    border: Border.all(color: Color.rgba(255, 255, 255, 0.08), width: 1.px),
    radius: BorderRadius.circular(14.px),
    backgroundColor: const Color.rgba(255, 255, 255, 0.03),
    display: Display.flex,
    flexDirection: FlexDirection.column,
    gap: Gap.all(12.px),
    shadow: BoxShadow(
      offsetX: 0.px,
      offsetY: 10.px,
      blur: 24.px,
      color: Color.rgba(0, 0, 0, 0.22),
    ),
  ),
  css('.card-header').styles(
    display: Display.flex,
    alignItems: AlignItems.center,
    justifyContent: JustifyContent.spaceBetween,
    gap: Gap.all(8.px),
  ),
  css('.card-title').styles(
    fontSize: 18.px,
    fontWeight: FontWeight.w700,
    color: const Color('#e8edf7'),
  ),
  css(
    '.tag-row',
  ).styles(display: Display.flex, flexWrap: FlexWrap.wrap, gap: Gap.all(8.px)),
  css('.timeline').styles(
    listStyle: ListStyle.none,
    padding: Spacing.zero,
    margin: Spacing.zero,
    display: Display.flex,
    flexDirection: FlexDirection.column,
    gap: Gap.all(12.px),
  ),
  css('.timeline-item').styles(
    padding: Padding.all(14.px),
    border: Border.all(color: Color.rgba(255, 255, 255, 0.08), width: 1.px),
    radius: BorderRadius.circular(12.px),
    backgroundColor: const Color.rgba(255, 255, 255, 0.02),
    display: Display.flex,
    flexDirection: FlexDirection.column,
    gap: Gap.all(8.px),
  ),
  css('.timeline-header').styles(
    display: Display.flex,
    alignItems: AlignItems.center,
    gap: Gap.all(10.px),
  ),
  css('.contact-grid').styles(
    display: Display.grid,
    gridTemplate: GridTemplate(
      columns: GridTracks([
        GridTrack.repeat(TrackRepeat.autoFit, [
          GridTrack(TrackSize.minmax(TrackSize(240.px), const TrackSize.fr(1))),
        ]),
      ]),
    ),
    gap: Gap.all(12.px),
  ),
  css('.link-strong').styles(
    color: const Color('#9ad6ff'),
    fontWeight: FontWeight.w600,
    fontFamily: const FontFamily.list([
      FontFamily('JetBrains Mono'),
      FontFamilies.monospace,
    ]),
  ),
];
