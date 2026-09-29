import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:pactto/models/proposta_pdf.dart';
import 'package:pactto/services/pdf_proposta.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('o PDF fala a mesma língua da folha do cliente', () async {
    final bytes = await gerarPdfProposta(
      const PropostaPdf(
        linhas: [
          LinhaPdf(
            nome: 'Hora de desenvolvimento',
            detalhe: '8 serviço × R\$ 180,00',
            total: 'R\$ 1.440,00',
          ),
        ],
        total: 'R\$ 1.440,00',
        validadeDias: 7,
        empresaPix: 'zamoht.exe@gmail.com',
      ),
    );

    final texto = latin1.decode(bytes, allowInvalid: true);
    expect(texto.startsWith('%PDF'), isTrue);
    expect(texto, contains('DejaVuSans'));
    expect(texto, contains('Proposta'));
    expect(texto, contains('Hora de desenvolvimento'));
    expect(texto, contains('1.440,00'));
  });
}
