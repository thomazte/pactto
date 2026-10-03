import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/constants/empresa_padrao.dart';
import '../models/empresa.dart';

/// Logo usado enquanto o prestador não escolhe outro.
Future<Uint8List?> carregarLogoPadrao() async {
  try {
    final dados = await rootBundle.load('assets/logo_padrao.jpg');
    return dados.buffer.asUint8List();
  } catch (_) {
    return null;
  }
}

class EmpresaLocal {
  const EmpresaLocal();

  static const _nome = 'empresa_nome';
  static const _telefone = 'empresa_telefone';
  static const _email = 'empresa_email';
  static const _pix = 'empresa_pix';
  static const _logo = 'empresa_logo';

  /// Campo vazio ou nunca gravado volta ao valor de [empresaPadrao].
  Future<Empresa> carregar() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String ler(String chave, String padrao) {
        final valor = prefs.getString(chave)?.trim() ?? '';
        return valor.isEmpty ? padrao : valor;
      }

      final logo = prefs.getString(_logo);
      return Empresa(
        nome: ler(_nome, empresaPadrao.nome),
        telefone: ler(_telefone, empresaPadrao.telefone),
        email: ler(_email, empresaPadrao.email),
        pix: ler(_pix, empresaPadrao.pix),
        logo: logo == null ? null : base64Decode(logo),
      );
    } catch (_) {
      return empresaPadrao;
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
