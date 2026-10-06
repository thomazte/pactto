import 'package:flutter/material.dart';

import 'app.dart';
import 'services/empresa_local.dart';
import 'services/modelos_local.dart';
import 'services/numeracao_local.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final empresa = await const EmpresaLocal().carregar();
  final numero = await const NumeracaoLocal().carregar();
  final logoPadrao = await carregarLogoPadrao();
  final modelos = await const ModelosLocal().carregar();
  runApp(
    PrestadorApp(
      empresa: empresa,
      numero: numero,
      logoPadrao: logoPadrao,
      modelos: modelos.modelos,
      modeloId: modelos.escolhido,
    ),
  );
}
