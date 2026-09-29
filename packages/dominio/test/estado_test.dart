import 'package:dominio/dominio.dart';
import 'package:test/test.dart';

Matcher erro(String codigo) => throwsA(
      isA<ErroDominio>().having((e) => e.codigo, 'codigo', codigo),
    );

void main() {
  test('INT-04 rascunho, enviado, aprovado e concluído', () {
    var status = StatusOrcamento.rascunho;
    status = transicionar(de: status, para: StatusOrcamento.enviado, ator: AtorTransicao.prestador);
    status = transicionar(de: status, para: StatusOrcamento.aprovado, ator: AtorTransicao.cliente);
    status = transicionar(de: status, para: StatusOrcamento.concluido, ator: AtorTransicao.prestador);
    expect(status, StatusOrcamento.concluido);
  });

  test('INT-05 rascunho não aprova', () {
    expect(
      () => transicionar(
        de: StatusOrcamento.rascunho,
        para: StatusOrcamento.aprovado,
        ator: AtorTransicao.cliente,
      ),
      erro('transicao_invalida'),
    );
  });

  test('INT-06 enviado não conclui', () {
    expect(
      () => transicionar(
        de: StatusOrcamento.enviado,
        para: StatusOrcamento.concluido,
        ator: AtorTransicao.prestador,
      ),
      erro('transicao_invalida'),
    );
  });

  test('recusa e ajuste exigem motivo de 10 caracteres', () {
    expect(
      () => transicionar(
        de: StatusOrcamento.enviado,
        para: StatusOrcamento.recusado,
        ator: AtorTransicao.cliente,
        motivo: 'curto',
      ),
      erro('motivo_obrigatorio'),
    );
    expect(
      transicionar(
        de: StatusOrcamento.enviado,
        para: StatusOrcamento.recusado,
        ator: AtorTransicao.cliente,
        motivo: 'Valor acima do combinado',
      ),
      StatusOrcamento.recusado,
    );
    expect(
      transicionar(
        de: StatusOrcamento.enviado,
        para: StatusOrcamento.rascunho,
        ator: AtorTransicao.cliente,
        motivo: 'Trocar a torneira da cozinha',
      ),
      StatusOrcamento.rascunho,
    );
  });

  test('sistema expira e prestador reabre recusado ou expirado', () {
    expect(
      transicionar(
        de: StatusOrcamento.enviado,
        para: StatusOrcamento.expirado,
        ator: AtorTransicao.sistema,
      ),
      StatusOrcamento.expirado,
    );
    expect(
      transicionar(
        de: StatusOrcamento.expirado,
        para: StatusOrcamento.rascunho,
        ator: AtorTransicao.prestador,
      ),
      StatusOrcamento.rascunho,
    );
    expect(
      transicionar(
        de: StatusOrcamento.recusado,
        para: StatusOrcamento.rascunho,
        ator: AtorTransicao.prestador,
      ),
      StatusOrcamento.rascunho,
    );
  });

  test('cliente não conclui orçamento aprovado', () {
    expect(
      () => transicionar(
        de: StatusOrcamento.aprovado,
        para: StatusOrcamento.concluido,
        ator: AtorTransicao.cliente,
      ),
      erro('transicao_invalida'),
    );
  });
}
