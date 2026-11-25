import 'dart:io';

import 'package:jaspr/server.dart';
import 'package:nogipx_portfolio/main.server.dart';

Future<void> main() async {
  Jaspr.initializeApp();
  final page = await renderComponent(profileDocument);
  if (page.statusCode != HttpStatus.ok) {
    throw StateError('Jaspr вернул HTTP ${page.statusCode}');
  }
  final destination = File('web/index.html');
  await destination.writeAsBytes(page.body);
  stdout.writeln('Готово: ${destination.path}');
}
