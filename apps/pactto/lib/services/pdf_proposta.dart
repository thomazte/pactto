import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../core/constants/marca_pix_svg.dart';
import '../models/proposta_pdf.dart';

Future<List<int>> gerarPdfProposta(PropostaPdf proposta) async {
  final regular = pw.Font.ttf(
    await rootBundle.load('assets/fonts/DejaVuSans.ttf'),
  );
  final negrito = pw.Font.ttf(
    await rootBundle.load('assets/fonts/DejaVuSans-Bold.ttf'),
  );
  final doc = pw.Document(
    title: 'Proposta',
    keywords: [
      for (final linha in proposta.linhas) linha.nome,
      proposta.total,
    ].join(' '),
  );
  doc.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.fromLTRB(48, 48, 48, 40),
      theme: pw.ThemeData.withFont(base: regular, bold: negrito),
      build: (context) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.fromLTRB(22, 20, 22, 18),
              color: PdfColor.fromInt(0xFF2563EB),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'PROPOSTA',
                    style: const pw.TextStyle(
                      fontSize: 10,
                      color: PdfColors.white,
                      letterSpacing: 1.4,
                    ),
                  ),
                  pw.SizedBox(height: 6),
                  pw.Text(
                    proposta.empresaNome ?? 'Proposta',
                    style: pw.TextStyle(
                      fontSize: 24,
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
                style: const pw.TextStyle(
                  fontSize: 11,
                  color: PdfColors.grey700,
                ),
              ),
            ],
            pw.SizedBox(height: 2),
            pw.Text(
              'Válida por ${proposta.validadeDias} dias.',
              style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey700),
            ),
            pw.SizedBox(height: 18),
            for (final linha in proposta.linhas) ...[
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
                        pw.SizedBox(height: 2),
                        pw.Text(
                          linha.detalhe,
                          style: const pw.TextStyle(
                            fontSize: 11,
                            color: PdfColors.grey700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  pw.Text(linha.total, style: const pw.TextStyle(fontSize: 13)),
                ],
              ),
              pw.SizedBox(height: 8),
              pw.Container(height: 0.4, color: PdfColors.grey300),
              pw.SizedBox(height: 10),
            ],
            if (proposta.desconto != null) _par('Desconto', proposta.desconto!),
            if (proposta.visita != null) _par('Visita', proposta.visita!),
            pw.SizedBox(height: 8),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'Total',
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.Text(
                  proposta.total,
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        );
      },
    ),
  );
  return doc.save();
}

class PdfPropostaService {
  const PdfPropostaService();

  /// Devolve true quando o PDF foi compartilhado no navegador.
  Future<bool> entregar(Uint8List bytes) async {
    if (kIsWeb) {
      final baixou = await Printing.sharePdf(
        bytes: bytes,
        filename: 'proposta.pdf',
      );
      if (!baixou) throw StateError('pdf');
      return true;
    }
    try {
      await Printing.layoutPdf(
        onLayout: (_) async => bytes,
        name: 'proposta.pdf',
      );
      return false;
    } catch (_) {
      final baixou = await Printing.sharePdf(
        bytes: bytes,
        filename: 'proposta.pdf',
      );
      if (!baixou) rethrow;
      return false;
    }
  }
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
