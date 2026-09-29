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
int parseReaisCentavos(String entrada) {
  var texto = entrada.trim().replaceAll('R\$', '').replaceAll(' ', '');
  if (texto.isEmpty) {
    throw const ErroDominio('moeda_invalida');
  }
  final negativo = texto.startsWith('-');
  if (negativo) {
    texto = texto.substring(1);
  }
  if (!RegExp(r'^\d{1,3}(\.\d{3})*(,\d{1,2})?$|^\d+(,\d{1,2})?$').hasMatch(texto)) {
    throw const ErroDominio('moeda_invalida');
  }
  final partes = texto.split(',');
  final reais = int.parse(partes[0].replaceAll('.', ''));
  final fracaoTexto = partes.length == 2 ? partes[1].padRight(2, '0') : '00';
  final fracao = int.parse(fracaoTexto);
  final centavos = reais * 100 + fracao;
  return negativo ? -centavos : centavos;
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
