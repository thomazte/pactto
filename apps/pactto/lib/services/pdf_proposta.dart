import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../core/constants/marca_pix_svg.dart';
import '../models/proposta_pdf.dart';

Future<List<int>> gerarPdfProposta(PropostaPdf proposta) async {
  final doc = await montarPdfProposta(proposta);
  return doc.save();
}

/// Monta o documento sem salvar, para o teste contar as páginas.
Future<pw.Document> montarPdfProposta(PropostaPdf proposta) async {
  final bytesRegular = await rootBundle.load('assets/fonts/DejaVuSans.ttf');
  final bytesNegrito = await rootBundle.load(
    'assets/fonts/DejaVuSans-Bold.ttf',
  );
  final regular = pw.Font.ttf(bytesRegular);
  final negrito = pw.Font.ttf(bytesNegrito);
  final logo = proposta.logo == null ? null : pw.MemoryImage(proposta.logo!);
  final nomeEmpresa = proposta.empresaNome ?? 'Proposta';
  final titulo = medidaTituloEmpresa(
    nomeEmpresa,
    bytesNegrito,
    comLogo: logo != null,
  );
  final doc = pw.Document(
    title: 'Proposta ${proposta.numeroFormatado}',
    keywords: [
      for (final linha in proposta.linhas) linha.nome,
      ...proposta.mensalidades,
      proposta.total,
    ].join(' '),
  );
  doc.addPage(
    pw.MultiPage(
      pageTheme: pw.PageTheme(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(48, 48, 48, 40),
        theme: pw.ThemeData.withFont(base: regular, bold: negrito),
      ),
      footer: (context) {
        if (context.pagesCount < 2) return pw.SizedBox();
        return pw.Container(
          alignment: pw.Alignment.centerRight,
          margin: const pw.EdgeInsets.only(top: 12),
          child: pw.Text(
            'Proposta ${proposta.numeroFormatado} · '
            'página ${context.pageNumber} de ${context.pagesCount}',
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
          ),
        );
      },
      build: (context) => [
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.fromLTRB(22, 20, 22, 18),
          color: PdfColor.fromInt(0xFF2563EB),
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'PROPOSTA Nº ${proposta.numeroFormatado}',
                      style: const pw.TextStyle(
                        fontSize: 10,
                        color: PdfColors.white,
                        letterSpacing: 1.4,
                      ),
                    ),
                    pw.SizedBox(height: 6),
                    pw.Text(
                      nomeEmpresa,
                      maxLines: titulo.linhas,
                      style: pw.TextStyle(
                        fontSize: titulo.tamanho,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.white,
                      ),
                    ),
                    for (final linha in proposta.empresaLinhas) ...[
                      pw.SizedBox(height: 2),
                      pw.Text(
                        linha,
                        style: const pw.TextStyle(
                          fontSize: 11,
                          color: PdfColors.white,
                        ),
                      ),
                    ],
                    if (proposta.empresaPix != null) ...[
                      pw.SizedBox(height: 4),
                      pw.Row(
                        children: [
                          pw.SvgImage(
                            svg: svgMarcaPix,
                            width: 11,
                            height: 11,
                            colorFilter: PdfColors.white,
                          ),
                          pw.SizedBox(width: 5),
                          pw.Text(
                            proposta.empresaPix!,
                            style: const pw.TextStyle(
                              fontSize: 11,
                              color: PdfColors.white,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              if (logo != null) ...[
                pw.SizedBox(width: espacoLogo),
                pw.Container(
                  width: ladoLogo,
                  height: ladoLogo,
                  padding: const pw.EdgeInsets.all(6),
                  decoration: const pw.BoxDecoration(
                    color: PdfColors.white,
                    borderRadius: pw.BorderRadius.all(pw.Radius.circular(8)),
                  ),
                  child: pw.Image(logo, fit: pw.BoxFit.contain),
                ),
              ],
            ],
          ),
        ),
        pw.SizedBox(height: 18),
        pw.Text(
          proposta.clienteNome == null
              ? 'Para o cliente'
              : 'Para ${proposta.clienteNome}',
          style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
        ),
        if (proposta.clienteContato != null) ...[
          pw.SizedBox(height: 2),
          pw.Text(
            proposta.clienteContato!,
            style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey700),
          ),
        ],
        pw.SizedBox(height: 2),
        pw.Text(
          'Emitida em ${proposta.emitidaEm}. '
          'Válida até ${proposta.validaAte}.',
          style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey700),
        ),
        pw.SizedBox(height: 18),
        for (final linha in proposta.linhas) _linha(linha),
        if (proposta.desconto != null) _par('Desconto', proposta.desconto!),
        if (proposta.visita != null) _par('Visita', proposta.visita!),
        pw.SizedBox(height: 8),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'Total',
              style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
            ),
            pw.Text(
              proposta.total,
              style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
            ),
          ],
        ),
        if (proposta.mensalidades.isNotEmpty) ...[
          pw.SizedBox(height: 18),
          pw.Container(height: 0.4, color: PdfColors.grey300),
          pw.SizedBox(height: 12),
          for (final texto in proposta.mensalidades)
            pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 6),
              child: pw.Text(
                texto,
                style: const pw.TextStyle(
                  fontSize: 12,
                  color: PdfColors.grey800,
                ),
              ),
            ),
        ],
      ],
    ),
  );
  return doc;
}

/// Cada linha é um bloco só, para a quebra de página não separar o texto
/// do traço que o fecha.
pw.Widget _linha(LinhaPdf linha) {
  return pw.Padding(
    padding: const pw.EdgeInsets.only(bottom: 10),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    linha.nome,
                    style: pw.TextStyle(
                      fontSize: 13,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  if (linha.detalhe.isNotEmpty) ...[
                    pw.SizedBox(height: 2),
                    pw.Text(
                      linha.detalhe,
                      style: const pw.TextStyle(
                        fontSize: 11,
                        color: PdfColors.grey700,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (linha.total.isNotEmpty)
              pw.Text(linha.total, style: const pw.TextStyle(fontSize: 13)),
          ],
        ),
        pw.SizedBox(height: 8),
        pw.Container(height: 0.4, color: PdfColors.grey300),
      ],
    ),
  );
}

/// Verdadeira quando o PDF consegue desenhar a imagem.
bool imagemAceitaNoPdf(Uint8List bytes) {
  try {
    pw.MemoryImage(bytes);
    return true;
  } catch (_) {
    return false;
  }
}

enum EntregaPdf {
  /// Impresso ou compartilhado no celular.
  entregue,

  /// Baixado no navegador.
  baixado,

  /// O prestador fechou a impressão ou o compartilhamento sem concluir.
  cancelado,
}

class PdfPropostaService {
  const PdfPropostaService();

  Future<EntregaPdf> entregar(Uint8List bytes, {required String nome}) async {
    if (kIsWeb) {
      final baixou = await Printing.sharePdf(bytes: bytes, filename: nome);
      return baixou ? EntregaPdf.baixado : EntregaPdf.cancelado;
    }
    bool imprimiu;
    try {
      imprimiu = await Printing.layoutPdf(
        onLayout: (_) async => bytes,
        name: nome,
      );
    } catch (_) {
      final compartilhou = await Printing.sharePdf(
        bytes: bytes,
        filename: nome,
      );
      return compartilhou ? EntregaPdf.entregue : EntregaPdf.cancelado;
    }
    return imprimiu ? EntregaPdf.entregue : EntregaPdf.cancelado;
  }
}

const tamanhoBaseTituloEmpresa = 24.0;
const tamanhoMinimoTituloEmpresa = 13.0;

const ladoLogo = 64.0;
const espacoLogo = 16.0;

/// Largura útil do nome no cabeçalho azul, já sem margem, padding e logo.
double larguraTituloEmpresa({bool comLogo = false}) {
  final largura = PdfPageFormat.a4.width - 48 * 2 - 22 * 2;
  return comLogo ? largura - ladoLogo - espacoLogo : largura;
}

/// Nome curto permanece em 24 pt. Nome longo encolhe para caber numa linha.
({double tamanho, int linhas}) medidaTituloEmpresa(
  String nome,
  ByteData fonteNegrito, {
  bool comLogo = false,
}) {
  final em = _larguraEm(TtfParser(fonteNegrito), nome);
  final largura = larguraTituloEmpresa(comLogo: comLogo) - 2;
  if (em <= 0 || largura / em >= tamanhoBaseTituloEmpresa) {
    return (tamanho: tamanhoBaseTituloEmpresa, linhas: 1);
  }
  final ideal = largura / em;
  if (ideal >= tamanhoMinimoTituloEmpresa) {
    return (tamanho: ideal, linhas: 1);
  }
  return (tamanho: tamanhoMinimoTituloEmpresa, linhas: 2);
}

double _larguraEm(TtfParser fonte, String texto) {
  var largura = 0.0;
  for (final rune in texto.runes) {
    final indice = fonte.charToGlyphIndexMap[rune];
    if (indice == null) continue;
    largura += fonte.glyphInfoMap[indice]?.advanceWidth ?? 0;
  }
  return largura;
}

pw.Widget _par(String rotulo, String valor) {
  return pw.Padding(
    padding: const pw.EdgeInsets.only(bottom: 4),
    child: pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(
          rotulo,
          style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey800),
        ),
        pw.Text(valor, style: const pw.TextStyle(fontSize: 12)),
      ],
    ),
  );
}
