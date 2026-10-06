import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../core/constants/marca_pix_svg.dart';
import '../models/linha_texto.dart';
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
      ?proposta.total,
      for (final texto in [...proposta.textosAntes, ...proposta.textosDepois])
        texto.titulo,
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
                pw.SizedBox(
                  width: ladoLogo,
                  height: ladoLogo,
                  child: pw.ClipRRect(
                    horizontalRadius: 8,
                    verticalRadius: 8,
                    child: pw.Image(logo, fit: pw.BoxFit.cover),
                  ),
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
        for (final texto in proposta.textosAntes) ..._texto(texto),
        ..._investimento(proposta),
        pw.SizedBox(height: 10),
        if (proposta.desconto != null) _par('Desconto', proposta.desconto!),
        if (proposta.visita != null) _par('Visita', proposta.visita!),
        if (proposta.total != null) ...[
          pw.SizedBox(height: 8),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                proposta.rotuloTotal,
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Text(
                proposta.total!,
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
        if (proposta.textosDepois.isNotEmpty) pw.SizedBox(height: 18),
        for (final texto in proposta.textosDepois) ..._texto(texto),
        if (proposta.aceite) _aceite(proposta),
      ],
    ),
  );
  return doc;
}

/// Uma linha por widget, para o texto longo poder passar de página.
List<pw.Widget> _texto(TextoPdf texto) {
  const estilo = pw.TextStyle(fontSize: 11, color: PdfColors.grey800);
  final negrito = estilo.copyWith(fontWeight: pw.FontWeight.bold);
  pw.Widget conteudo(LinhaTexto linha) => pw.RichText(
    text: pw.TextSpan(
      style: estilo,
      children: [
        if (linha.rotulo != null)
          pw.TextSpan(text: linha.rotulo, style: negrito),
        pw.TextSpan(text: linha.resto),
      ],
    ),
  );
  pw.Widget linha(LinhaTexto linha) => pw.Padding(
    padding: const pw.EdgeInsets.only(bottom: 4),
    child: linha.topico
        ? pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.SizedBox(width: 14, child: pw.Text('•', style: estilo)),
              pw.Expanded(child: conteudo(linha)),
            ],
          )
        : conteudo(linha),
  );
  final linhas = lerCorpo(texto.corpo);
  return [
    // O título desce junto com a primeira linha, para não ficar sozinho no
    // pé da página.
    if (texto.titulo.isNotEmpty)
      pw.Inseparable(
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              texto.titulo,
              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 6),
            if (linhas.isNotEmpty) linha(linhas.first),
          ],
        ),
      ),
    for (final item in texto.titulo.isEmpty ? linhas : linhas.skip(1))
      linha(item),
    pw.SizedBox(height: 14),
  ];
}

/// Itens da proposta. Com textos antes, ganham o título "Investimento". Uma
/// tabela curta desce inteira, com o título, para a página seguinte quando
/// não cabe; uma longa pode continuar de uma página para outra.
List<pw.Widget> _investimento(PropostaPdf proposta) {
  final tabela = _tabela(const ['Item', 'Cobrança', 'Valor'], const [5, 2, 2], [
    for (final linha in proposta.linhas)
      [linha.nome, linha.detalhe, linha.total],
  ]);
  final titulo = [
    if (proposta.textosAntes.isNotEmpty) ...[
      pw.Text(
        'Investimento',
        style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
      ),
      pw.SizedBox(height: 10),
    ],
  ];
  if (proposta.linhas.length > 15) return [...titulo, tabela];
  return [
    pw.Inseparable(
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [...titulo, tabela],
      ),
    ),
  ];
}

/// Tabela com cabeçalho em negrito e um traço sob cada linha. A última
/// coluna é o valor, alinhado à direita. Linhas que não cabem continuam na
/// página seguinte.
pw.Widget _tabela(
  List<String> cabecalho,
  List<int> pesos,
  List<List<String>> linhas,
) {
  pw.TableRow linha(List<String> celulas, {required bool topo}) {
    return pw.TableRow(
      decoration: pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(
            color: topo ? PdfColors.grey500 : PdfColors.grey300,
            width: topo ? 0.8 : 0.4,
          ),
        ),
      ),
      children: [
        for (var i = 0; i < celulas.length; i++)
          pw.Padding(
            padding: pw.EdgeInsets.fromLTRB(
              i == 0 ? 0 : 6,
              6,
              i == celulas.length - 1 ? 0 : 6,
              6,
            ),
            child: pw.Text(
              celulas[i],
              textAlign: i == celulas.length - 1
                  ? pw.TextAlign.right
                  : pw.TextAlign.left,
              style: pw.TextStyle(
                fontSize: topo ? 10 : 11,
                fontWeight: topo ? pw.FontWeight.bold : null,
                color: topo ? PdfColors.grey700 : PdfColors.grey900,
              ),
            ),
          ),
      ],
    );
  }

  return pw.Table(
    columnWidths: {
      for (var i = 0; i < pesos.length; i++)
        i: pw.FlexColumnWidth(pesos[i].toDouble()),
    },
    children: [
      linha(cabecalho, topo: true),
      for (final celulas in linhas) linha(celulas, topo: false),
    ],
  );
}

/// Validade, "De acordo" e as duas assinaturas, num bloco só para não
/// separar as linhas entre páginas.
pw.Widget _aceite(PropostaPdf proposta) {
  const estilo = pw.TextStyle(fontSize: 11, color: PdfColors.grey800);
  pw.Widget assinatura(String papel, String nome, String? documento) {
    return pw.Expanded(
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(height: 0.6, color: PdfColors.grey600),
          pw.SizedBox(height: 4),
          pw.Text(
            nome,
            style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
          ),
          pw.Text(rotuloDocumento(documento), style: estilo),
          pw.Text(
            papel,
            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
          ),
        ],
      ),
    );
  }

  return pw.Inseparable(
    child: pw.Padding(
      padding: const pw.EdgeInsets.only(top: 6),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Aceite',
            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 6),
          pw.Text(
            'Esta proposta é válida até ${proposta.validaAte}.',
            style: estilo,
          ),
          pw.SizedBox(height: 4),
          pw.Text('De acordo,', style: estilo),
          pw.SizedBox(height: 44),
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              assinatura(
                'Cliente',
                proposta.clienteNome ?? 'Cliente',
                proposta.clienteDocumento,
              ),
              pw.SizedBox(width: 28),
              assinatura(
                'Prestador',
                proposta.empresaNome ?? 'Prestador',
                proposta.empresaDocumento,
              ),
            ],
          ),
          pw.SizedBox(height: 22),
          pw.Text('Data: ____/____/________', style: estilo),
        ],
      ),
    ),
  );
}

/// "CPF: …" ou "CNPJ: …" pelo número de dígitos; sem documento, um espaço
/// para preencher à mão.
String rotuloDocumento(String? documento) {
  if (documento == null) return 'CPF/CNPJ: ____________________';
  final digitos = documento.replaceAll(RegExp(r'\D'), '');
  return '${digitos.length == 11 ? 'CPF' : 'CNPJ'}: $documento';
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
