import 'dart:typed_data';

class Empresa {
  const Empresa({
    this.nome = '',
    this.telefone = '',
    this.email = '',
    this.pix = '',
    this.logo,
  });

  final String nome;
  final String telefone;
  final String email;
  final String pix;

  /// Imagem PNG ou JPG que vai no cabeçalho da proposta.
  final Uint8List? logo;
}
