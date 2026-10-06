import 'dart:typed_data';

import 'package:dominio/dominio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pactto/app.dart';
import 'package:pactto/controllers/proposta_controller.dart';
import 'package:pactto/core/constants/modelos_padrao.dart';
import 'package:pactto/models/atalho_item.dart';
import 'package:pactto/models/modelo_proposta.dart';
import 'package:pactto/models/proposta_salva.dart';
import 'package:pactto/services/numeracao_local.dart';
import 'package:pactto/services/pdf_proposta.dart';
import 'package:pactto/services/propostas_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Entrega implements PdfPropostaService {
  var nome = '';

  @override
  Future<EntregaPdf> entregar(Uint8List bytes, {required String nome}) async {
    this.nome = nome;
    return EntregaPdf.entregue;
  }
}

var _relogio = 0;
DateTime _agora() =>
    DateTime.utc(2026, 10, 6, 15).add(Duration(seconds: _relogio++));

PropostaController _controller({int numero = 1, _Entrega? pdf}) {
  return PropostaController(
    numero: numero,
    modelos: modelosPadrao,
    modeloId: modelosPadrao.first.id,
    pdf: pdf,
    agora: _agora,
  );
}

void _preencher(PropostaController controller) {
  controller.clienteNome.text = 'DBF Force LTDA';
  controller.clienteDocumento.text = '47.407.013/0001-43';
  controller.textos.first.corpo.text = 'Texto da DBF.';
  controller.validade.text = '20';
  controller.alternarAceite(false);
  controller.definirModalidade(ModalidadeItem.valorFechado);
  controller.descricao.text = 'Desenvolvimento';
  controller.valor.text = '2.200,00';
  controller.adicionar();
  controller.definirTipoDesconto(TipoDesconto.fixo);
  controller.desconto.text = '100';
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('a proposta salva vai e volta no JSON', () {
    final controller = _controller();
    addTearDown(controller.dispose);
    _preencher(controller);
    expect(controller.salvarProposta(), isNull);

    final volta = PropostaSalva.deJson(controller.propostas.single.paraJson());
    expect(volta.clienteNome, 'DBF Force LTDA');
    expect(volta.textos.first.corpo, 'Texto da DBF.');
    expect(volta.textos.last.posicao, PosicaoTexto.depois);
    expect(volta.linhas.single.valorCentavos, 220000);
    expect(volta.linhas.single.modalidade, ModalidadeItem.valorFechado);
    expect(volta.validadeDias, 20);
    expect(volta.aceite, isFalse);
    expect(volta.descontoTipo, TipoDesconto.fixo);
    expect(volta.desconto, '100');
    expect(volta.numero, isNull);
  });

  test(
    'salvar pede cliente ou item, e salvar de novo atualiza a mesma',
    () async {
      final controller = _controller();
      addTearDown(controller.dispose);
      expect(
        controller.salvarProposta(),
        'Preencha o cliente ou um item antes de salvar.',
      );

      _preencher(controller);
      controller.salvarProposta();
      final id = controller.propostaId;
      controller.clienteNome.text = 'DBF Force';
      controller.salvarProposta();
      expect(controller.propostas, hasLength(1));
      expect(controller.propostaId, id);
      expect(controller.propostas.single.clienteNome, 'DBF Force');

      final gravadas = await const PropostasLocal().carregar();
      expect(gravadas.single.clienteNome, 'DBF Force');
    },
  );

  test('abrir traz tudo de volta, com os textos da proposta', () {
    final controller = _controller();
    addTearDown(controller.dispose);
    _preencher(controller);
    controller.salvarProposta();
    final id = controller.propostaId!;

    controller.novaProposta();
    expect(controller.clienteNome.text, isEmpty);
    expect(controller.linhas, isEmpty);
    expect(controller.textos.first.corpo.text, isNot('Texto da DBF.'));
    expect(controller.propostaId, isNull);

    controller.abrirProposta(id);
    expect(controller.clienteNome.text, 'DBF Force LTDA');
    expect(controller.clienteDocumento.text, '47.407.013/0001-43');
    expect(controller.textos.first.corpo.text, 'Texto da DBF.');
    expect(controller.validade.text, '20');
    expect(controller.incluirAceite, isFalse);
    expect(controller.linhas.single.descricao, 'Desenvolvimento');
    expect(controller.descontoTipo, TipoDesconto.fixo);
    expect(controller.desconto.text, '100');
    expect(controller.mostrarAjustes, isTrue);
    expect(controller.resumo.totais!.totalCentavos, 210000);
  });

  test(
    'PDF de proposta nova salva com o número e avança a numeração',
    () async {
      final pdf = _Entrega();
      final controller = _controller(numero: 7, pdf: pdf);
      addTearDown(controller.dispose);
      _preencher(controller);

      expect(await controller.gerarPdf(), ResultadoPdf.gerado);
      expect(pdf.nome, 'proposta-0007-dbf-force-ltda.pdf');
      expect(controller.numero, 8);
      expect(controller.propostas.single.numero, 7);
      expect(await const NumeracaoLocal().carregar(), 8);
    },
  );

  test('proposta reaberta mantém o número e não gasta outro', () async {
    final pdf = _Entrega();
    final controller = _controller(numero: 7, pdf: pdf);
    addTearDown(controller.dispose);
    _preencher(controller);
    await controller.gerarPdf();

    controller.abrirProposta(controller.propostas.single.id);
    expect(controller.numeroFormatado, '0007');
    controller.valor.text = '500';
    controller.adicionar();
    expect(await controller.gerarPdf(), ResultadoPdf.gerado);

    expect(pdf.nome, 'proposta-0007-dbf-force-ltda.pdf');
    expect(controller.numero, 8);
    expect(controller.propostas, hasLength(1));
    expect(controller.propostas.single.linhas, hasLength(2));
  });

  test('rascunho reaberto recebe o próximo número no primeiro PDF', () async {
    final pdf = _Entrega();
    final controller = _controller(numero: 3, pdf: pdf);
    addTearDown(controller.dispose);
    _preencher(controller);
    controller.salvarProposta();
    final id = controller.propostaId!;
    controller.novaProposta();

    controller.abrirProposta(id);
    expect(controller.numeroFormatado, '0003');
    await controller.gerarPdf();
    expect(controller.propostas.single.numero, 3);
    expect(controller.numero, 4);
  });

  test('excluir a proposta aberta deixa a tela como proposta nova', () {
    final controller = _controller();
    addTearDown(controller.dispose);
    _preencher(controller);
    controller.salvarProposta();

    controller.excluirProposta(controller.propostaId!);
    expect(controller.propostas, isEmpty);
    expect(controller.propostaId, isNull);
    expect(controller.clienteNome.text, 'DBF Force LTDA');
  });

  testWidgets('salvar, limpar e reabrir pela lista', (tester) async {
    tester.view.physicalSize = const Size(390, 5200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      PrestadorApp(modelos: modelosPadrao, modeloId: modelosPadrao.first.id),
    );

    String? titulo() =>
        tester.widget<Text>(find.byKey(const Key('titulo_proposta'))).data;

    await tester.enterText(find.byKey(const Key('cliente_nome')), 'DBF');
    // O botão de baixo, ao lado do PDF, salva do mesmo jeito.
    await tester.scrollUntilVisible(
      find.byKey(const Key('salvar_proposta_folha')),
      400,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(find.byKey(const Key('salvar_proposta_folha')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('salvar_proposta_folha')));
    await tester.pump();
    expect(find.text('Proposta salva.'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.byKey(const Key('titulo_proposta')),
      -400,
      scrollable: find.byType(Scrollable).first,
    );
    expect(titulo(), 'Rascunho salvo');
    expect(find.text('Propostas salvas (1)'), findsOneWidget);

    await tester.ensureVisible(find.byKey(const Key('nova_proposta')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('nova_proposta')));
    await tester.pump();
    expect(titulo(), 'Nova proposta');

    await tester.ensureVisible(find.byKey(const Key('propostas_salvas')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('propostas_salvas')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('DBF'));
    await tester.pumpAndSettle();

    expect(titulo(), 'Rascunho salvo');
    expect(
      tester
          .widget<TextField>(find.byKey(const Key('cliente_nome')))
          .controller
          ?.text,
      'DBF',
    );
  });
}
