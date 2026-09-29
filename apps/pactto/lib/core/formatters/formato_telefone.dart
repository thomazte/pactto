import 'package:flutter/services.dart';

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

class FormatoTelefone extends TextInputFormatter {
  const FormatoTelefone();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final texto = formatarTelefone(newValue.text);
    final noFim =
        newValue.selection.isCollapsed &&
        newValue.selection.end >= newValue.text.length;
    final offset = noFim
        ? texto.length
        : _posicao(texto, _digitosAte(newValue));
    return TextEditingValue(
      text: texto,
      selection: TextSelection.collapsed(offset: offset.clamp(0, texto.length)),
    );
  }

  int _digitosAte(TextEditingValue valor) {
    final fim = valor.selection.end.clamp(0, valor.text.length);
    return valor.text.substring(0, fim).replaceAll(RegExp(r'\D'), '').length;
  }

  int _posicao(String texto, int digitos) {
    var vistos = 0;
    for (var i = 0; i < texto.length; i++) {
      final codigo = texto.codeUnitAt(i);
      if (codigo >= 48 && codigo <= 57) {
        vistos++;
        if (vistos == digitos) return i + 1;
      }
    }
    return texto.length;
  }
}
