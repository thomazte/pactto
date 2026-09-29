import 'arredondamento.dart';
import 'erro_dominio.dart';

enum TipoItem { maoDeObra, material }

enum TipoDesconto { nenhum, fixo, percentual }

enum CondicaoPagamento { aVista, parcelado, entradaSaldo }

enum MeioAVista { pix, dinheiro, ambos }

final class LinhaOrcamento {
  const LinhaOrcamento({
    required this.tipo,
    required this.quantidadeMilesimos,
    required this.valorUnitarioCentavos,
  });

  final TipoItem tipo;

  /// Quantidade com 3 casas. 2,500 vira 2500.
  final int quantidadeMilesimos;
  final int valorUnitarioCentavos;
}

final class TotaisOrcamento {
  const TotaisOrcamento({
    required this.subtotalMaoDeObraCentavos,
    required this.subtotalMateriaisCentavos,
    required this.baseCentavos,
    required this.descontoCentavos,
    required this.taxaDeslocamentoCentavos,
    required this.totalCentavos,
    required this.totaisLinhaCentavos,
  });

  final int subtotalMaoDeObraCentavos;
  final int subtotalMateriaisCentavos;
  final int baseCentavos;
  final int descontoCentavos;
  final int taxaDeslocamentoCentavos;
  final int totalCentavos;
  final List<int> totaisLinhaCentavos;
}

int totalLinhaCentavos({
  required int quantidadeMilesimos,
  required int valorUnitarioCentavos,
}) {
  if (quantidadeMilesimos <= 0) {
    throw const ErroDominio('quantidade_invalida');
  }
  if (valorUnitarioCentavos < 0) {
    throw const ErroDominio('preco_negativo');
  }
  final produto = BigInt.from(quantidadeMilesimos) * BigInt.from(valorUnitarioCentavos);
  return halfUpDiv(produto, BigInt.from(1000));
}

/// Quantidade pt-BR com no máximo 3 casas. "2,5" vira 2500 milésimos.
int parseQuantidadeMilesimos(String entrada) {
  final texto = entrada.trim();
  final match = RegExp(r'^(\d+)(?:,(\d{1,3}))?$').firstMatch(texto);
  if (match == null) {
    throw const ErroDominio('quantidade_invalida');
  }
  final inteiros = int.parse(match.group(1)!);
  final fracao = match.group(2);
  final milesimosFracao = fracao == null ? 0 : int.parse(fracao.padRight(3, '0'));
  return somarCentavos(inteiros * 1000, milesimosFracao);
}

TotaisOrcamento calcularOrcamento({
  required List<LinhaOrcamento> linhas,
  required TipoDesconto descontoTipo,
  int? descontoFixoCentavos,
  int? descontoPercentualBps,
  int taxaDeslocamentoCentavos = 0,
}) {
  if (taxaDeslocamentoCentavos < 0) {
    throw const ErroDominio('taxa_negativa');
  }

  final totaisLinha = <int>[];
  var mao = 0;
  var materiais = 0;
  for (final linha in linhas) {
    final total = totalLinhaCentavos(
      quantidadeMilesimos: linha.quantidadeMilesimos,
      valorUnitarioCentavos: linha.valorUnitarioCentavos,
    );
    totaisLinha.add(total);
    if (linha.tipo == TipoItem.maoDeObra) {
      mao = somarCentavos(mao, total);
    } else {
      materiais = somarCentavos(materiais, total);
    }
  }

  final base = somarCentavos(mao, materiais);
  final desconto = _desconto(
    base: base,
    tipo: descontoTipo,
    fixoCentavos: descontoFixoCentavos,
    bps: descontoPercentualBps,
  );

  return TotaisOrcamento(
    subtotalMaoDeObraCentavos: mao,
    subtotalMateriaisCentavos: materiais,
    baseCentavos: base,
    descontoCentavos: desconto,
    taxaDeslocamentoCentavos: taxaDeslocamentoCentavos,
    totalCentavos: somarCentavos(base - desconto, taxaDeslocamentoCentavos),
    totaisLinhaCentavos: totaisLinha,
  );
}

int _desconto({
  required int base,
  required TipoDesconto tipo,
  required int? fixoCentavos,
  required int? bps,
}) {
  switch (tipo) {
    case TipoDesconto.nenhum:
      if (fixoCentavos != null || bps != null) {
        throw const ErroDominio('desconto_inconsistente');
      }
      return 0;
    case TipoDesconto.fixo:
      if (bps != null || fixoCentavos == null || fixoCentavos < 0) {
        throw const ErroDominio('desconto_inconsistente');
      }
      if (fixoCentavos > base) {
        throw const ErroDominio('desconto_acima_da_base');
      }
      return fixoCentavos;
    case TipoDesconto.percentual:
      if (fixoCentavos != null || bps == null) {
        throw const ErroDominio('desconto_inconsistente');
      }
      if (bps < 0 || bps > 10000) {
        throw const ErroDominio('desconto_percentual_invalido');
      }
      return halfUpDiv(BigInt.from(base) * BigInt.from(bps), BigInt.from(10000));
  }
}

List<int> distribuirParcelas(int totalCentavos, int parcelas) {
  if (parcelas < 2 || parcelas > 24) {
    throw const ErroDominio('parcelas_invalidas');
  }
  if (totalCentavos < 0) {
    throw const ErroDominio('preco_negativo');
  }
  final base = totalCentavos ~/ parcelas;
  final resto = totalCentavos - base * parcelas;
  return List<int>.generate(parcelas, (i) => base + (i < resto ? 1 : 0));
}

int saldoAposEntrada(int totalCentavos, int entradaCentavos) {
  if (entradaCentavos <= 0 || entradaCentavos >= totalCentavos) {
    throw const ErroDominio('entrada_invalida');
  }
  return totalCentavos - entradaCentavos;
}

final class EnvioOrcamento {
  const EnvioOrcamento({
    required this.perfilTemPix,
    required this.clienteTemWhatsapp,
    required this.quantidadeItens,
    required this.condicao,
    required this.totalCentavos,
    this.meioAVista,
    this.parcelas,
    this.entradaCentavos,
  });

  final bool perfilTemPix;
  final bool clienteTemWhatsapp;
  final int quantidadeItens;
  final CondicaoPagamento condicao;
  final int totalCentavos;
  final MeioAVista? meioAVista;
  final int? parcelas;
  final int? entradaCentavos;
}

void validarEnvio(EnvioOrcamento envio) {
  if (!envio.perfilTemPix) {
    throw const ErroDominio('pix_obrigatorio');
  }
  if (!envio.clienteTemWhatsapp) {
    throw const ErroDominio('whatsapp_obrigatorio');
  }
  if (envio.quantidadeItens < 1) {
    throw const ErroDominio('itens_obrigatorios');
  }
  switch (envio.condicao) {
    case CondicaoPagamento.aVista:
      if (envio.meioAVista == null || envio.parcelas != null || envio.entradaCentavos != null) {
        throw const ErroDominio('pagamento_inconsistente');
      }
    case CondicaoPagamento.parcelado:
      final n = envio.parcelas;
      if (n == null || n < 2 || n > 24 || envio.entradaCentavos != null) {
        throw const ErroDominio('parcelas_invalidas');
      }
    case CondicaoPagamento.entradaSaldo:
      saldoAposEntrada(envio.totalCentavos, envio.entradaCentavos ?? 0);
  }
}
