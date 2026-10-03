import 'package:dominio/dominio.dart';

import 'atalho_item.dart';

class LinhaDigitada {
  const LinhaDigitada({
    required this.modalidade,
    required this.descricao,
    required this.quantidadeMilesimos,
    required this.valorCentavos,
  });

  /// Lê o que o prestador digitou. Lança [ErroDominio] quando a quantidade
  /// ou o valor não formam uma linha válida, para nenhuma linha inválida
  /// chegar à lista.
  factory LinhaDigitada.ler({
    required ModalidadeItem modalidade,
    required String descricao,
    required String quantidade,
    required String valor,
  }) {
    final quantidadeMilesimos = parseQuantidadeMilesimos(quantidade);
    final valorCentavos = parseReaisCentavos(valor);
    // Recusa quantidade zero, preço negativo e total acima do limite.
    totalLinhaCentavos(
      quantidadeMilesimos: quantidadeMilesimos,
      valorUnitarioCentavos: valorCentavos,
    );
    return LinhaDigitada(
      modalidade: modalidade,
      descricao: descricao,
      quantidadeMilesimos: quantidadeMilesimos,
      valorCentavos: valorCentavos,
    );
  }

  final ModalidadeItem modalidade;
  final String descricao;
  final int quantidadeMilesimos;
  final int valorCentavos;

  bool get somaNoOrcamento => modalidade.somaNoOrcamento;

  TipoItem get tipo => modalidade == ModalidadeItem.licenca
      ? TipoItem.material
      : TipoItem.maoDeObra;

  String get nome {
    if (descricao.isNotEmpty) return descricao;
    return switch (modalidade) {
      ModalidadeItem.licenca => 'Licença',
      ModalidadeItem.mensalidade => 'Mensalidade',
      ModalidadeItem.hora || ModalidadeItem.valorFechado => 'Serviço',
    };
  }

  /// Conta no formato em que a folha e o PDF mostram a linha.
  String get texto {
    final unitario = formatarReais(valorCentavos);
    final quantidade = formatarQuantidade(quantidadeMilesimos);
    switch (modalidade) {
      case ModalidadeItem.hora:
        final total = formatarReais(totalCentavos);
        return '$nome — $quantidade h × $unitario = $total';
      case ModalidadeItem.valorFechado:
        return '$nome — $unitario';
      case ModalidadeItem.mensalidade:
        return '$nome — $unitario por mês, a partir do uso';
      case ModalidadeItem.licenca:
        final unidade = quantidadeMilesimos == 1000 ? 'licença' : 'licenças';
        final conta = '$quantidade $unidade × $unitario';
        if (descricao.isEmpty) return conta;
        return '$descricao — $conta';
    }
  }

  int get totalCentavos {
    return totalLinhaCentavos(
      quantidadeMilesimos: quantidadeMilesimos,
      valorUnitarioCentavos: valorCentavos,
    );
  }
}
