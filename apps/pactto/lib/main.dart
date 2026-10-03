import 'package:flutter/material.dart';

import 'app.dart';
import 'services/empresa_local.dart';
import 'services/numeracao_local.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final empresa = await const EmpresaLocal().carregar();
  final numero = await const NumeracaoLocal().carregar();
  final logoPadrao = await carregarLogoPadrao();
  runApp(
    PrestadorApp(empresa: empresa, numero: numero, logoPadrao: logoPadrao),
  );
}
