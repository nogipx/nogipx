import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

enum CallMode {
  unary('Unary', 'Один запрос и один ответ.', requests: 1, responses: 1),
  server(
    'Server stream',
    'На один запрос сервер отправляет поток ответов.',
    requests: 1,
    responses: 3,
  ),
  client(
    'Client stream',
    'Клиент отправляет поток сообщений и получает один ответ.',
    requests: 3,
    responses: 1,
  ),
  duplex(
    'Duplex',
    'Обе стороны могут отправлять сообщения независимо.',
    requests: 3,
    responses: 3,
  );

  const CallMode(
    this.label,
    this.caption, {
    required this.requests,
    required this.responses,
  });
  final String label, caption;
  final int requests, responses;
}

class RpcDemo extends StatelessComponent {
  const RpcDemo({super.key});

  @override
  Component build(BuildContext context) => fieldset(classes: 'demo', [
    legend(classes: 'sr-only', [Component.text('Выберите вид RPC-вызова')]),
    div(classes: 'demo-title', [Component.text('Схема вызова')]),
    div(classes: 'switch', [
      for (final mode in CallMode.values)
        label([
          input<bool>(
            type: InputType.radio,
            name: 'call-mode',
            value: mode.name,
            checked: mode == CallMode.unary,
            attributes: {'aria-controls': 'diagram-${mode.name}'},
          ),
          span([Component.text(mode.label)]),
        ]),
    ]),
    for (final mode in CallMode.values)
      div(id: 'diagram-${mode.name}', classes: 'diagram ${mode.name}', [
        div(classes: 'endpoints', [
          span([Component.text('Клиент')]),
          span([Component.text('Сервер')]),
        ]),
        div(
          classes: 'lanes',
          attributes: {'aria-hidden': 'true'},
          [
            div(classes: 'lane outgoing', [
              for (var i = 0; i < mode.requests; i++)
                span(classes: 'packet', []),
            ]),
            div(classes: 'lane incoming', [
              for (var i = 0; i < mode.responses; i++)
                span(classes: 'packet', []),
            ]),
          ],
        ),
        p([Component.text(mode.caption)]),
      ]),
  ]);
}
