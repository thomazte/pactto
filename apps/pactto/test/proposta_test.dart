import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pactto/app.dart';

void main() {
  testWidgets('2,5 vezes 33,33 fecha em 83,33', (tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const PrestadorApp());

    await tester.enterText(find.byKey(const Key('quantidade')), '2,5');
    await tester.enterText(find.byKey(const Key('valor')), '33,33');
    await tester.tap(find.byKey(const Key('adicionar')));
    await tester.pump();

    expect(
      tester.widget<Text>(find.byKey(const Key('total'))).data,
      r'R$ 83,33',
    );
  });

  testWidgets('atalho de tecnologia preenche a descrição como serviço', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const PrestadorApp());

    await tester.tap(
      find.widgetWithText(ActionChip, 'Hora de desenvolvimento'),
    );
    await tester.pump();

    expect(
      tester
          .widget<TextField>(find.byKey(const Key('descricao')))
          .controller
          ?.text,
      'Hora de desenvolvimento',
    );
  });

  testWidgets('telefone e WhatsApp ganham a máscara ao digitar', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1600);
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
