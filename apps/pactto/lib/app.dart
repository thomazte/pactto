import 'package:flutter/material.dart';

import 'core/theme/tema.dart';
import 'models/empresa.dart';
import 'views/proposta/tela_proposta.dart';

class PrestadorApp extends StatelessWidget {
  const PrestadorApp({super.key, this.empresa = const Empresa()});

  final Empresa empresa;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pactto',
      debugShowCheckedModeBanner: false,
      theme: temaPrestador(),
      home: TelaProposta(empresa: empresa),
    );
  }
}
