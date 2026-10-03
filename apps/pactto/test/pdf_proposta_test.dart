import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pactto/models/atalho_item.dart';
import 'package:pactto/models/linha_digitada.dart';
import 'package:pactto/models/proposta_pdf.dart';
import 'package:pactto/services/pdf_proposta.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('o PDF fala a mesma língua da folha do cliente', () async {
    final bytes = await gerarPdfProposta(
      const PropostaPdf(
        numero: 12,
        emitidaEm: '03/10/2026',
        validaAte: '10/10/2026',
        linhas: [
          LinhaPdf(
            nome: 'Hora de desenvolvimento',
            detalhe: '8 serviço × R\$ 180,00',
            total: 'R\$ 1.440,00',
          ),
        ],
        total: 'R\$ 1.440,00',
        empresaPix: 'zamoht.exe@gmail.com',
      ),
    );

    final texto = latin1.decode(bytes, allowInvalid: true);
    expect(texto.startsWith('%PDF'), isTrue);
    expect(texto, contains('DejaVuSans'));
    expect(texto, contains('Proposta 0012'));
    expect(texto, contains('Hora de desenvolvimento'));
    expect(texto, contains('1.440,00'));
  });

  test(
    'o PDF separa a mensalidade da conta de hora, fechado e licença',
    () async {
      final hora = LinhaDigitada.ler(
        modalidade: ModalidadeItem.hora,
        descricao: 'Desenvolvimento',
        quantidade: '50',
        valor: '60',
      );
      final fechado = LinhaDigitada.ler(
        modalidade: ModalidadeItem.valorFechado,
        descricao: 'Implantação',
        quantidade: '1',
        valor: '1200',
      );
      final licenca = LinhaDigitada.ler(
        modalidade: ModalidadeItem.licenca,
        descricao: '',
        quantidade: '3',
        valor: '40',
      );
      final mensal = LinhaDigitada.ler(
        modalidade: ModalidadeItem.mensalidade,
        descricao: '',
        quantidade: '1',
        valor: '350',
      );

      final bytes = await gerarPdfProposta(
        PropostaPdf(
          numero: 1,
          emitidaEm: '03/10/2026',
          validaAte: '10/10/2026',
          linhas: [
            LinhaPdf(nome: hora.texto, detalhe: '', total: ''),
            LinhaPdf(nome: fechado.texto, detalhe: '', total: ''),
            LinhaPdf(nome: licenca.texto, detalhe: '', total: ''),
          ],
          mensalidades: [mensal.texto],
          total: r'R$ 4.320,00',
        ),
      );

      final texto = latin1
          .decode(bytes, allowInvalid: true)
          .replaceAll('\x00', '');
      expect(texto, contains('Desenvolvimento'));
      expect(texto, contains('50 h'));
      expect(texto, contains('60,00'));
      expect(texto, contains('3.000,00'));
      expect(texto, contains('Implanta'));
      expect(texto, contains('1.200,00'));
      expect(texto, contains('3 licen'));
      expect(texto, contains('40,00'));
      expect(texto, contains('350,00'));
      expect(texto, contains('a partir do uso'));
      expect(texto, contains('4.320,00'));
    },
  );

  test('nome curto permanece grande e nome longo cabe numa linha', () async {
    final fonte = await rootBundle.load('assets/fonts/DejaVuSans-Bold.ttf');
    final curto = medidaTituloEmpresa('Pactto', fonte);
    expect(curto.tamanho, tamanhoBaseTituloEmpresa);
    expect(curto.linhas, 1);

    const longo = 'Consultoria e Desenvolvimento de Sistemas Integrados Ltda';
    final medida = medidaTituloEmpresa(longo, fonte);
    expect(medida.linhas, 1);
    expect(medida.tamanho, lessThan(tamanhoBaseTituloEmpresa));
    expect(medida.tamanho, greaterThanOrEqualTo(tamanhoMinimoTituloEmpresa));

    final enorme = medidaTituloEmpresa('A' * 180, fonte);
    expect(enorme.tamanho, tamanhoMinimoTituloEmpresa);
    expect(enorme.linhas, 2);
  });

  test('proposta longa continua na página seguinte', () async {
    final doc = await montarPdfProposta(
      PropostaPdf(
        numero: 3,
        emitidaEm: '03/10/2026',
        validaAte: '10/10/2026',
        linhas: [
          for (var i = 1; i <= 60; i++)
            LinhaPdf(nome: 'Item $i — R\$ 10,00', detalhe: '', total: ''),
        ],
        total: r'R$ 600,00',
      ),
    );
    await doc.save();
    expect(doc.document.pdfPageList.pages.length, greaterThan(1));
  });

  test('o logo da empresa entra no cabeçalho', () async {
    final semLogo = await gerarPdfProposta(_simples());
    final comLogo = await gerarPdfProposta(_simples(logo: _png1x1));
    expect(comLogo.length, greaterThan(semLogo.length));
  });

  test('o arquivo leva número e cliente, sem acento', () {
    expect(_simples().nomeArquivo, 'proposta-0007.pdf');
    expect(
      _simples(cliente: 'João da Conceição & Filhos').nomeArquivo,
      'proposta-0007-joao-da-conceicao-filhos.pdf',
    );
  });

  test('só PNG e JPG legíveis servem de logo', () {
    expect(imagemAceitaNoPdf(_png1x1), isTrue);
    expect(imagemAceitaNoPdf(Uint8List.fromList(utf8.encode('logo'))), isFalse);
  });
}

PropostaPdf _simples({Uint8List? logo, String? cliente}) => PropostaPdf(
  numero: 7,
  emitidaEm: '03/10/2026',
  validaAte: '10/10/2026',
  linhas: const [LinhaPdf(nome: 'Serviço', detalhe: '', total: '')],
  total: r'R$ 10,00',
  logo: logo,
  clienteNome: cliente,
);

final _png1x1 = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==',
);
