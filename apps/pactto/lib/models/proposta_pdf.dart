import 'dart:typed_data';

class LinhaPdf {
  const LinhaPdf({
    required this.nome,
    required this.detalhe,
    required this.total,
  });

  final String nome;
  final String detalhe;
  final String total;
}

class PropostaPdf {
  const PropostaPdf({
    required this.numero,
    required this.emitidaEm,
    required this.validaAte,
    required this.linhas,
    required this.total,
    this.mensalidades = const [],
    this.desconto,
    this.visita,
    this.empresaNome,
    this.empresaLinhas = const [],
    this.empresaPix,
    this.clienteNome,
    this.clienteContato,
    this.logo,
  });

  final int numero;

  /// Datas já no formato pt-BR, como "03/10/2026".
  final String emitidaEm;
  final String validaAte;

  final List<LinhaPdf> linhas;

  /// Valores mensais, fora do total único do projeto.
  final List<String> mensalidades;
  final String total;
  final String? desconto;
  final String? visita;
  final String? empresaNome;
  final List<String> empresaLinhas;
  final String? empresaPix;
  final String? clienteNome;
  final String? clienteContato;
  final Uint8List? logo;

  /// "0012" para a proposta 12.
  String get numeroFormatado => numero.toString().padLeft(4, '0');

  /// Nome do arquivo entregue ao cliente, sem acento nem espaço.
  String get nomeArquivo {
    final cliente = _semAcento(clienteNome ?? '')
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
    return cliente.isEmpty
        ? 'proposta-$numeroFormatado.pdf'
        : 'proposta-$numeroFormatado-$cliente.pdf';
  }
}

String _semAcento(String texto) {
  const de = 'áàâãäéèêëíìîïóòôõöúùûüçñÁÀÂÃÄÉÈÊËÍÌÎÏÓÒÔÕÖÚÙÛÜÇÑ';
  const para = 'aaaaaeeeeiiiiooooouuuucnAAAAAEEEEIIIIOOOOOUUUUCN';
  final buffer = StringBuffer();
  for (final rune in texto.runes) {
    final letra = String.fromCharCode(rune);
    final indice = de.indexOf(letra);
    buffer.write(indice < 0 ? letra : para[indice]);
  }
  return buffer.toString();
}
