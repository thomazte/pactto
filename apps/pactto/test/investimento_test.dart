import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pactto/app.dart';
import 'package:pactto/controllers/proposta_controller.dart';
import 'package:pactto/core/constants/modelos_padrao.dart';
import 'package:pactto/models/atalho_item.dart';
import 'package:pactto/models/linha_digitada.dart';
import 'package:pactto/models/linha_texto.dart';
import 'package:pactto/models/modelo_proposta.dart';
import 'package:shared_preferences/shared_preferences.dart';

void _item(
  PropostaController controller,
  ModalidadeItem modalidade,
  String descricao,
  String valor,
) {
  controller.definirModalidade(modalidade);
  controller.descricao.text = descricao;
  controller.valor.text = valor;
  controller.adicionar();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('cada item diz o que é, como é cobrado e quanto vale', () {
    final hora = LinhaDigitada.ler(
      modalidade: ModalidadeItem.hora,
      descricao: 'Desenvolvimento',
      quantidade: '50',
      valor: '60',
    );
    expect(hora.item, r'Desenvolvimento (50 h × R$ 60,00)');
    expect(hora.cobranca, 'única');

    final licenca = LinhaDigitada.ler(
      modalidade: ModalidadeItem.licenca,
      descricao: '',
      quantidade: '3',
      valor: '40',
    );
    expect(licenca.item, r'Licença (3 licenças × R$ 40,00)');

    final mensal = LinhaDigitada.ler(
      modalidade: ModalidadeItem.mensalidade,
      descricao: 'Mensalidade (servidor e suporte)',
      quantidade: '1',
      valor: '350',
    );
    expect(mensal.item, 'Mensalidade (servidor e suporte)');
    expect(mensal.cobranca, 'mensal');
  });

  test('com mensalidade, o total diz que soma só os valores únicos', () {
    final controller = PropostaController();
    addTearDown(controller.dispose);

    _item(controller, ModalidadeItem.valorFechado, 'Desenvolvimento', '2200');
    _item(controller, ModalidadeItem.valorFechado, 'Implantação', '800');
    expect(controller.rotuloTotal, 'Total');
    expect(controller.mostraTotal, isTrue);

    _item(controller, ModalidadeItem.mensalidade, 'Mensalidade', '350');
    expect(controller.rotuloTotal, 'Total dos valores únicos');
    expect(controller.resumo.totais!.totalCentavos, 300000);
  });

  test('só mensalidade fica sem total, a não ser com visita', () {
    final controller = PropostaController();
    addTearDown(controller.dispose);
    _item(controller, ModalidadeItem.mensalidade, 'Mensalidade', '100');
    expect(controller.mostraTotal, isFalse);

    controller.visita.text = '50';
    expect(controller.mostraTotal, isTrue);
  });

  test('a validade vem do modelo e campo inválido segura o PDF', () async {
    final controller = PropostaController(
      modelos: modelosPadrao,
      modeloId: modelosPadrao.first.id,
      agora: () => DateTime.utc(2026, 10, 6, 15),
    );
    addTearDown(controller.dispose);
    expect(controller.validade.text, '15');
    expect(controller.validaAte, '21/10/2026');

    controller.validade.text = '0';
    expect(controller.erroValidade, 'De 1 a 365 dias.');
    _item(controller, ModalidadeItem.valorFechado, 'Projeto', '1000');
    expect(await controller.gerarPdf(), ResultadoPdf.ignorado);

    controller.validade.text = '30';
    expect(controller.salvarComoModelo('Trinta dias'), isNull);
    expect(controller.modeloAtual!.validadeDias, 30);

    controller.escolherModelo(null);
    expect(controller.validade.text, '${ModeloProposta.validadePadrao}');
  });

  test('a validade vai e volta no JSON, e modelo antigo vale 7 dias', () {
    const modelo = ModeloProposta(id: 'v', nome: 'V', validadeDias: 15);
    expect(ModeloProposta.deJson(modelo.paraJson()).validadeDias, 15);
    expect(
      ModeloProposta.deJson({'id': 'x', 'nome': 'Antigo'}).validadeDias,
      ModeloProposta.validadePadrao,
    );
  });

  test('rótulo de tópico e linha curta com dois-pontos viram negrito', () {
    final linhas = lerCorpo(
      'O sistema entregue inclui:\n'
      'Inclui:\n'
      '- Prazo de entrega: 30 dias\n'
      '- Pagamento do desenvolvimento e implantação: 2 parcelas\n'
      '- Reajuste anual pelo IPCA\n'
      '- Ver o item 2.1: depois\n'
      'Texto comum.',
    );
    expect(linhas[0].rotulo, isNull);
    expect(linhas[1].rotulo, 'Inclui:');
    expect(linhas[2].topico, isTrue);
    expect(linhas[2].rotulo, 'Prazo de entrega:');
    expect(linhas[2].resto, ' 30 dias');
    expect(linhas[3].rotulo, 'Pagamento do desenvolvimento e implantação:');
    expect(linhas[4].rotulo, isNull);
    expect(linhas[5].rotulo, isNull);
    expect(linhas[6].topico, isFalse);
    expect(linhas[6].resto, 'Texto comum.');
  });

  testWidgets('a folha mostra a tabela de itens e o total sem anos', (
    tester,
  ) async {
    // Largura de celular: a tabela e o total precisam caber sem estourar.
    tester.view.physicalSize = const Size(390, 5200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const PrestadorApp());

    await tester.tap(find.widgetWithText(ChoiceChip, 'Valor fechado'));
    await tester.pump();
    await tester.enterText(find.byKey(const Key('valor')), '3000');
    await tester.tap(find.byKey(const Key('adicionar')));
    await tester.pump();
    expect(find.text('Total'), findsOneWidget);

    await tester.tap(find.widgetWithText(ChoiceChip, 'Mensalidade'));
    await tester.pump();
    await tester.enterText(find.byKey(const Key('valor')), '350');
    await tester.tap(find.byKey(const Key('adicionar')));
    await tester.pump();

    expect(find.text('Valores por ano'), findsNothing);
    expect(find.text('mensal'), findsOneWidget);
    expect(find.text(r'R$ 350,00'), findsOneWidget);
    expect(find.text('Total dos valores únicos'), findsOneWidget);
  });
}
