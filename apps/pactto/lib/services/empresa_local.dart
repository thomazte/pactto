import 'dart:convert';
import 'dart:typed_data';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/empresa.dart';

class EmpresaLocal {
  const EmpresaLocal();

  static const _nome = 'empresa_nome';
  static const _telefone = 'empresa_telefone';
  static const _email = 'empresa_email';
  static const _pix = 'empresa_pix';
  static const _logo = 'empresa_logo';

  Future<Empresa> carregar() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final logo = prefs.getString(_logo);
      return Empresa(
        nome: prefs.getString(_nome) ?? '',
        telefone: prefs.getString(_telefone) ?? '',
        email: prefs.getString(_email) ?? '',
        pix: prefs.getString(_pix) ?? '',
        logo: logo == null ? null : base64Decode(logo),
      );
    } catch (_) {
      return const Empresa();
    }
  }

  /// Grava os textos. O logo tem gravação própria, para não reescrever a
  /// imagem a cada tecla.
  Future<void> salvar(Empresa empresa) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_nome, empresa.nome);
      await prefs.setString(_telefone, empresa.telefone);
      await prefs.setString(_email, empresa.email);
      await prefs.setString(_pix, empresa.pix);
    } catch (_) {}
  }

  Future<void> salvarLogo(Uint8List? logo) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (logo == null) {
        await prefs.remove(_logo);
      } else {
        await prefs.setString(_logo, base64Encode(logo));
      }
    } catch (_) {}
  }
}
