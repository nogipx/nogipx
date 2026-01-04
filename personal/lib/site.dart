import 'package:jaspr/dom.dart';
import 'package:jaspr/server.dart';
import 'package:rpc_dart_data/rpc_dart_data.dart';

import 'resume_data.dart';
import 'stats.dart';

class PersonalSite extends StatelessComponent {
  const PersonalSite({required this.resumeClient, super.key});

  final DataServiceClient resumeClient;

  @override
  Component build(BuildContext context) {
    return Document(
      lang: 'ru',
      title: 'Карим Маматказин · Flutter',
      meta: const {
        'description':
            'Резюме Flutter-разработчика Карима Маматказина (nogipx).',
      },
      styles: _styles,
      body: _Page(resumeClient: resumeClient),
    );
  }
}

class _Page extends StatelessComponent {
  const _Page({required this.resumeClient});

  final DataServiceClient resumeClient;

  @override
  Component build(BuildContext context) {
    return Component.element(
      tag: 'main',
      classes: 'page',
      children: [ResumeScreen(resumeClient: resumeClient)],
    );
  }
}

class ResumeScreen extends AsyncStatelessComponent {
  const ResumeScreen({required this.resumeClient, super.key});

  final DataServiceClient resumeClient;

  @override
  Future<Component> build(BuildContext context) async {
    final repo = ResumeRepository(resumeClient);
    final profile = await repo.loadProfile();
    final experiences = await repo.loadExperience();
    final skills = await repo.loadSkills();
    final libraries = await repo.loadLibraries();
    final extras = await repo.loadExtras();

    return Component.fragment([
      _Hero(profile: profile),
      _Contacts(profile: profile),
      _Experience(experiences: experiences),
      _Skills(skills: skills),
      LiveStatsSection(service: StatsService(publisher: profile.publisher)),
      _Libraries(libraries: libraries),
      _Extras(extras: extras),
    ]);
  }
}

class _Hero extends StatelessComponent {
  const _Hero({required this.profile});

  final ResumeProfile profile;

  @override
  Component build(BuildContext context) {
    return section([
      span([Component.text('flat speed // jaspr')], classes: 'eyebrow'),
      h1([Component.text(profile.name)], classes: 'hero-title'),
      div([
        Component.text('фокус: Flutter, CI/CD, нативные интеграции'),
      ], classes: 'typewriter'),
      div([
        span([Component.text(profile.role)], classes: 'accent-text'),
        Component.text(' · ${profile.location}'),
        Component.text(' · ${profile.citizenship}'),
      ], classes: 'meta-line'),
    ], classes: 'hero');
  }
}

class _Contacts extends StatelessComponent {
  const _Contacts({required this.profile});

  final ResumeProfile profile;

  @override
  Component build(BuildContext context) {
    return section([
      div([
        span([Component.text('контакты')], classes: 'eyebrow'),
        div([
          Component.text('без продающих лозунгов — просто факты из резюме'),
        ], classes: 'section-note'),
      ], classes: 'section-head'),
      div([
        span([Component.text(profile.contacts.phone)], classes: 'pill-inline'),
        a([
          Component.text(profile.contacts.email),
        ], href: 'mailto:${profile.contacts.email}'),
        a(
          [Component.text(profile.contacts.telegram)],
          href:
              'https://t.me/${profile.contacts.telegram.replaceFirst('@', '')}',
          target: Target.blank,
          attributes: {'rel': 'noopener'},
        ),
      ], classes: 'contact-row'),
      div([
        Component.text('занятость: ${profile.formats.join(', ')}'),
      ], classes: 'section-note'),
      div([
        Component.text('ожидание: ${profile.salary}'),
      ], classes: 'section-note'),
    ], classes: 'contacts');
  }
}

class _Experience extends StatelessComponent {
  const _Experience({required this.experiences});

  final List<ResumeExperience> experiences;

  @override
  Component build(BuildContext context) {
    return section([
      div([
        span([Component.text('опыт')], classes: 'eyebrow'),
        div([
          Component.text('последние проекты и роли'),
        ], classes: 'section-note'),
      ], classes: 'section-head'),
      ul([
        for (final exp in experiences)
          li([
            div([
              span([Component.text(exp.company)], classes: 'job-title'),
              Component.text(' · ${exp.city}'),
            ], classes: 'job-head'),
            div([
              Component.text('${exp.role} · ${exp.period} · ${exp.duration}'),
            ], classes: 'job-meta'),
            ul([
              for (final point in exp.points) li([Component.text(point)]),
            ], classes: 'points'),
          ]),
      ], classes: 'experience-list'),
    ]);
  }
}

class _Skills extends StatelessComponent {
  const _Skills({required this.skills});

  final ResumeSkills skills;

  @override
  Component build(BuildContext context) {
    return section([
      div([
        span([Component.text('скиллы')], classes: 'eyebrow'),
        div([
          Component.text('моноширинный стек + минимум лишнего оформления'),
        ], classes: 'section-note'),
      ], classes: 'section-head'),
      div([
        span([Component.text('техническое')], classes: 'accent-text'),
        ul([
          for (final s in skills.core) li([Component.text(s)]),
          for (final t in skills.tools) li([Component.text(t)]),
        ], classes: 'inline-list'),
      ]),
      div([
        span([Component.text('форматы')], classes: 'accent-text'),
        ul([
          for (final s in skills.formats) li([Component.text(s)]),
        ], classes: 'inline-list'),
      ]),
      div([
        span([Component.text('специализации')], classes: 'accent-text'),
        ul([
          for (final s in skills.specializations) li([Component.text(s)]),
        ], classes: 'inline-list'),
      ]),
      div([
        span([Component.text('языки')], classes: 'accent-text'),
        ul([
          for (final lang in skills.languages) li([Component.text(lang)]),
        ], classes: 'inline-list'),
      ]),
    ]);
  }
}

class _Libraries extends StatelessComponent {
  const _Libraries({required this.libraries});

  final List<ResumeLibrary> libraries;

  @override
  Component build(BuildContext context) {
    return section([
      div([
        span([Component.text('библиотеки')], classes: 'eyebrow'),
        div([
          Component.text('паблишер: dart.nogipx.dev'),
        ], classes: 'section-note'),
      ], classes: 'section-head'),
      ul([
        for (final lib in libraries)
          li([
            span([Component.text(lib.name)], classes: 'accent-text'),
            Component.text(' — ${lib.description}'),
          ]),
      ], classes: 'library-list'),
    ]);
  }
}

class _Extras extends StatelessComponent {
  const _Extras({required this.extras});

  final ResumeExtras extras;

  @override
  Component build(BuildContext context) {
    return section([
      div([
        span([Component.text('заметки')], classes: 'eyebrow'),
        div([
          Component.text('детали, которые не хочется терять из резюме'),
        ], classes: 'section-note'),
      ], classes: 'section-head'),
      ul([
        for (final note in extras.notes) li([Component.text(note)]),
      ], classes: 'points'),
    ]);
  }
}

final _styles = [
  css.import(
    'https://fonts.googleapis.com/css2?family=JetBrains+Mono:wght@400;500;700&display=swap',
  ),
  css('body').styles(
    margin: Spacing.zero,
    padding: Spacing.zero,
    backgroundColor: const Color('#070809'),
    color: const Color('#f4f6f8'),
    fontFamily: const FontFamily.list([
      FontFamily('JetBrains Mono'),
      FontFamilies.monospace,
    ]),
    lineHeight: 1.6.em,
    raw: {
      'background-image':
          'linear-gradient(135deg, rgba(255,165,0,0.08) 0%, rgba(0,0,0,0) 35%), '
          'radial-gradient(circle at 10% 10%, rgba(255,140,0,0.14), transparent 25%), '
          'radial-gradient(circle at 80% 20%, rgba(255,255,255,0.08), transparent 30%)',
      '-webkit-font-smoothing': 'antialiased',
    },
  ),
  css('.page').styles(
    display: Display.flex,
    flexDirection: FlexDirection.column,
    gap: Gap.all(40.px),
    padding: Padding.symmetric(vertical: 48.px, horizontal: 22.px),
    maxWidth: 1100.px,
    margin: Spacing.symmetric(horizontal: Unit.auto),
  ),
  css('section').styles(
    display: Display.flex,
    flexDirection: FlexDirection.column,
    gap: Gap.all(14.px),
  ),
  css('.eyebrow').styles(
    textTransform: TextTransform.upperCase,
    letterSpacing: 1.5.px,
    fontSize: 12.px,
    color: const Color('#ffb347'),
  ),
  css('.hero-title').styles(
    fontSize: 46.px,
    letterSpacing: 0.6.px,
    fontWeight: FontWeight.w700,
    lineHeight: 1.1.em,
  ),
  css('.typewriter').styles(
    fontSize: 20.px,
    whiteSpace: WhiteSpace.noWrap,
    overflow: Overflow.hidden,
    raw: {
      'display': 'inline-block',
      'border-right': '2px solid #ffb347',
      'animation':
          'type 8s steps(40) infinite alternate, blink 1s step-end infinite',
      'max-width': '100%',
    },
  ),
  css('.meta-line').styles(
    display: Display.flex,
    gap: Gap.all(14.px),
    flexWrap: FlexWrap.wrap,
    color: const Color('#cfd6e4'),
    fontSize: 14.px,
  ),
  css('.contacts').styles(
    display: Display.flex,
    flexDirection: FlexDirection.column,
    gap: Gap.all(8.px),
  ),
  css('.contact-row').styles(
    display: Display.flex,
    flexWrap: FlexWrap.wrap,
    gap: Gap.all(12.px),
    fontSize: 15.px,
  ),
  css('.pill-inline').styles(
    padding: Padding.symmetric(vertical: 6.px, horizontal: 10.px),
    backgroundColor: const Color.rgba(255, 140, 0, 0.12),
    color: const Color('#ffd9a1'),
    radius: BorderRadius.circular(6.px),
  ),
  css('.section-head').styles(
    display: Display.flex,
    flexDirection: FlexDirection.column,
    gap: Gap.all(6.px),
  ),
  css('.section-note').styles(color: const Color('#c3cad6')),
  css('.experience-list').styles(
    listStyle: ListStyle.none,
    padding: Spacing.zero,
    margin: Spacing.zero,
    display: Display.flex,
    flexDirection: FlexDirection.column,
    gap: Gap.all(18.px),
  ),
  css('.job-head').styles(
    display: Display.flex,
    flexWrap: FlexWrap.wrap,
    gap: Gap.all(8.px),
    alignItems: AlignItems.baseline,
  ),
  css('.job-title').styles(fontSize: 18.px, fontWeight: FontWeight.w700),
  css('.job-meta').styles(color: const Color('#cfd6e4')),
  css('.points').styles(
    listStyle: ListStyle.square,
    padding: Spacing.only(left: 20.px),
    margin: Spacing.zero,
    display: Display.flex,
    flexDirection: FlexDirection.column,
    gap: Gap.all(6.px),
    color: const Color('#dfe4ef'),
  ),
  css('.inline-list').styles(
    display: Display.flex,
    flexWrap: FlexWrap.wrap,
    gap: Gap.all(10.px),
    padding: Spacing.zero,
    margin: Spacing.zero,
    listStyle: ListStyle.none,
    color: const Color('#dfe4ef'),
  ),
  css('.accent-text').styles(color: const Color('#ffb347')),
  css('.library-list').styles(
    listStyle: ListStyle.none,
    padding: Spacing.zero,
    margin: Spacing.zero,
    display: Display.flex,
    flexDirection: FlexDirection.column,
    gap: Gap.all(10.px),
  ),
  css('.stats-list').styles(
    listStyle: ListStyle.none,
    padding: Spacing.zero,
    margin: Spacing.zero,
    display: Display.flex,
    flexDirection: FlexDirection.column,
    gap: Gap.all(10.px),
  ),
  css('.stat-row').styles(
    display: Display.flex,
    alignItems: AlignItems.center,
    justifyContent: JustifyContent.spaceBetween,
    gap: Gap.all(10.px),
  ),
  css('.muted').styles(color: const Color('#c3cad6')),
  css.keyframes('type', {
    '0%': const Styles(raw: {'width': '0ch'}),
    '100%': const Styles(raw: {'width': '42ch'}),
  }),
  css.keyframes('blink', {
    '0%': const Styles(raw: {'border-color': '#ffb347'}),
    '50%': const Styles(raw: {'border-color': 'transparent'}),
    '100%': const Styles(raw: {'border-color': '#ffb347'}),
  }),
];
