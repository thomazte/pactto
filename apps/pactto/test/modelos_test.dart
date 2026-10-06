import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pactto/app.dart';
import 'package:pactto/controllers/proposta_controller.dart';
import 'package:pactto/core/constants/modelos_padrao.dart';
import 'package:pactto/models/modelo_proposta.dart';
import 'package:pactto/models/proposta_pdf.dart';
import 'package:pactto/services/modelos_local.dart';
import 'package:pactto/services/pdf_proposta.dart';
import 'package:pactto/views/proposta/folha_proposta.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _EntregaFixa implements PdfPropostaService {
  Uint8List? bytes;

  @override
  Future<EntregaPdf> entregar(Uint8List bytes, {required String nome}) async {
    this.bytes = bytes;
    return EntregaPdf.entregue;
  }
}

const _modelo = ModeloProposta(
  id: 'm1',
  nome: 'Manutenção',
  textos: [
    TextoProposta(titulo: 'Escopo', corpo: '- Limpeza\n- Revisão'),
    TextoProposta(
      titulo: 'Garantia',
      corpo: '90 dias.',
      posicao: PosicaoTexto.depois,
    ),
  ],
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('sem nada gravado, vale o modelo padrão já escolhido', () async {
    final carregado = await const ModelosLocal().carregar();
    expect(carregado.modelos.map((m) => m.nome), ['Sistema sob medida']);
    expect(carregado.escolhido, modelosPadrao.first.id);
  });

  test(
    'modelos gravados voltam iguais, e lista vazia continua vazia',
    () async {
      await const ModelosLocal().salvar([_modelo]);
      await const ModelosLocal().salvarEscolhido('m1');
      var carregado = await const ModelosLocal().carregar();
      expect(carregado.escolhido, 'm1');
      final textos = carregado.modelos.single.textos;
      expect(textos.map((t) => t.titulo), ['Escopo', 'Garantia']);
      expect(textos.last.posicao, PosicaoTexto.depois);

      await const ModelosLocal().salvar([]);
      await const ModelosLocal().salvarEscolhido(null);
      carregado = await const ModelosLocal().carregar();
      expect(carregado.modelos, isEmpty);
    },
  );

  test('escolher o modelo preenche os textos sem alterar o modelo', () {
    final controller = PropostaController(modelos: [_modelo]);
    addTearDown(controller.dispose);
    expect(controller.textos, isEmpty);

    controller.escolherModelo('m1');
    expect(controller.textos.map((t) => t.titulo.text), ['Escopo', 'Garantia']);

    controller.textos.first.corpo.text = '- Só limpeza';
    expect(
      controller.modelos.single.textos.first.corpo,
      '- Limpeza\n- Revisão',
    );

    controller.escolherModelo(null);
    expect(controller.modeloId, isNull);
    expect(controller.textos, isEmpty);
  });

  test('id gravado que não existe mais vira "sem modelo"', () {
    final controller = PropostaController(modelos: [_modelo], modeloId: '');
    addTearDown(controller.dispose);
    expect(controller.modeloAtual, isNull);
  });

  test('salvar como modelo cria, substitui pelo nome e grava', () async {
    final controller = PropostaController(
      modelos: [_modelo],
      modeloId: 'm1',
      agora: () => DateTime.utc(2026, 10, 6),
    );
    addTearDown(controller.dispose);

    expect(controller.salvarComoModelo('  '), 'Dê um nome ao modelo.');

    controller.adicionarTexto();
    controller.textos.last.titulo.text = 'Prazo';
    controller.textos.last.corpo.text = '5 dias úteis.';
    expect(controller.salvarComoModelo('Manutenção completa'), isNull);
    expect(controller.modelos, hasLength(2));
    expect(controller.modeloAtual!.textos, hasLength(3));

    controller.removerTexto(2);
    expect(controller.salvarComoModelo('manutenção COMPLETA'), isNull);
    expect(controller.modelos, hasLength(2));
    expect(controller.modeloAtual!.nome, 'manutenção COMPLETA');
    expect(controller.modeloAtual!.textos, hasLength(2));

    final gravado = await const ModelosLocal().carregar();
    expect(gravado.modelos, hasLength(2));
    expect(gravado.escolhido, controller.modeloId);
  });

  test('textos em branco não viram modelo', () {
    final controller = PropostaController();
    addTearDown(controller.dispose);
    controller.adicionarTexto();
    expect(controller.salvarComoModelo('Vazio'), 'Escreva ao menos um texto.');
    expect(controller.modelos, isEmpty);
  });

  test('excluir o modelo mantém os textos da proposta', () {
    final controller = PropostaController(modelos: [_modelo], modeloId: 'm1');
    addTearDown(controller.dispose);

    controller.excluirModelo('m1');
    expect(controller.modelos, isEmpty);
    expect(controller.modeloId, isNull);
    expect(controller.textos, hasLength(2));
  });

  test('o PDF leva os textos e a proposta seguinte volta ao modelo', () async {
    final pdf = _EntregaFixa();
    final controller = PropostaController(
      pdf: pdf,
      modelos: [_modelo],
      modeloId: 'm1',
    );
    addTearDown(controller.dispose);
    controller.textos.first.titulo.text = 'Escopo ajustado';
    controller.valor.text = '100';
    controller.adicionar();

    expect(await controller.gerarPdf(), ResultadoPdf.gerado);
    // As palavras-chave saem em UTF-16 quando têm caractere fora do
    // Latin-1; sem os zeros, a busca vale para os dois jeitos.
    final texto = latin1
        .decode(pdf.bytes!, allowInvalid: true)
        .replaceAll('\x00', '');
    expect(texto, contains('Escopo ajustado'));
    expect(texto, contains('Garantia'));
    expect(controller.textos.first.titulo.text, 'Escopo');
  });

  test('texto longo passa de página sem quebrar o PDF', () async {
    final corpo = List.generate(120, (i) => '- Tópico $i').join('\n');
    final doc = await montarPdfProposta(
      PropostaPdf(
        numero: 1,
        emitidaEm: '06/10/2026',
        validaAte: '13/10/2026',
        linhas: const [LinhaPdf(nome: 'Serviço', detalhe: '', total: '')],
        total: r'R$ 100,00',
        textosAntes: [TextoPdf(titulo: 'Escopo', corpo: corpo)],
      ),
    );
    final bytes = await doc.save();
    final texto = latin1.decode(bytes, allowInvalid: true);
    expect(RegExp(r'/Type\s*/Page\b').allMatches(texto).length, greaterThan(1));
  });

  testWidgets('trocar o modelo mostra os textos na folha', (tester) async {
    tester.view.physicalSize = const Size(800, 3200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const PrestadorApp(modelos: [_modelo]));

    expect(find.text('Investimento'), findsNothing);

    await tester.tap(find.byKey(const Key('modelo')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Manutenção').last);
    await tester.pumpAndSettle();

    expect(find.text('Investimento'), findsOneWidget);
    expect(find.text('Limpeza'), findsOneWidget);
    final folha = find.byType(FolhaProposta);
    expect(
      find.descendant(of: folha, matching: find.text('90 dias.')),
      findsOneWidget,
    );
  });
}
