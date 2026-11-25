import 'package:jaspr/dom.dart';
import 'package:jaspr/server.dart';

import 'portfolio.dart';

void main() {
  Jaspr.initializeApp();
  runApp(portfolioDocument);
}

const portfolioDocument = Document(
  title: 'Карим Маматказин — nogipx',
  lang: 'ru',
  base: null,
  meta: {
    'description': 'Архитектор ПО Карим Маматказин. Проекты на Dart: rpc_dart, Parlance и Rhyolite Sync.',
    'theme-color': '#08080c',
  },
  head: [
    link(href: 'style.css', rel: 'stylesheet'),
    link(href: 'mark.svg', rel: 'icon', type: 'image/svg+xml'),
  ],
  body: Portfolio(),
);
