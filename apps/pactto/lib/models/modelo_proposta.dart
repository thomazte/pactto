/// Onde o texto entra na proposta, em relação à lista de itens.
enum PosicaoTexto {
  antes('Antes dos itens'),
  depois('Depois dos itens');

  const PosicaoTexto(this.rotulo);

  final String rotulo;
}

/// Um bloco de texto da proposta: título e corpo. No corpo, linha que começa
/// com "- " vira tópico.
class TextoProposta {
  const TextoProposta({
    required this.titulo,
    required this.corpo,
    this.posicao = PosicaoTexto.antes,
  });

  factory TextoProposta.deJson(Map<String, dynamic> json) {
    return TextoProposta(
      titulo: json['titulo'] as String? ?? '',
      corpo: json['corpo'] as String? ?? '',
      posicao: json['posicao'] == PosicaoTexto.depois.name
          ? PosicaoTexto.depois
          : PosicaoTexto.antes,
    );
  }

  final String titulo;
  final String corpo;
  final PosicaoTexto posicao;

  bool get vazio => titulo.trim().isEmpty && corpo.trim().isEmpty;

  Map<String, dynamic> paraJson() => {
    'titulo': titulo,
    'corpo': corpo,
    'posicao': posicao.name,
  };
}

/// Conjunto de textos reaproveitado de uma proposta para outra.
class ModeloProposta {
  const ModeloProposta({
    required this.id,
    required this.nome,
    this.textos = const [],
    this.aceite = false,
  });

  factory ModeloProposta.deJson(Map<String, dynamic> json) {
    return ModeloProposta(
      id: json['id'] as String,
      nome: json['nome'] as String? ?? '',
      textos: [
        for (final texto in json['textos'] as List? ?? const [])
          TextoProposta.deJson(Map<String, dynamic>.from(texto as Map)),
      ],
      aceite: json['aceite'] == true,
    );
  }

  final String id;
  final String nome;
  final List<TextoProposta> textos;

  /// Fecha a proposta com validade, "De acordo" e linhas de assinatura.
  final bool aceite;

  Map<String, dynamic> paraJson() => {
    'id': id,
    'nome': nome,
    'textos': [for (final texto in textos) texto.paraJson()],
    'aceite': aceite,
  };
}
