import 'package:shared_preferences/shared_preferences.dart';

/// Número da próxima proposta, gravado no aparelho.
class NumeracaoLocal {
  const NumeracaoLocal();

  static const _proximo = 'proposta_proximo_numero';

  Future<int> carregar() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt(_proximo) ?? 1;
    } catch (_) {
      return 1;
    }
  }

  Future<void> salvar(int proximo) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_proximo, proximo);
    } catch (_) {}
  }
}
