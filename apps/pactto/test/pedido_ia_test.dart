import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pactto/app.dart';
import 'package:pactto/controllers/proposta_controller.dart';
import 'package:pactto/models/modelo_proposta.dart';
import 'package:pactto/services/pedido_ia.dart';

const _modelo = ModeloProposta(
  id: 'm1',
  nome: 'Sistema',
  textos: [
    TextoProposta(titulo: 'Apresentação', corpo: 'Texto genérico.'),
    TextoProposta(titulo: 'Escopo', corpo: '- Cadastros'),
    TextoProposta(
      titulo: 'Condições',
      corpo: '- 12 meses',
      posicao: PosicaoTexto.depois,
    ),
  ],
);

void main() {
  test('o pedido leva cliente, tópicos, regras e os textos atuais', () {
    final pedido = montarPedidoIa(
      topicos: ' sistema de OS, garantia ',
      cliente: 'DBF Force',
      textos: _modelo.textos.take(2).toList(),
    );
    expect(pedido, contains('Cliente: DBF Force'));
    expect(pedido, contains('sistema de OS, garantia'));
    expect(pedido, contains('"## Título"'));
    expect(pedido, contains('## Escopo\n- Cadastros'));
    expect(pedido, isNot(contains('Condições')));
  });

  test('sem textos, o pedido pede apresentação e escopo', () {
    final pedido = montarPedidoIa(topicos: 'site');
    expect(pedido, contains('"Apresentação" e "Escopo"'));
    expect(pedido, isNot(contains('Cliente:')));
  });

  test('a resposta vira textos, sem negrito, cerca nem marcador estranho', () {
    final textos = lerRespostaIa('''
Claro! Segue a proposta:

```
## **Apresentação**
Sistema de OS para a **DBF Force**.

### Escopo:
* Abertura de OS
• Controle de garantia
- PDF da OS
```
''');
    expect(textos.map((t) => t.titulo), ['Apresentação', 'Escopo']);
    expect(textos.first.corpo, 'Sistema de OS para a DBF Force.');
    expect(
      textos.last.corpo,
      '- Abertura de OS\n- Controle de garantia\n- PDF da OS',
    );
  });

  test('resposta sem títulos não vira texto', () {
    expect(lerRespostaIa('Um parágrafo qualquer.'), isEmpty);
  });

  test('a resposta troca o texto de mesmo título e cria os novos', () {
    final controller = PropostaController(modelos: [_modelo], modeloId: 'm1');
    addTearDown(controller.dispose);

    expect(controller.pedidoIa(), isNull);
    controller.topicosIa.text = 'OS e garantia';
    expect(controller.pedidoIa(), contains('## Apresentação'));
    expect(controller.pedidoIa(), isNot(contains('## Condições')));

    expect(
      controller.aplicarRespostaIa('sem formato'),
      startsWith('Não encontrei os textos'),
    );
    expect(
      controller.aplicarRespostaIa(
        '## escopo\n- OS\n- Garantia\n## Plataformas\nNavegador.',
      ),
      isNull,
    );
    expect(controller.textos.map((t) => t.titulo.text), [
      'Apresentação',
      'Escopo',
      'Plataformas',
      'Condições',
    ]);
    expect(controller.textos[1].corpo.text, '- OS\n- Garantia');
    expect(controller.textos[2].posicao, PosicaoTexto.antes);
    expect(controller.modelos.single.textos[1].corpo, '- Cadastros');
  });

  testWidgets('copiar e colar pela área de transferência', (tester) async {
    String? copiado;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (chamada) async {
        if (chamada.method == 'Clipboard.setData') {
          copiado = (chamada.arguments as Map)['text'] as String;
        }
        if (chamada.method == 'Clipboard.getData') {
          return {'text': '## Escopo\n- Ordem de serviço'};
        }
        return null;
      },
    );
    tester.view.physicalSize = const Size(800, 3200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      const PrestadorApp(modelos: [_modelo], modeloId: 'm1'),
    );

    await tester.tap(find.byKey(const Key('copiar_pedido_ia')));
    await tester.pump();
    expect(copiado, isNull);
    expect(find.text('Escreva primeiro o que o cliente precisa.'), findsOne);

    await tester.enterText(find.byKey(const Key('topicos_ia')), 'OS');
    await tester.tap(find.byKey(const Key('copiar_pedido_ia')));
    await tester.pump();
    expect(copiado, contains('O que o cliente precisa:\nOS'));

    await tester.tap(find.byKey(const Key('colar_resposta_ia')));
    await tester.pump();
    expect(find.text('Ordem de serviço'), findsOneWidget);
  });
}
