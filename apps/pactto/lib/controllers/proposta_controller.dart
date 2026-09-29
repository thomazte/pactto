import 'dart:typed_data';

import 'package:dominio/dominio.dart';
import 'package:flutter/widgets.dart';

import '../core/formatters/formato_telefone.dart';
import '../models/atalho_item.dart';
import '../models/empresa.dart';
import '../models/linha_digitada.dart';
import '../models/proposta_pdf.dart';
import '../models/resumo_orcamento.dart';
import '../services/empresa_local.dart';
import '../services/pdf_proposta.dart';

enum ResultadoPdf { ignorado, gerado, baixado, falha }

class PropostaController extends ChangeNotifier {
  PropostaController({
    Empresa empresa = const Empresa(),
    EmpresaLocal? armazenamento,
    PdfPropostaService? pdf,
  }) : _armazenamento = armazenamento ?? const EmpresaLocal(),
       _pdf = pdf ?? const PdfPropostaService() {
    empresaNome = TextEditingController(text: empresa.nome);
    empresaTelefone = TextEditingController(
      text: formatarTelefone(empresa.telefone),
    );
    empresaEmail = TextEditingController(text: empresa.email);
    empresaPix = TextEditingController(text: empresa.pix);
  }

  final EmpresaLocal _armazenamento;
  final PdfPropostaService _pdf;

  late final TextEditingController empresaNome;
  late final TextEditingController empresaTelefone;
  late final TextEditingController empresaEmail;
  late final TextEditingController empresaPix;
  final clienteNome = TextEditingController();
  final clienteWhatsapp = TextEditingController();
  final descricao = TextEditingController();
  final quantidade = TextEditingController();
  final valor = TextEditingController();
  final desconto = TextEditingController();
  final visita = TextEditingController();
  final linhas = <LinhaDigitada>[];

  TipoItem tipo = TipoItem.maoDeObra;
  TipoDesconto descontoTipo = TipoDesconto.percentual;
  var mostrarAjustes = false;
  var gerandoPdf = false;
  var _descartado = false;

  String? get nomeEmpresa => _limpo(empresaNome);
  String? get pixEmpresa => _limpo(empresaPix);
  String? get nomeCliente => _limpo(clienteNome);
  String? get contatoCliente => _limpo(clienteWhatsapp);

  List<String> get linhasEmpresa => [
    ?_limpo(empresaTelefone),
    ?_limpo(empresaEmail),
  ];

  ResumoOrcamento get resumo {
    try {
      final itens = [
        for (final linha in linhas)
          LinhaOrcamento(
            tipo: linha.tipo,
            quantidadeMilesimos: parseQuantidadeMilesimos(linha.quantidade),
            valorUnitarioCentavos: parseReaisCentavos(linha.valor),
          ),
      ];
      final descontoTexto = desconto.text.trim();
      final visitaTexto = visita.text.trim();
      final temDesconto = descontoTexto.isNotEmpty && descontoTexto != '0';
      final totais = calcularOrcamento(
        linhas: itens,
        descontoTipo: temDesconto ? descontoTipo : TipoDesconto.nenhum,
        descontoFixoCentavos: temDesconto && descontoTipo == TipoDesconto.fixo
            ? parseReaisCentavos(descontoTexto)
            : null,
        descontoPercentualBps:
            temDesconto && descontoTipo == TipoDesconto.percentual
            ? parseReaisCentavos(descontoTexto)
            : null,
        taxaDeslocamentoCentavos: visitaTexto.isEmpty
            ? 0
            : parseReaisCentavos(visitaTexto),
      );
      return ResumoOrcamento.ok(totais);
    } on ErroDominio catch (erro) {
      return ResumoOrcamento.falha(_mensagem(erro.codigo));
    }
  }

  void aplicarAtalho(AtalhoItem atalho) {
    tipo = atalho.tipo;
    descricao.text = atalho.rotulo;
    _atualizar();
  }

  void adicionar() {
    final valorDigitado = valor.text.trim();
    if (valorDigitado.isEmpty) return;
    final quantidadeDigitada = quantidade.text.trim().isEmpty
        ? '1'
        : quantidade.text.trim();
    linhas.add(
      LinhaDigitada(
        tipo: tipo,
        descricao: descricao.text.trim(),
        quantidade: quantidadeDigitada,
        valor: valorDigitado,
      ),
    );
    descricao.clear();
    quantidade.clear();
    valor.clear();
    _atualizar();
  }

  void remover(int indice) {
    linhas.removeAt(indice);
    _atualizar();
  }

  void alternarAjustes() {
    mostrarAjustes = !mostrarAjustes;
    _atualizar();
  }

  void definirTipoDesconto(TipoDesconto tipoDesconto) {
    descontoTipo = tipoDesconto;
    _atualizar();
  }

  void notificar() => _atualizar();

  void aoEditarEmpresa() {
    _atualizar();
    _armazenamento.salvar(
      Empresa(
        nome: empresaNome.text,
        telefone: empresaTelefone.text,
        email: empresaEmail.text,
        pix: empresaPix.text,
      ),
    );
  }

  Future<ResultadoPdf> gerarPdf() async {
    final totais = resumo.totais;
    if (totais == null || linhas.isEmpty || gerandoPdf) {
      return ResultadoPdf.ignorado;
    }
    gerandoPdf = true;
    _atualizar();
    var gerou = false;
    var resultado = ResultadoPdf.falha;
    try {
      final bytes = Uint8List.fromList(
        await gerarPdfProposta(
          PropostaPdf(
            linhas: [
              for (final linha in linhas)
                LinhaPdf(
                  nome: linha.nome,
                  detalhe: linha.detalhe,
                  total: formatarReais(linha.totalCentavos),
                ),
            ],
            total: formatarReais(totais.totalCentavos),
            desconto: totais.descontoCentavos == 0
                ? null
                : formatarReais(totais.descontoCentavos),
            visita: totais.taxaDeslocamentoCentavos == 0
                ? null
                : formatarReais(totais.taxaDeslocamentoCentavos),
            empresaNome: nomeEmpresa,
            empresaLinhas: linhasEmpresa,
            empresaPix: pixEmpresa,
            clienteNome: nomeCliente,
            clienteContato: contatoCliente,
          ),
        ),
      );
      final baixadoNaWeb = await _pdf.entregar(bytes);
      gerou = true;
      resultado = baixadoNaWeb ? ResultadoPdf.baixado : ResultadoPdf.gerado;
    } catch (_) {
      resultado = ResultadoPdf.falha;
    } finally {
      if (!_descartado) {
        gerandoPdf = false;
        if (gerou) _limpar();
        _atualizar();
      }
    }
    return resultado;
  }

  void _limpar() {
    clienteNome.clear();
    clienteWhatsapp.clear();
    descricao.clear();
    quantidade.clear();
    valor.clear();
    desconto.clear();
    visita.clear();
    linhas.clear();
    tipo = TipoItem.maoDeObra;
    descontoTipo = TipoDesconto.percentual;
    mostrarAjustes = false;
  }

  String? _limpo(TextEditingController controle) {
    final texto = controle.text.trim();
    return texto.isEmpty ? null : texto;
  }

  String _mensagem(String codigo) {
    return switch (codigo) {
      'desconto_acima_da_base' => 'O desconto passa do valor dos itens.',
      'desconto_percentual_invalido' => 'O desconto vai de 0 a 100%.',
      'quantidade_invalida' => 'Quantidade inválida. Exemplo: 2,5.',
      'moeda_invalida' => 'Valor inválido. Exemplo: 180,00.',
      _ => 'Confira os valores para continuar.',
    };
  }

  void _atualizar() {
    if (!_descartado) notifyListeners();
  }

  @override
  void dispose() {
    _descartado = true;
    empresaNome.dispose();
    empresaTelefone.dispose();
    empresaEmail.dispose();
    empresaPix.dispose();
    clienteNome.dispose();
    clienteWhatsapp.dispose();
    descricao.dispose();
    quantidade.dispose();
    valor.dispose();
    desconto.dispose();
    visita.dispose();
    super.dispose();
  }
}
