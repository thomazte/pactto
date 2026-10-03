import 'arredondamento.dart';
import 'erro_dominio.dart';

String formatarReais(int centavos) {
  final negativo = centavos < 0;
  final absoluto = centavos.abs();
  final reais = absoluto ~/ 100;
  final fracao = (absoluto % 100).toString().padLeft(2, '0');
  final texto = 'R\$ ${_grupoMilhar(reais)},$fracao';
  return negativo ? '-$texto' : texto;
}

/// Máscara pt-BR. "1.234,50" vira 123450 centavos.
///
/// Sem vírgula, um único ponto seguido de 1 ou 2 dígitos é a casa decimal,
/// como digita o teclado numérico que não tem vírgula: "10.5" vira 1050.
int parseReaisCentavos(String entrada) {
  var texto = entrada.trim().replaceAll('R\$', '').replaceAll(' ', '');
  if (texto.isEmpty) {
    throw const ErroDominio('moeda_invalida');
  }
  final negativo = texto.startsWith('-');
  if (negativo) {
    texto = texto.substring(1);
  }
  texto = pontoComoVirgula(texto, casas: 2);
  if (!RegExp(r'^\d{1,3}(\.\d{3})*(,\d{1,2})?$|^\d+(,\d{1,2})?$').hasMatch(texto)) {
    throw const ErroDominio('moeda_invalida');
  }
  final partes = texto.split(',');
  final reais = BigInt.parse(partes[0].replaceAll('.', ''));
  final fracaoTexto = partes.length == 2 ? partes[1].padRight(2, '0') : '00';
  final centavos = centavosSeguros(
    reais * BigInt.from(100) + BigInt.parse(fracaoTexto),
  );
  return negativo ? -centavos : centavos;
}

/// Troca o ponto pela vírgula quando ele só pode ser a casa decimal:
/// texto sem vírgula, um único ponto e de 1 até [casas] dígitos depois dele.
/// "1.234" continua milhar quando [casas] é menor que 3.
String pontoComoVirgula(String texto, {required int casas}) {
  if (texto.contains(',')) return texto;
  final ponto = texto.indexOf('.');
  if (ponto < 0 || ponto != texto.lastIndexOf('.')) return texto;
  final depois = texto.length - ponto - 1;
  if (depois < 1 || depois > casas) return texto;
  return '${texto.substring(0, ponto)},${texto.substring(ponto + 1)}';
}

String _grupoMilhar(int valor) {
  final digitos = valor.toString();
  final buffer = StringBuffer();
  for (var i = 0; i < digitos.length; i++) {
    final faltam = digitos.length - i;
    if (i > 0 && faltam % 3 == 0) {
      buffer.write('.');
    }
    buffer.write(digitos[i]);
  }
  return buffer.toString();
}
