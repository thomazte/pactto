import 'package:dominio/dominio.dart';

class ResumoOrcamento {
  const ResumoOrcamento.ok(this.totais) : mensagem = null;
  const ResumoOrcamento.falha(this.mensagem) : totais = null;

  final TotaisOrcamento? totais;
  final String? mensagem;
}
