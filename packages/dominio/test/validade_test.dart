import 'package:dominio/dominio.dart';
import 'package:test/test.dart';

void main() {
  // 2026-09-28 23:30 em São Paulo = 2026-09-29 02:30 UTC.
  final enviadoNoite = DateTime.utc(2026, 9, 29, 2, 30);

  test('EXP-01 validade de 1 dia a partir da data civil', () {
    expect(
      calcularValidoAte(enviadoEm: enviadoNoite, validadeDias: 1),
      DateTime.utc(2026, 9, 29),
    );
  });

  test('EXP-02 o dia de valido_ate ainda é válido', () {
    final vencida = propostaVencida(
      status: StatusOrcamento.enviado,
      validoAte: DateTime.utc(2026, 9, 29),
      agora: DateTime.utc(2026, 9, 29, 15),
    );
    expect(vencida, isFalse);
  });

  test('EXP-03 o dia seguinte expira só o enviado', () {
    expect(
      propostaVencida(
        status: StatusOrcamento.enviado,
        validoAte: DateTime.utc(2026, 9, 29),
        agora: DateTime.utc(2026, 9, 30, 3, 5),
      ),
      isTrue,
    );
  });

  test('EXP-04 rascunho e aprovado ficam de fora do job', () {
    final agora = DateTime.utc(2026, 10, 1, 15);
    expect(
      propostaVencida(
        status: StatusOrcamento.rascunho,
        validoAte: DateTime.utc(2026, 9, 1),
        agora: agora,
      ),
      isFalse,
    );
    expect(
      propostaVencida(
        status: StatusOrcamento.aprovado,
        validoAte: DateTime.utc(2026, 9, 1),
        agora: agora,
      ),
      isFalse,
    );
  });

  test('EXP-06 01:30 UTC cai no dia anterior em São Paulo', () {
    final enviado = DateTime.utc(2026, 9, 29, 1, 30);
    expect(dataCivilSaoPaulo(enviado), DateTime.utc(2026, 9, 28));
    expect(
      calcularValidoAte(enviadoEm: enviado, validadeDias: 1),
      DateTime.utc(2026, 9, 29),
    );
  });
}
