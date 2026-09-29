import 'erro_dominio.dart';

/// Maior centavos que cabe num inteiro de 64 bits com sinal.
final BigInt limiteCentavos = BigInt.parse('9223372036854775807');

/// Divisão half-up para valores não negativos.
///
/// O resto vezes 2, se atingir o divisor, sobe uma unidade.
int halfUpDiv(BigInt numerador, BigInt divisor) {
  if (numerador.isNegative || divisor <= BigInt.zero) {
    throw const ErroDominio('arredondamento_invalido');
  }
  final quociente = numerador ~/ divisor;
  final resto = numerador.remainder(divisor);
  final sobe = resto * BigInt.two >= divisor;
  return centavosSeguros(sobe ? quociente + BigInt.one : quociente);
}

int centavosSeguros(BigInt valor) {
  if (valor.isNegative || valor > limiteCentavos) {
    throw const ErroDominio('valor_acima_do_limite');
  }
  return valor.toInt();
}

int somarCentavos(int a, int b) => centavosSeguros(BigInt.from(a) + BigInt.from(b));
