import 'package:flutter/services.dart';

/// Máscara aplicada enquanto a pessoa digita. O cursor fica depois do mesmo
/// dígito em que estava, mesmo quando a máscara põe ou tira pontuação.
abstract class MascaraDigitos extends TextInputFormatter {
  const MascaraDigitos();

  String formatar(String texto);

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final texto = formatar(newValue.text);
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
