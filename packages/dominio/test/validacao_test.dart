import 'package:dominio/dominio.dart';
import 'package:test/test.dart';

Matcher erro(String codigo) => throwsA(
      isA<ErroDominio>().having((e) => e.codigo, 'codigo', codigo),
    );

void main() {
  test('VAL-02 CPF válido persiste só os dígitos', () {
    expect(normalizarDocumento('111.444.777-35', cnpj: false), '11144477735');
    expect(cpfValido('111.444.777-34'), isFalse);
  });

  test('VAL-03 CNPJ válido persiste só os dígitos', () {
    expect(normalizarDocumento('11.222.333/0001-81', cnpj: true), '11222333000181');
    expect(cnpjValido('11.222.333/0001-80'), isFalse);
  });

  test('VAL-04 envio sem Pix é bloqueado', () {
    expect(
      () => validarEnvio(
        const EnvioOrcamento(
          perfilTemPix: false,
          clienteTemWhatsapp: true,
          quantidadeItens: 1,
          condicao: CondicaoPagamento.aVista,
          meioAVista: MeioAVista.pix,
          totalCentavos: 1000,
        ),
      ),
      erro('pix_obrigatorio'),
    );
  });

  test('VAL-07 validade aceita 1 e 365', () {
    final envio = DateTime.utc(2026, 9, 29, 2, 30);
    expect(calcularValidoAte(enviadoEm: envio, validadeDias: 1), DateTime.utc(2026, 9, 29));
    expect(calcularValidoAte(enviadoEm: envio, validadeDias: 365), DateTime.utc(2027, 9, 28));
    expect(() => calcularValidoAte(enviadoEm: envio, validadeDias: 0), erro('validade_invalida'));
    expect(() => calcularValidoAte(enviadoEm: envio, validadeDias: 366), erro('validade_invalida'));
  });

  test('VAL-08 parcelas de 2 a 24', () {
    validarEnvio(
      const EnvioOrcamento(
        perfilTemPix: true,
        clienteTemWhatsapp: true,
        quantidadeItens: 1,
        condicao: CondicaoPagamento.parcelado,
        parcelas: 2,
        totalCentavos: 1000,
      ),
    );
    expect(
      () => validarEnvio(
        const EnvioOrcamento(
          perfilTemPix: true,
          clienteTemWhatsapp: true,
          quantidadeItens: 1,
          condicao: CondicaoPagamento.parcelado,
          parcelas: 1,
          totalCentavos: 1000,
        ),
      ),
      erro('parcelas_invalidas'),
    );
    expect(
      () => validarEnvio(
        const EnvioOrcamento(
          perfilTemPix: true,
          clienteTemWhatsapp: true,
          quantidadeItens: 1,
          condicao: CondicaoPagamento.parcelado,
          parcelas: 25,
          totalCentavos: 1000,
        ),
      ),
      erro('parcelas_invalidas'),
    );
  });

  test('VAL-09 envio sem itens', () {
    expect(
      () => validarEnvio(
        const EnvioOrcamento(
          perfilTemPix: true,
          clienteTemWhatsapp: true,
          quantidadeItens: 0,
          condicao: CondicaoPagamento.aVista,
          meioAVista: MeioAVista.pix,
          totalCentavos: 0,
        ),
      ),
      erro('itens_obrigatorios'),
    );
  });
}
