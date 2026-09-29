import 'erro_dominio.dart';

String somenteDigitos(String entrada) => entrada.replaceAll(RegExp(r'\D'), '');

bool cpfValido(String entrada) {
  final digitos = somenteDigitos(entrada);
  if (digitos.length != 11 || RegExp(r'^(\d)\1{10}$').hasMatch(digitos)) {
    return false;
  }
  final nums = digitos.split('').map(int.parse).toList();
  final d1 = _dvCpf(nums.sublist(0, 9));
  final d2 = _dvCpf([...nums.sublist(0, 9), d1]);
  return nums[9] == d1 && nums[10] == d2;
}

bool cnpjValido(String entrada) {
  final digitos = somenteDigitos(entrada);
  if (digitos.length != 14 || RegExp(r'^(\d)\1{13}$').hasMatch(digitos)) {
    return false;
  }
  final nums = digitos.split('').map(int.parse).toList();
  final d1 = _dvCnpj(nums.sublist(0, 12));
  final d2 = _dvCnpj([...nums.sublist(0, 12), d1]);
  return nums[12] == d1 && nums[13] == d2;
}

String normalizarDocumento(String entrada, {required bool cnpj}) {
  final valido = cnpj ? cnpjValido(entrada) : cpfValido(entrada);
  if (!valido) {
    throw const ErroDominio('documento_invalido');
  }
  return somenteDigitos(entrada);
}

int _dvCpf(List<int> base) {
  var soma = 0;
  var peso = base.length + 1;
  for (final numero in base) {
    soma += numero * peso;
    peso--;
  }
  final resto = (soma * 10) % 11;
  return resto == 10 ? 0 : resto;
}

int _dvCnpj(List<int> base) {
  final pesos = base.length == 12
      ? const [5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2]
      : const [6, 5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2];
  var soma = 0;
  for (var i = 0; i < base.length; i++) {
    soma += base[i] * pesos[i];
  }
  final resto = soma % 11;
  final dv = 11 - resto;
  return dv >= 10 ? 0 : dv;
}
