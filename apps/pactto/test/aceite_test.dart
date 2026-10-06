import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pactto/app.dart';
import 'package:pactto/controllers/proposta_controller.dart';
import 'package:pactto/core/constants/modelos_padrao.dart';
import 'package:pactto/models/modelo_proposta.dart';
import 'package:pactto/models/proposta_pdf.dart';
import 'package:pactto/services/pdf_proposta.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _comAceite = ModeloProposta(
  id: 'a',
  nome: 'Com aceite',
  aceite: true,
  textos: [TextoProposta(titulo: 'Escopo', corpo: '- OS')],
);

const _semAceite = ModeloProposta(
  id: 'b',
  nome: 'Sem aceite',
  textos: [TextoProposta(titulo: 'Escopo', corpo: '- Site')],
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('o modelo padrão traz aceite, inclui/não inclui e prazos', () {
    final modelo = modelosPadrao.first;
    expect(modelo.aceite, isTrue);
    final titulos = modelo.textos.map((t) => t.titulo);
    expect(titulos, contains('O que a mensalidade cobre'));
    expect(titulos, contains('Prazos e condições'));
  });

  test('o aceite vai e volta no JSON do modelo', () {
    expect(ModeloProposta.deJson(_comAceite.paraJson()).aceite, isTrue);
    expect(ModeloProposta.deJson(_semAceite.paraJson()).aceite, isFalse);
    // Modelo gravado antes do aceite existir.
    expect(
      ModeloProposta.deJson({'id': 'x', 'nome': 'Antigo', 'textos': []}).aceite,
      isFalse,
    );
  });

  test('o aceite segue o modelo e pode mudar só na proposta', () {
    final controller = PropostaController(
      modelos: [_comAceite, _semAceite],
      modeloId: 'a',
    );
    addTearDown(controller.dispose);
    expect(controller.incluirAceite, isTrue);

    controller.escolherModelo('b');
    expect(controller.incluirAceite, isFalse);

    controller.alternarAceite(true);
    expect(controller.modelos.last.aceite, isFalse);
    expect(controller.salvarComoModelo('Sem aceite'), isNull);
    expect(controller.modeloAtual!.aceite, isTrue);

    controller.escolherModelo(null);
    expect(controller.incluirAceite, isFalse);
  });

  test('CPF ou CNPJ errado avisa, e Pix com CNPJ vira documento', () {
    final controller = PropostaController();
    addTearDown(controller.dispose);

    expect(controller.erroDocumentoCliente, isNull);
    controller.clienteDocumento.text = '47.407.013/0001-43';
    expect(controller.erroDocumentoCliente, isNull);
    controller.clienteDocumento.text = '123.456.789-00';
    expect(controller.erroDocumentoCliente, 'CPF ou CNPJ inválido.');

    controller.empresaPix.text = 'zamoht.exe@gmail.com';
    expect(controller.documentoEmpresa, isNull);
    controller.empresaPix.text = '69.408.874/0001-89';
    expect(controller.documentoEmpresa, '69.408.874/0001-89');
  });

  test('o rótulo do documento segue o número de dígitos', () {
    expect(rotuloDocumento('529.982.247-25'), 'CPF: 529.982.247-25');
    expect(rotuloDocumento('47.407.013/0001-43'), 'CNPJ: 47.407.013/0001-43');
    expect(rotuloDocumento(null), startsWith('CPF/CNPJ: ___'));
  });

  test('o PDF com aceite é gerado', () async {
    final bytes = await gerarPdfProposta(
      const PropostaPdf(
        numero: 1,
        emitidaEm: '06/10/2026',
        validaAte: '21/10/2026',
        linhas: [LinhaPdf(nome: 'Serviço', detalhe: '', total: '')],
        total: r'R$ 100,00',
        clienteNome: 'DBF Force LTDA',
        clienteDocumento: '47.407.013/0001-43',
        aceite: true,
      ),
    );
    expect(String.fromCharCodes(bytes.take(4)), '%PDF');
  });

  testWidgets('a folha mostra o aceite quando ele está ligado', (tester) async {
    tester.view.physicalSize = const Size(800, 3600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      const PrestadorApp(modelos: [_comAceite], modeloId: 'a'),
    );
    expect(find.byKey(const Key('aceite_folha')), findsOneWidget);

    await tester.tap(find.byKey(const Key('incluir_aceite')));
    await tester.pump();
    expect(find.byKey(const Key('aceite_folha')), findsNothing);
  });
}
