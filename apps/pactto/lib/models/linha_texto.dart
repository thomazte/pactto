/// Uma linha do corpo de um texto, do jeito que a folha e o PDF desenham.
class LinhaTexto {
  const LinhaTexto({required this.topico, this.rotulo, required this.resto});

  /// Linha que começou com "- ".
  final bool topico;

  /// Parte em negrito no começo da linha, já com os dois-pontos.
  final String? rotulo;
  final String resto;
}

/// Lê o corpo linha a linha. Viram negrito:
/// - o começo de um tópico até o primeiro ": ", quando é curto e sem ponto,
///   como em "- Prazo de entrega: 30 dias";
/// - uma linha comum de até três palavras terminada em ":", como "Inclui:".
List<LinhaTexto> lerCorpo(String corpo) {
  final linhas = <LinhaTexto>[];
  for (final bruta in corpo.split('\n')) {
    var texto = bruta.trim();
    if (texto.isEmpty) continue;
    final topico = texto.startsWith('- ');
    if (topico) texto = texto.substring(2).trim();

    if (topico) {
      final fim = texto.indexOf(': ');
      final rotulo = fim > 0 ? texto.substring(0, fim) : '';
      if (rotulo.isNotEmpty && rotulo.length <= 50 && !rotulo.contains('.')) {
        linhas.add(
          LinhaTexto(
            topico: true,
            rotulo: '$rotulo:',
            resto: texto.substring(fim + 1),
          ),
        );
        continue;
      }
    } else if (texto.endsWith(':') && texto.split(' ').length <= 3) {
      linhas.add(LinhaTexto(topico: false, rotulo: texto, resto: ''));
      continue;
    }
    linhas.add(LinhaTexto(topico: topico, resto: texto));
  }
  return linhas;
}
