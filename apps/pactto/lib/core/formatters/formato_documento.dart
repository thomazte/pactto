import 'mascara_digitos.dart';

/// CPF ou CNPJ conforme a quantidade de dígitos, enquanto a pessoa digita.
/// Até 11 dígitos: 529.982.247-25. De 12 a 14: 47.407.013/0001-43.
String formatarDocumento(String texto) {
  var digitos = texto.replaceAll(RegExp(r'\D'), '');
  if (digitos.length > 14) digitos = digitos.substring(0, 14);
  final pontos = digitos.length <= 11
      ? const {3: '.', 6: '.', 9: '-'}
      : const {2: '.', 5: '.', 8: '/', 12: '-'};
  final buffer = StringBuffer();
  for (var i = 0; i < digitos.length; i++) {
    final separador = pontos[i];
    if (separador != null) buffer.write(separador);
    buffer.write(digitos[i]);
  }
  return buffer.toString();
}

class FormatoDocumento extends MascaraDigitos {
  const FormatoDocumento();

  @override
  String formatar(String texto) => formatarDocumento(texto);
}
