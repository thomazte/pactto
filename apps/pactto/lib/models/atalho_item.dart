import 'package:dominio/dominio.dart';

class AtalhoItem {
  const AtalhoItem(this.rotulo, this.tipo);

  final String rotulo;
  final TipoItem tipo;
}

const atalhosItem = <AtalhoItem>[
  AtalhoItem('Hora de desenvolvimento', TipoItem.maoDeObra),
  AtalhoItem('Suporte', TipoItem.maoDeObra),
  AtalhoItem('Licença', TipoItem.material),
];
