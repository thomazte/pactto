import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/proposta_salva.dart';

/// Propostas salvas no aparelho, a mais recente primeiro.
class PropostasLocal {
  const PropostasLocal();

  static const chave = 'propostas_salvas';

  Future<List<PropostaSalva>> carregar() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final gravadas = prefs.getString(chave);
      if (gravadas == null) return [];
      return [
        for (final item in jsonDecode(gravadas) as List)
          PropostaSalva.deJson(Map<String, dynamic>.from(item as Map)),
      ];
    } catch (_) {
      return [];
    }
  }

  Future<void> salvar(List<PropostaSalva> propostas) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        chave,
        jsonEncode([for (final proposta in propostas) proposta.paraJson()]),
      );
    } catch (_) {}
  }
}
