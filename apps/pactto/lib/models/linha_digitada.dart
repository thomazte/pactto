import 'package:dominio/dominio.dart';

class LinhaDigitada {
  const LinhaDigitada({
    required this.tipo,
    required this.descricao,
    required this.quantidade,
    required this.valor,
  });

  final TipoItem tipo;
  final String descricao;
  final String quantidade;
  final String valor;

  String get nome {
    if (descricao.isNotEmpty) return descricao;
    return tipo == TipoItem.maoDeObra ? 'Serviço' : 'Licença';
  }

  String get detalhe {
    final unidade = tipo == TipoItem.maoDeObra ? 'serviço' : 'licença';
    return '$quantidade $unidade × ${formatarReais(parseReaisCentavos(valor))}';
  }

  int get totalCentavos {
    return totalLinhaCentavos(
      quantidadeMilesimos: parseQuantidadeMilesimos(quantidade),
      valorUnitarioCentavos: parseReaisCentavos(valor),
    );
  }
}
