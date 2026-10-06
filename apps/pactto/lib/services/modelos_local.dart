import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../core/constants/modelos_padrao.dart';
import '../models/modelo_proposta.dart';

/// Modelos gravados no aparelho e o último escolhido.
class ModelosLocal {
  const ModelosLocal();

  static const _modelos = 'modelos_proposta';
  static const _escolhido = 'modelo_escolhido';

  /// Sem nada gravado, valem os [modelosPadrao]. Uma lista gravada vazia
  /// continua vazia: o prestador apagou os modelos de propósito.
  Future<({List<ModeloProposta> modelos, String? escolhido})> carregar() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final gravados = prefs.getString(_modelos);
      final modelos = gravados == null
          ? modelosPadrao
          : [
              for (final item in jsonDecode(gravados) as List)
                ModeloProposta.deJson(Map<String, dynamic>.from(item as Map)),
            ];
      final escolhido = prefs.containsKey(_escolhido)
          ? prefs.getString(_escolhido)
          : modelos.firstOrNull?.id;
      return (modelos: modelos, escolhido: escolhido);
    } catch (_) {
      return (modelos: modelosPadrao, escolhido: modelosPadrao.first.id);
    }
  }

  Future<void> salvar(List<ModeloProposta> modelos) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _modelos,
        jsonEncode([for (final modelo in modelos) modelo.paraJson()]),
      );
    } catch (_) {}
  }

  /// Grava o modelo escolhido. Null é "sem modelo".
  Future<void> salvarEscolhido(String? id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (id == null) {
        await prefs.setString(_escolhido, '');
      } else {
        await prefs.setString(_escolhido, id);
      }
    } catch (_) {}
  }
}
