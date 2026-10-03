import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:pactto/controllers/proposta_controller.dart';
import 'package:pactto/services/numeracao_local.dart';
import 'package:pactto/services/pdf_proposta.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _EntregaFixa implements PdfPropostaService {
  _EntregaFixa(this.resposta);

  final EntregaPdf resposta;
  var chamadas = 0;
  String? nome;

  @override
  Future<EntregaPdf> entregar(Uint8List bytes, {required String nome}) async {
    chamadas++;
    this.nome = nome;
    return resposta;
  }
}

PropostaController _comItem(PdfPropostaService pdf, {int numero = 1}) {
  final controller = PropostaController(pdf: pdf, numero: numero);
  controller.clienteNome.text = 'Maria';
  controller.quantidade.text = '2';
  controller.valor.text = '100';
  controller.adicionar();
  return controller;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('cancelar a impressão mantém a proposta preenchida', () async {
    final pdf = _EntregaFixa(EntregaPdf.cancelado);
    final controller = _comItem(pdf);
    addTearDown(controller.dispose);

    expect(await controller.gerarPdf(), ResultadoPdf.cancelado);
    expect(pdf.chamadas, 1);
    expect(controller.linhas, hasLength(1));
    expect(controller.clienteNome.text, 'Maria');
    expect(controller.gerandoPdf, isFalse);
    expect(controller.numero, 1);
  });

  test('PDF entregue limpa a proposta e mantém a empresa', () async {
    final controller = _comItem(_EntregaFixa(EntregaPdf.entregue));
    addTearDown(controller.dispose);
    controller.empresaNome.text = 'Pactto';

    expect(await controller.gerarPdf(), ResultadoPdf.gerado);
    expect(controller.linhas, isEmpty);
    expect(controller.clienteNome.text, isEmpty);
    expect(controller.empresaNome.text, 'Pactto');
  });

  test('o número avança e fica gravado depois da entrega', () async {
    final pdf = _EntregaFixa(EntregaPdf.entregue);
    final controller = _comItem(pdf, numero: 12);
    addTearDown(controller.dispose);

    await controller.gerarPdf();
    expect(pdf.nome, 'proposta-0012-maria.pdf');
    expect(controller.numero, 13);
    expect(controller.numeroFormatado, '0013');
    expect(await const NumeracaoLocal().carregar(), 13);
  });

  test('a proposta mostra emissão e validade pelo dia de São Paulo', () {
    final controller = PropostaController(
      agora: () => DateTime.utc(2026, 10, 3, 2),
    );
    addTearDown(controller.dispose);

    expect(controller.emitidaEm, '02/10/2026');
    expect(controller.validaAte, '09/10/2026');
  });

  test('o logo precisa ser imagem legível de até 1 MB', () {
    final controller = PropostaController();
    addTearDown(controller.dispose);

    expect(
      controller.definirLogo(Uint8List.fromList(utf8.encode('logo'))),
      'Escolha uma imagem PNG ou JPG.',
    );
    expect(
      controller.definirLogo(Uint8List(PropostaController.limiteLogoBytes + 1)),
      'Escolha uma imagem de até 1 MB.',
    );
    expect(controller.logo, isNull);

    final png = base64Decode(
      'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==',
    );
    expect(controller.definirLogo(png), isNull);
    expect(controller.logo, png);

    controller.removerLogo();
    expect(controller.logo, isNull);
  });

  test('item inválido não entra na lista e explica o motivo', () {
    final controller = PropostaController();
    addTearDown(controller.dispose);

    controller.valor.text = 'abc';
    controller.adicionar();
    expect(controller.linhas, isEmpty);
    expect(controller.erroItem, 'Valor inválido. Exemplo: 180,00.');
    expect(controller.valor.text, 'abc');

    controller.aoEditarItem();
    expect(controller.erroItem, isNull);

    controller.quantidade.text = '0';
    controller.valor.text = '10';
    controller.adicionar();
    expect(controller.linhas, isEmpty);
    expect(controller.erroItem, 'Quantidade inválida. Exemplo: 2,5.');

    controller.quantidade.text = '1';
    controller.valor.text = '9' * 30;
    controller.adicionar();
    expect(controller.linhas, isEmpty);
    expect(controller.erroItem, 'Valor alto demais.');

    controller.valor.text = '-5';
    controller.adicionar();
    expect(controller.linhas, isEmpty);
    expect(controller.erroItem, 'O valor não pode ser negativo.');

    controller.valor.text = '10';
    controller.adicionar();
    expect(controller.linhas, hasLength(1));
    expect(controller.erroItem, isNull);
  });

  test('ponto do teclado numérico vale como vírgula', () {
    final controller = PropostaController();
    addTearDown(controller.dispose);

    controller.quantidade.text = '2.5';
    controller.valor.text = '33.33';
    controller.adicionar();
    controller.desconto.text = '10.5';

    expect(controller.linhas.single.texto, startsWith('Serviço — 2,5 h'));
    final totais = controller.resumo.totais!;
    expect(totais.baseCentavos, 8333);
    expect(totais.descontoCentavos, 875);
  });
}
