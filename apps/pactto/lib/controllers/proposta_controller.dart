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
import '../services/numeracao_local.dart';
import '../services/pdf_proposta.dart';

enum ResultadoPdf { ignorado, gerado, baixado, cancelado, falha }

class PropostaController extends ChangeNotifier {
  PropostaController({
    Empresa empresa = const Empresa(),
    this.numero = 1,
    this.logoPadrao,
    EmpresaLocal? armazenamento,
    NumeracaoLocal? numeracao,
    PdfPropostaService? pdf,
    DateTime Function()? agora,
  }) : _armazenamento = armazenamento ?? const EmpresaLocal(),
       _numeracao = numeracao ?? const NumeracaoLocal(),
       _pdf = pdf ?? const PdfPropostaService(),
       _agora = agora ?? DateTime.now,
       _logoProprio = empresa.logo {
    empresaNome = TextEditingController(text: empresa.nome);
    empresaTelefone = TextEditingController(
      text: formatarTelefone(empresa.telefone),
    );
    empresaEmail = TextEditingController(text: empresa.email);
    empresaPix = TextEditingController(text: empresa.pix);
  }

  static const validadeDias = 7;

  final EmpresaLocal _armazenamento;
  final NumeracaoLocal _numeracao;
  final PdfPropostaService _pdf;
  final DateTime Function() _agora;

  /// Número desta proposta. Avança quando o PDF chega ao cliente.
  int numero;

  /// Logo que vale enquanto a empresa não escolhe outro.
  final Uint8List? logoPadrao;
  Uint8List? _logoProprio;

  Uint8List? get logo => _logoProprio ?? logoPadrao;

  bool get temLogoProprio => _logoProprio != null;

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

  ModalidadeItem modalidade = ModalidadeItem.hora;
  TipoDesconto descontoTipo = TipoDesconto.percentual;
  var mostrarAjustes = false;
  var gerandoPdf = false;

  /// Motivo pelo qual o último item digitado não entrou na lista.
  String? erroItem;
  var _descartado = false;

  String? get nomeEmpresa => _limpo(empresaNome);
  String? get pixEmpresa => _limpo(empresaPix);
  String? get nomeCliente => _limpo(clienteNome);
  String? get contatoCliente => _limpo(clienteWhatsapp);

  String get numeroFormatado => numero.toString().padLeft(4, '0');

  String get emitidaEm => formatarData(dataCivilSaoPaulo(_agora()));

  String get validaAte => formatarData(
    calcularValidoAte(enviadoEm: _agora(), validadeDias: validadeDias),
  );

  List<String> get linhasEmpresa => [
    ?_limpo(empresaTelefone),
    ?_limpo(empresaEmail),
  ];

  ResumoOrcamento get resumo {
    try {
      final itens = [
        for (final linha in linhas)
          if (linha.somaNoOrcamento)
            LinhaOrcamento(
              tipo: linha.tipo,
              quantidadeMilesimos: linha.quantidadeMilesimos,
              valorUnitarioCentavos: linha.valorCentavos,
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

  void definirModalidade(ModalidadeItem nova) {
    if (modalidade == nova) return;
    modalidade = nova;
    quantidade.clear();
    valor.clear();
    erroItem = null;
    _atualizar();
  }

  void adicionar() {
    final valorDigitado = valor.text.trim();
    if (valorDigitado.isEmpty) return;
    final quantidadeDigitada = modalidade.informaQuantidade
        ? (quantidade.text.trim().isEmpty ? '1' : quantidade.text.trim())
        : '1';
    try {
      linhas.add(
        LinhaDigitada.ler(
          modalidade: modalidade,
          descricao: descricao.text.trim(),
          quantidade: quantidadeDigitada,
          valor: valorDigitado,
        ),
      );
    } on ErroDominio catch (erro) {
      erroItem = _mensagem(erro.codigo);
      _atualizar();
      return;
    }
    erroItem = null;
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

  void aoEditarItem() {
    if (erroItem == null) return;
    erroItem = null;
    _atualizar();
  }

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

  static const limiteLogoBytes = 1024 * 1024;

  /// Devolve o motivo da recusa, ou null quando o logo foi aceito.
  String? definirLogo(Uint8List imagem) {
    if (imagem.length > limiteLogoBytes) {
      return 'Escolha uma imagem de até 1 MB.';
    }
    if (!imagemAceitaNoPdf(imagem)) {
      return 'Escolha uma imagem PNG ou JPG.';
    }
    _logoProprio = imagem;
    _armazenamento.salvarLogo(imagem);
    _atualizar();
    return null;
  }

  /// Apaga o logo escolhido e volta ao padrão.
  void usarLogoPadrao() {
    _logoProprio = null;
    _armazenamento.salvarLogo(null);
    _atualizar();
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
      final proposta = PropostaPdf(
        numero: numero,
        emitidaEm: emitidaEm,
        validaAte: validaAte,
        logo: logo,
        linhas: [
          for (final linha in linhas)
            if (linha.somaNoOrcamento)
              LinhaPdf(nome: linha.texto, detalhe: '', total: ''),
        ],
        mensalidades: [
          for (final linha in linhas)
            if (!linha.somaNoOrcamento) linha.texto,
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
      );
      final bytes = Uint8List.fromList(await gerarPdfProposta(proposta));
      final entrega = await _pdf.entregar(bytes, nome: proposta.nomeArquivo);
      resultado = switch (entrega) {
        EntregaPdf.entregue => ResultadoPdf.gerado,
        EntregaPdf.baixado => ResultadoPdf.baixado,
        EntregaPdf.cancelado => ResultadoPdf.cancelado,
      };
      gerou = resultado != ResultadoPdf.cancelado;
    } catch (_) {
      resultado = ResultadoPdf.falha;
    } finally {
      if (gerou) numero++;
      if (!_descartado) {
        gerandoPdf = false;
        if (gerou) _limpar();
        _atualizar();
      }
    }
    if (gerou) await _numeracao.salvar(numero);
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
    erroItem = null;
    modalidade = ModalidadeItem.hora;
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
      'valor_acima_do_limite' => 'Valor alto demais.',
      'preco_negativo' => 'O valor não pode ser negativo.',
      'taxa_negativa' => 'A visita não pode ser negativa.',
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
