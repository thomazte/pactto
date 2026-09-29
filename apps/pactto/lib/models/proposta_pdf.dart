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
    required this.linhas,
    required this.total,
    this.desconto,
    this.visita,
    this.validadeDias = 7,
    this.empresaNome,
    this.empresaLinhas = const [],
    this.empresaPix,
    this.clienteNome,
    this.clienteContato,
  });

  final List<LinhaPdf> linhas;
  final String total;
  final String? desconto;
  final String? visita;
  final int validadeDias;
  final String? empresaNome;
  final List<String> empresaLinhas;
  final String? empresaPix;
  final String? clienteNome;
  final String? clienteContato;
}
