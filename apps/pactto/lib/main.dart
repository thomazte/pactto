import 'package:flutter/material.dart';

import 'app.dart';
import 'services/empresa_local.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final empresa = await const EmpresaLocal().carregar();
  runApp(PrestadorApp(empresa: empresa));
}
