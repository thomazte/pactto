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

  factory LinhaDigitada.deJson(Map<String, dynamic> json) {
    return LinhaDigitada(
      modalidade: ModalidadeItem.values.firstWhere(
        (modalidade) => modalidade.name == json['modalidade'],
        orElse: () => ModalidadeItem.valorFechado,
      ),
      descricao: json['descricao'] as String? ?? '',
      quantidadeMilesimos: json['quantidadeMilesimos'] as int? ?? 1000,
      valorCentavos: json['valorCentavos'] as int? ?? 0,
    );
  }

  Map<String, dynamic> paraJson() => {
    'modalidade': modalidade.name,
    'descricao': descricao,
    'quantidadeMilesimos': quantidadeMilesimos,
    'valorCentavos': valorCentavos,
  };

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

  /// Coluna "Item" da tabela de investimento, com a conta quando há
  /// quantidade.
  String get item {
    final unitario = formatarReais(valorCentavos);
    final quantidade = formatarQuantidade(quantidadeMilesimos);
    return switch (modalidade) {
      ModalidadeItem.hora => '$nome ($quantidade h × $unitario)',
      ModalidadeItem.licenca =>
        '$nome ($quantidade ${quantidadeMilesimos == 1000 ? 'licença' : 'licenças'} × $unitario)',
      ModalidadeItem.valorFechado || ModalidadeItem.mensalidade => nome,
    };
  }

  /// Coluna "Cobrança": a mensalidade se repete, o resto é pago uma vez.
  String get cobranca => somaNoOrcamento ? 'única' : 'mensal';

  int get totalCentavos {
    return totalLinhaCentavos(
      quantidadeMilesimos: quantidadeMilesimos,
      valorUnitarioCentavos: valorCentavos,
    );
  }
}
