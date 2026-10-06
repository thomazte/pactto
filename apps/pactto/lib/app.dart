import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'core/theme/tema.dart';
import 'core/constants/modelos_padrao.dart';
import 'models/empresa.dart';
import 'models/modelo_proposta.dart';
import 'views/proposta/tela_proposta.dart';

class PrestadorApp extends StatelessWidget {
  const PrestadorApp({
    super.key,
    this.empresa = const Empresa(),
    this.numero = 1,
    this.logoPadrao,
    this.modelos = modelosPadrao,
    this.modeloId,
  });

  final Empresa empresa;

  /// Número da próxima proposta.
  final int numero;

  /// Logo que vale enquanto a empresa não escolhe outro.
  final Uint8List? logoPadrao;

  final List<ModeloProposta> modelos;

  /// Modelo que preenche os textos ao abrir. Null é "sem modelo".
  final String? modeloId;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pactto',
      debugShowCheckedModeBanner: false,
      theme: temaPrestador(),
      home: TelaProposta(
        empresa: empresa,
        numero: numero,
        logoPadrao: logoPadrao,
        modelos: modelos,
        modeloId: modeloId,
      ),
    );
  }
}
