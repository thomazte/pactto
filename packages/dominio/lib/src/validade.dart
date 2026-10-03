import 'erro_dominio.dart';
import 'estado_orcamento.dart';

/// São Paulo está em UTC−3 o ano inteiro desde 2019.
const deslocamentoSaoPaulo = Duration(hours: -3);

DateTime dataCivilSaoPaulo(DateTime instante) {
  final local = instante.toUtc().add(deslocamentoSaoPaulo);
  return DateTime.utc(local.year, local.month, local.day);
}

DateTime calcularValidoAte({
  required DateTime enviadoEm,
  required int validadeDias,
}) {
  if (validadeDias < 1 || validadeDias > 365) {
    throw const ErroDominio('validade_invalida');
  }
  return dataCivilSaoPaulo(enviadoEm).add(Duration(days: validadeDias));
}

/// Verdadeira quando a data civil de São Paulo já passou de [validoAte].
bool propostaVencida({
  required StatusOrcamento status,
  required DateTime validoAte,
  required DateTime agora,
}) {
  if (status != StatusOrcamento.enviado) {
    return false;
  }
  final hoje = dataCivilSaoPaulo(agora);
  final limite = DateTime.utc(validoAte.toUtc().year, validoAte.toUtc().month, validoAte.toUtc().day);
  return hoje.isAfter(limite);
}

/// Data civil no formato pt-BR. 3 de outubro de 2026 vira "03/10/2026".
String formatarData(DateTime data) {
  final dia = data.day.toString().padLeft(2, '0');
  final mes = data.month.toString().padLeft(2, '0');
  return '$dia/$mes/${data.year}';
}
