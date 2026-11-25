import 'package:jaspr/dom.dart';
import 'package:jaspr/server.dart';

import 'profile.dart';

void main() {
  Jaspr.initializeApp();
  runApp(profileDocument);
}

const profileDocument = Document(
  title: 'Karmarov (@nogipx) — приложения и библиотеки',
  lang: 'ru',
  base: null,
  meta: {
    'description': 'Karmarov (@nogipx) — автор Rhyolite Sync, rpc_dart и Parlance. Проекты и контакты.',
    'theme-color': '#f6f7fa',
  },
  head: [
    link(href: 'profile.css', rel: 'stylesheet'),
    link(href: 'enso.png', rel: 'icon', type: 'image/png'),
  ],
  body: Profile(),
);
