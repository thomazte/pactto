import 'mascara_digitos.dart';

/// Máscara brasileira enquanto a pessoa digita.
/// Celular com 11 dígitos: (62) 98483-5669.
/// Fixo com 10 dígitos: (62) 3483-5669.
String formatarTelefone(String texto) {
  var digitos = texto.replaceAll(RegExp(r'\D'), '');
  if (digitos.startsWith('55') &&
      (digitos.length == 12 || digitos.length == 13)) {
    digitos = digitos.substring(2);
  }
  if (digitos.length > 11) digitos = digitos.substring(0, 11);
  if (digitos.isEmpty) return '';

  final ddd = digitos.substring(0, digitos.length < 2 ? digitos.length : 2);
  if (digitos.length <= 2) return '($ddd';

  final resto = digitos.substring(2);
  if (digitos.length <= 6) return '($ddd) $resto';
  if (digitos.length <= 10) {
    final meio = resto.substring(0, 4);
    final fim = resto.substring(4);
    return '($ddd) $meio-$fim';
  }
  return '($ddd) ${resto.substring(0, 5)}-${resto.substring(5)}';
}

class FormatoTelefone extends MascaraDigitos {
  const FormatoTelefone();

  @override
  String formatar(String texto) => formatarTelefone(texto);
}
