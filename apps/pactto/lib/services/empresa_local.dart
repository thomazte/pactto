import 'package:shared_preferences/shared_preferences.dart';

import '../models/empresa.dart';

class EmpresaLocal {
  const EmpresaLocal();

  static const _nome = 'empresa_nome';
  static const _telefone = 'empresa_telefone';
  static const _email = 'empresa_email';
  static const _pix = 'empresa_pix';

  Future<Empresa> carregar() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return Empresa(
        nome: prefs.getString(_nome) ?? '',
        telefone: prefs.getString(_telefone) ?? '',
        email: prefs.getString(_email) ?? '',
        pix: prefs.getString(_pix) ?? '',
      );
    } catch (_) {
      return const Empresa();
    }
  }

  Future<void> salvar(Empresa empresa) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_nome, empresa.nome);
      await prefs.setString(_telefone, empresa.telefone);
      await prefs.setString(_email, empresa.email);
      await prefs.setString(_pix, empresa.pix);
    } catch (_) {}
  }
}
