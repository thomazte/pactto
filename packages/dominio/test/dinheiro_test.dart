import 'package:dominio/dominio.dart';
import 'package:test/test.dart';

Matcher erro(String codigo) => throwsA(
      isA<ErroDominio>().having((e) => e.codigo, 'codigo', codigo),
    );

void main() {
  group('linhas e totais', () {
    test('FIN-01 fração 0,5 na linha sobe', () {
      expect(
        totalLinhaCentavos(quantidadeMilesimos: 2500, valorUnitarioCentavos: 3333),
        8333,
      );
    });

    test('FIN-02 linha exata', () {
      expect(
        totalLinhaCentavos(quantidadeMilesimos: 1005, valorUnitarioCentavos: 1000),
        1005,
      );
    });

    test('FIN-03 soma três linhas de 10 centavos', () {
      final totais = calcularOrcamento(
        linhas: const [
          LinhaOrcamento(tipo: TipoItem.maoDeObra, quantidadeMilesimos: 1000, valorUnitarioCentavos: 10),
          LinhaOrcamento(tipo: TipoItem.maoDeObra, quantidadeMilesimos: 1000, valorUnitarioCentavos: 10),
          LinhaOrcamento(tipo: TipoItem.maoDeObra, quantidadeMilesimos: 1000, valorUnitarioCentavos: 10),
        ],
        descontoTipo: TipoDesconto.nenhum,
      );
      expect(totais.subtotalMaoDeObraCentavos, 30);
      expect(totais.totalCentavos, 30);
    });

    test('FIN-04 desconto de 10% sobre 3333', () {
      final totais = calcularOrcamento(
        linhas: const [
          LinhaOrcamento(tipo: TipoItem.maoDeObra, quantidadeMilesimos: 1000, valorUnitarioCentavos: 3333),
        ],
        descontoTipo: TipoDesconto.percentual,
        descontoPercentualBps: 1000,
      );
      expect(totais.descontoCentavos, 333);
      expect(totais.totalCentavos, 3000);
    });

    test('FIN-05 meio centavo no desconto sobe', () {
      final totais = calcularOrcamento(
        linhas: const [
          LinhaOrcamento(tipo: TipoItem.material, quantidadeMilesimos: 1000, valorUnitarioCentavos: 1),
        ],
        descontoTipo: TipoDesconto.percentual,
        descontoPercentualBps: 5000,
      );
      expect(totais.descontoCentavos, 1);
      expect(totais.totalCentavos, 0);
    });

    test('FIN-06 1 bps sobre 1 centavo zera o desconto', () {
      final totais = calcularOrcamento(
        linhas: const [
          LinhaOrcamento(tipo: TipoItem.material, quantidadeMilesimos: 1000, valorUnitarioCentavos: 1),
        ],
        descontoTipo: TipoDesconto.percentual,
        descontoPercentualBps: 1,
      );
      expect(totais.descontoCentavos, 0);
      expect(totais.totalCentavos, 1);
    });

    test('FIN-07 desconto fixo e taxa', () {
      final totais = calcularOrcamento(
        linhas: const [
          LinhaOrcamento(tipo: TipoItem.maoDeObra, quantidadeMilesimos: 1000, valorUnitarioCentavos: 10000),
        ],
        descontoTipo: TipoDesconto.fixo,
        descontoFixoCentavos: 2000,
        taxaDeslocamentoCentavos: 5000,
      );
      expect(totais.totalCentavos, 13000);
    });

    test('FIN-08 taxa fica fora do percentual', () {
      final totais = calcularOrcamento(
        linhas: const [
          LinhaOrcamento(tipo: TipoItem.maoDeObra, quantidadeMilesimos: 1000, valorUnitarioCentavos: 10000),
        ],
        descontoTipo: TipoDesconto.percentual,
        descontoPercentualBps: 1000,
        taxaDeslocamentoCentavos: 5000,
      );
      expect(totais.descontoCentavos, 1000);
      expect(totais.totalCentavos, 14000);
    });

    test('FIN-09 desconto de 100% deixa só a taxa', () {
      final totais = calcularOrcamento(
        linhas: const [
          LinhaOrcamento(tipo: TipoItem.maoDeObra, quantidadeMilesimos: 1000, valorUnitarioCentavos: 5000),
        ],
        descontoTipo: TipoDesconto.percentual,
        descontoPercentualBps: 10000,
        taxaDeslocamentoCentavos: 1500,
      );
      expect(totais.totalCentavos, 1500);
    });

    test('FIN-10 desconto fixo acima da base', () {
      expect(
        () => calcularOrcamento(
          linhas: const [
            LinhaOrcamento(tipo: TipoItem.maoDeObra, quantidadeMilesimos: 1000, valorUnitarioCentavos: 2000),
          ],
          descontoTipo: TipoDesconto.fixo,
          descontoFixoCentavos: 2001,
        ),
        erro('desconto_acima_da_base'),
      );
    });

    test('FIN-11 percentual acima de 10000 bps', () {
      expect(
        () => calcularOrcamento(
          linhas: const [
            LinhaOrcamento(tipo: TipoItem.maoDeObra, quantidadeMilesimos: 1000, valorUnitarioCentavos: 100),
          ],
          descontoTipo: TipoDesconto.percentual,
          descontoPercentualBps: 10001,
        ),
        erro('desconto_percentual_invalido'),
      );
    });

    test('FIN-12 somente mão de obra', () {
      final totais = calcularOrcamento(
        linhas: const [
          LinhaOrcamento(tipo: TipoItem.maoDeObra, quantidadeMilesimos: 1000, valorUnitarioCentavos: 20000),
        ],
        descontoTipo: TipoDesconto.fixo,
        descontoFixoCentavos: 2000,
      );
      expect(totais.subtotalMateriaisCentavos, 0);
      expect(totais.totalCentavos, 18000);
    });

    test('FIN-13 somente materiais', () {
      final totais = calcularOrcamento(
        linhas: const [
          LinhaOrcamento(tipo: TipoItem.material, quantidadeMilesimos: 1000, valorUnitarioCentavos: 8000),
        ],
        descontoTipo: TipoDesconto.nenhum,
        taxaDeslocamentoCentavos: 1000,
      );
      expect(totais.subtotalMaoDeObraCentavos, 0);
      expect(totais.totalCentavos, 9000);
    });

    test('FIN-14 grandeza acima de 2^53', () {
      expect(
        totalLinhaCentavos(
          quantidadeMilesimos: 999999999,
          valorUnitarioCentavos: 99999999999,
        ),
        99999999899000000,
      );
    });

    test('FIN-15 quantidade com 4 casas decimais', () {
      expect(() => parseQuantidadeMilesimos('1,0005'), erro('quantidade_invalida'));
    });

    test('FIN-16 preço zero é cortesia', () {
      expect(
        totalLinhaCentavos(quantidadeMilesimos: 3000, valorUnitarioCentavos: 0),
        0,
      );
    });

    test('FIN-17 quantidade zero ou negativa', () {
      expect(
        () => totalLinhaCentavos(quantidadeMilesimos: 0, valorUnitarioCentavos: 100),
        erro('quantidade_invalida'),
      );
      expect(() => parseQuantidadeMilesimos('-1'), erro('quantidade_invalida'));
    });

    test('FIN-18 preço negativo', () {
      expect(
        () => totalLinhaCentavos(quantidadeMilesimos: 1000, valorUnitarioCentavos: -1),
        erro('preco_negativo'),
      );
    });

    test('FIN-19 parcelas carregam o resto nas primeiras', () {
      expect(distribuirParcelas(10000, 3), [3334, 3333, 3333]);
      expect(distribuirParcelas(10000, 3).reduce((a, b) => a + b), 10000);
    });

    test('FIN-20 entrada tem de ser menor que o total', () {
      expect(saldoAposEntrada(10000, 4000), 6000);
      expect(() => saldoAposEntrada(10000, 10000), erro('entrada_invalida'));
      expect(() => saldoAposEntrada(10000, 10001), erro('entrada_invalida'));
    });

    test('2,500 em milésimos', () {
      expect(parseQuantidadeMilesimos('2,500'), 2500);
      expect(parseQuantidadeMilesimos('2,5'), 2500);
    });

    test('FIN-21 quantidade com ponto decimal', () {
      expect(parseQuantidadeMilesimos('2.5'), 2500);
      expect(parseQuantidadeMilesimos('2.75'), 2750);
      expect(() => parseQuantidadeMilesimos('1.500'), erro('quantidade_invalida'));
      expect(() => parseQuantidadeMilesimos('1.2.3'), erro('quantidade_invalida'));
    });

    test('FIN-22 quantidade enorme é erro de domínio, não estouro', () {
      expect(
        () => parseQuantidadeMilesimos('99999999999999999'),
        erro('valor_acima_do_limite'),
      );
      expect(
        () => parseQuantidadeMilesimos('9' * 30),
        erro('valor_acima_do_limite'),
      );
    });

    test('FIN-23 quantidade formatada sem zeros à direita', () {
      expect(formatarQuantidade(2500), '2,5');
      expect(formatarQuantidade(2750), '2,75');
      expect(formatarQuantidade(50000), '50');
      expect(formatarQuantidade(1005), '1,005');
    });
  });

  group('moeda', () {
    test('MOE-01 formata 8333 centavos', () {
      expect(formatarReais(8333), r'R$ 83,33');
    });

    test('MOE-02 lê máscara pt-BR', () {
      expect(parseReaisCentavos('1.234,50'), 123450);
    });

    test('MOE-03 0,10 mais 0,20 fecha em 30 centavos', () {
      expect(parseReaisCentavos('0,10') + parseReaisCentavos('0,20'), 30);
    });

    test('MOE-04 ponto com 1 ou 2 casas é decimal', () {
      expect(parseReaisCentavos('10.5'), 1050);
      expect(parseReaisCentavos('33.33'), 3333);
      expect(parseReaisCentavos('1.234'), 123400);
      expect(parseReaisCentavos('1.234.567'), 123456700);
      expect(() => parseReaisCentavos('1.234.5'), erro('moeda_invalida'));
    });

    test('MOE-05 valor enorme é erro de domínio, não estouro', () {
      expect(
        () => parseReaisCentavos('999999999999999999'),
        erro('valor_acima_do_limite'),
      );
      expect(
        () => parseReaisCentavos('9' * 30),
        erro('valor_acima_do_limite'),
      );
      expect(
        () => parseReaisCentavos('-${'9' * 30}'),
        erro('valor_acima_do_limite'),
      );
    });
  });
}
