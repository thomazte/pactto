import '../models/modelo_proposta.dart';

/// Pedido que o prestador cola numa IA de conversa, como o Claude. A IA
/// devolve os textos no formato que [lerRespostaIa] entende.
String montarPedidoIa({
  required String topicos,
  String? cliente,
  List<TextoProposta> textos = const [],
}) {
  final buffer = StringBuffer()
    ..writeln('Você vai me ajudar a escrever uma proposta comercial.')
    ..writeln();
  if (cliente != null && cliente.trim().isNotEmpty) {
    buffer
      ..writeln('Cliente: ${cliente.trim()}')
      ..writeln();
  }
  buffer
    ..writeln('O que o cliente precisa:')
    ..writeln(topicos.trim())
    ..writeln();
  if (textos.isEmpty) {
    buffer.writeln(
      'Escreva dois textos para esta proposta: "Apresentação" e "Escopo".',
    );
  } else {
    buffer.writeln(
      'Reescreva os textos abaixo para esta proposta, '
      'com os mesmos títulos e na mesma ordem.',
    );
  }
  buffer
    ..writeln()
    ..writeln('Regras:')
    ..writeln('- Português do Brasil, tom profissional e direto.')
    ..writeln('- Frases curtas. Em listas, comece cada linha com "- ".')
    ..writeln(
      '- Não cite preços, prazos nem condições de pagamento que não estejam '
      'acima.',
    )
    ..writeln('- Sem negrito, tabelas ou outra formatação.')
    ..writeln(
      '- Responda só com os textos, cada um começando por uma linha '
      '"## Título".',
    );
  if (textos.isNotEmpty) {
    buffer
      ..writeln()
      ..writeln('Textos atuais:');
    for (final texto in textos) {
      buffer
        ..writeln()
        ..writeln('## ${texto.titulo}')
        ..writeln(texto.corpo.trim());
    }
  }
  return buffer.toString().trimRight();
}

/// Separa a resposta da IA em textos pelas linhas "## Título". O que vem
/// antes do primeiro título é ignorado. Negrito sai, e tópicos com "*" ou
/// "•" viram "- ".
List<TextoProposta> lerRespostaIa(String resposta) {
  final textos = <TextoProposta>[];
  String? titulo;
  final corpo = <String>[];

  void fechar() {
    final atual = titulo;
    if (atual == null) return;
    final linhas = corpo.join('\n').trim();
    if (atual.isNotEmpty || linhas.isNotEmpty) {
      textos.add(TextoProposta(titulo: atual, corpo: linhas));
    }
    corpo.clear();
  }

  for (final bruta in resposta.split('\n')) {
    final linha = bruta.replaceAll('**', '').trimRight();
    if (linha.trimLeft().startsWith('```')) continue;
    final cabecalho = RegExp(r'^\s*#{1,6}\s*(.*)$').firstMatch(linha);
    if (cabecalho != null) {
      fechar();
      titulo = cabecalho.group(1)!.trim().replaceFirst(RegExp(r':$'), '');
      continue;
    }
    if (titulo == null) continue;
    corpo.add(linha.trim().replaceFirst(RegExp(r'^[*•]\s+'), '- '));
  }
  fechar();
  return textos;
}
