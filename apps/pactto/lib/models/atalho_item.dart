enum ModalidadeItem {
  hora('Hora'),
  valorFechado('Valor fechado'),
  mensalidade('Mensalidade'),
  licenca('Licença');

  const ModalidadeItem(this.rotulo);

  final String rotulo;

  /// Mensalidade fica fora do total único do projeto.
  bool get somaNoOrcamento => this != mensalidade;

  bool get informaQuantidade => this == hora || this == licenca;
}
