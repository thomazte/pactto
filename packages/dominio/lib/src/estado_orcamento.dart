import 'erro_dominio.dart';

enum StatusOrcamento { rascunho, enviado, aprovado, recusado, concluido, expirado }

enum AtorTransicao { prestador, cliente, sistema }

final class _Regra {
  const _Regra(this.de, this.para, this.atores, {this.exigeMotivo = false});

  final StatusOrcamento de;
  final StatusOrcamento para;
  final Set<AtorTransicao> atores;
  final bool exigeMotivo;
}

const _regras = <_Regra>[
  _Regra(StatusOrcamento.rascunho, StatusOrcamento.enviado, {AtorTransicao.prestador}),
  _Regra(
    StatusOrcamento.enviado,
    StatusOrcamento.aprovado,
    {AtorTransicao.cliente, AtorTransicao.prestador},
  ),
  _Regra(
    StatusOrcamento.enviado,
    StatusOrcamento.recusado,
    {AtorTransicao.cliente, AtorTransicao.prestador},
    exigeMotivo: true,
  ),
  _Regra(StatusOrcamento.enviado, StatusOrcamento.expirado, {AtorTransicao.sistema}),
  _Regra(
    StatusOrcamento.enviado,
    StatusOrcamento.rascunho,
    {AtorTransicao.cliente},
    exigeMotivo: true,
  ),
  _Regra(StatusOrcamento.aprovado, StatusOrcamento.concluido, {AtorTransicao.prestador}),
  _Regra(StatusOrcamento.recusado, StatusOrcamento.rascunho, {AtorTransicao.prestador}),
  _Regra(StatusOrcamento.expirado, StatusOrcamento.rascunho, {AtorTransicao.prestador}),
];

StatusOrcamento transicionar({
  required StatusOrcamento de,
  required StatusOrcamento para,
  required AtorTransicao ator,
  String? motivo,
}) {
  _Regra? regra;
  for (final candidata in _regras) {
    if (candidata.de == de && candidata.para == para) {
      regra = candidata;
      break;
    }
  }
  if (regra == null || !regra.atores.contains(ator)) {
    throw const ErroDominio('transicao_invalida');
  }
  if (regra.exigeMotivo && (motivo?.trim().length ?? 0) < 10) {
    throw const ErroDominio('motivo_obrigatorio');
  }
  return para;
}
