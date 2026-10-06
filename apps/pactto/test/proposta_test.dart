import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pactto/app.dart';

void main() {
  testWidgets('2,5 vezes 33,33 fecha em 83,33', (tester) async {
    tester.view.physicalSize = const Size(800, 3200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const PrestadorApp(numero: 42));

    expect(find.text('PROPOSTA Nº 0042'), findsOneWidget);
    expect(
      tester.widget<Text>(find.byKey(const Key('datas'))).data,
      matches(
        RegExp(r'^Emitida em \d\d/\d\d/\d{4}\. Válida até \d\d/\d\d/\d{4}\.$'),
      ),
    );

    await tester.enterText(find.byKey(const Key('quantidade')), '2,5');
    await tester.enterText(find.byKey(const Key('valor')), '33,33');
    await tester.tap(find.byKey(const Key('adicionar')));
    await tester.pump();

    expect(
      tester.widget<Text>(find.byKey(const Key('total'))).data,
      r'R$ 83,33',
    );
  });

  testWidgets('hora de 50 por 60 fecha em 3.000 e mensalidade fica de fora', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 3600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const PrestadorApp());

    expect(find.text('Horas'), findsOneWidget);
    expect(find.text('Valor da hora'), findsOneWidget);
    expect(
      find.widgetWithText(ActionChip, 'Hora de desenvolvimento'),
      findsNothing,
    );

    await tester.enterText(
      find.byKey(const Key('descricao')),
      'Desenvolvimento',
    );
    await tester.enterText(find.byKey(const Key('quantidade')), '50');
    await tester.enterText(find.byKey(const Key('valor')), '60');
    await tester.tap(find.byKey(const Key('adicionar')));
    await tester.pump();

    expect(
      find.text('Desenvolvimento — 50 h × R\$ 60,00 = R\$ 3.000,00'),
      findsWidgets,
    );
    expect(
      tester.widget<Text>(find.byKey(const Key('total'))).data,
      r'R$ 3.000,00',
    );

    await tester.tap(find.widgetWithText(ChoiceChip, 'Mensalidade'));
    await tester.pump();

    expect(find.byKey(const Key('quantidade')), findsNothing);
    expect(find.text('Horas'), findsNothing);
    expect(find.text('Valor por mês'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('valor')), '350');
    await tester.tap(find.byKey(const Key('adicionar')));
    await tester.pump();

    expect(
      find.text('Mensalidade — R\$ 350,00 por mês, a partir do uso'),
      findsWidgets,
    );
    expect(
      tester.widget<Text>(find.byKey(const Key('total'))).data,
      r'R$ 3.000,00',
    );
  });

  testWidgets('valor inválido mostra o motivo e não vira item', (tester) async {
    tester.view.physicalSize = const Size(800, 3200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const PrestadorApp());

    await tester.enterText(find.byKey(const Key('valor')), '12,345');
    await tester.tap(find.byKey(const Key('adicionar')));
    await tester.pump();

    expect(
      tester.widget<Text>(find.byKey(const Key('erro_item'))).data,
      'Valor inválido. Exemplo: 180,00.',
    );
    expect(find.byKey(const Key('total')), findsNothing);

    await tester.enterText(find.byKey(const Key('valor')), '12,34');
    await tester.pump();
    expect(find.byKey(const Key('erro_item')), findsNothing);
  });

  testWidgets('telefone e WhatsApp ganham a máscara ao digitar', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 3200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const PrestadorApp());

    await tester.enterText(
      find.byKey(const Key('empresa_telefone')),
      '62984835669',
    );
    await tester.enterText(
      find.byKey(const Key('cliente_whatsapp')),
      '6234835669',
    );
    await tester.pump();

    expect(
      tester
          .widget<TextField>(find.byKey(const Key('empresa_telefone')))
          .controller
          ?.text,
      '(62) 98483-5669',
    );
    expect(
      tester
          .widget<TextField>(find.byKey(const Key('cliente_whatsapp')))
          .controller
          ?.text,
      '(62) 3483-5669',
    );
  });
}
