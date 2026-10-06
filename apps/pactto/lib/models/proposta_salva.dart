import 'package:dominio/dominio.dart';

import 'linha_digitada.dart';
import 'modelo_proposta.dart';

/// Proposta guardada no aparelho para reabrir, editar e gerar o PDF de novo.
class PropostaSalva {
  const PropostaSalva({
    required this.id,
    required this.atualizadaEm,
    this.numero,
    this.clienteNome = '',
    this.clienteWhatsapp = '',
    this.clienteDocumento = '',
    this.modeloId,
    this.textos = const [],
    this.aceite = false,
    this.validadeDias = ModeloProposta.validadePadrao,
    this.linhas = const [],
    this.descontoTipo = TipoDesconto.percentual,
    this.desconto = '',
    this.visita = '',
  });

  factory PropostaSalva.deJson(Map<String, dynamic> json) {
    return PropostaSalva(
      id: json['id'] as String,
      atualizadaEm: DateTime.parse(json['atualizadaEm'] as String),
      numero: json['numero'] as int?,
      clienteNome: json['clienteNome'] as String? ?? '',
      clienteWhatsapp: json['clienteWhatsapp'] as String? ?? '',
      clienteDocumento: json['clienteDocumento'] as String? ?? '',
      modeloId: json['modeloId'] as String?,
      textos: [
        for (final texto in json['textos'] as List? ?? const [])
          TextoProposta.deJson(Map<String, dynamic>.from(texto as Map)),
      ],
      aceite: json['aceite'] == true,
      validadeDias:
          json['validadeDias'] as int? ?? ModeloProposta.validadePadrao,
      linhas: [
        for (final linha in json['linhas'] as List? ?? const [])
          LinhaDigitada.deJson(Map<String, dynamic>.from(linha as Map)),
      ],
      descontoTipo: json['descontoTipo'] == TipoDesconto.fixo.name
          ? TipoDesconto.fixo
          : TipoDesconto.percentual,
      desconto: json['desconto'] as String? ?? '',
      visita: json['visita'] as String? ?? '',
    );
  }

  final String id;
  final DateTime atualizadaEm;

  /// Número recebido no primeiro PDF. Null enquanto é só rascunho.
  final int? numero;

  final String clienteNome;
  final String clienteWhatsapp;
  final String clienteDocumento;

  /// Modelo escolhido quando a proposta foi salva, só para o seletor.
  final String? modeloId;
  final List<TextoProposta> textos;
  final bool aceite;
  final int validadeDias;
  final List<LinhaDigitada> linhas;
  final TipoDesconto descontoTipo;

  /// Desconto e visita como foram digitados.
  final String desconto;
  final String visita;

  Map<String, dynamic> paraJson() => {
    'id': id,
    'atualizadaEm': atualizadaEm.toUtc().toIso8601String(),
    'numero': numero,
    'clienteNome': clienteNome,
    'clienteWhatsapp': clienteWhatsapp,
    'clienteDocumento': clienteDocumento,
    'modeloId': modeloId,
    'textos': [for (final texto in textos) texto.paraJson()],
    'aceite': aceite,
    'validadeDias': validadeDias,
    'linhas': [for (final linha in linhas) linha.paraJson()],
    'descontoTipo': descontoTipo.name,
    'desconto': desconto,
    'visita': visita,
  };
}
