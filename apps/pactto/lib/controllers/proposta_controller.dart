import 'dart:typed_data';

import 'package:dominio/dominio.dart';
import 'package:flutter/widgets.dart';

import '../core/formatters/formato_telefone.dart';
import '../models/atalho_item.dart';
import '../models/empresa.dart';
import '../models/linha_digitada.dart';
import '../models/modelo_proposta.dart';
import '../models/proposta_pdf.dart';
import '../models/proposta_salva.dart';
import '../models/resumo_orcamento.dart';
import '../services/empresa_local.dart';
import '../services/modelos_local.dart';
import '../services/numeracao_local.dart';
import '../services/pedido_ia.dart';
import '../services/propostas_local.dart';
import '../services/pdf_proposta.dart';

enum ResultadoPdf { ignorado, gerado, baixado, cancelado, falha }

/// Texto da proposta em edição. Mudar aqui não altera o modelo.
class TextoEditavel {
  TextoEditavel(TextoProposta texto)
    : titulo = TextEditingController(text: texto.titulo),
      corpo = TextEditingController(text: texto.corpo),
      posicao = texto.posicao;

  final TextEditingController titulo;
  final TextEditingController corpo;
  PosicaoTexto posicao;

  TextoProposta get valor => TextoProposta(
    titulo: titulo.text.trim(),
    corpo: corpo.text.trim(),
    posicao: posicao,
  );

  void dispose() {
    titulo.dispose();
    corpo.dispose();
  }
}

class PropostaController extends ChangeNotifier {
  PropostaController({
    Empresa empresa = const Empresa(),
    this.numero = 1,
    this.logoPadrao,
    List<ModeloProposta> modelos = const [],
    String? modeloId,
    List<PropostaSalva> propostas = const [],
    EmpresaLocal? armazenamento,
    NumeracaoLocal? numeracao,
    ModelosLocal? armazenamentoModelos,
    PropostasLocal? armazenamentoPropostas,
    PdfPropostaService? pdf,
    DateTime Function()? agora,
  }) : _armazenamento = armazenamento ?? const EmpresaLocal(),
       _numeracao = numeracao ?? const NumeracaoLocal(),
       _modelosLocal = armazenamentoModelos ?? const ModelosLocal(),
       modelos = List.of(modelos),
       _propostasLocal = armazenamentoPropostas ?? const PropostasLocal(),
       propostas = List.of(propostas),
       _pdf = pdf ?? const PdfPropostaService(),
       _agora = agora ?? DateTime.now,
       _logoProprio = empresa.logo {
    empresaNome = TextEditingController(text: empresa.nome);
    empresaTelefone = TextEditingController(
      text: formatarTelefone(empresa.telefone),
    );
    empresaEmail = TextEditingController(text: empresa.email);
    empresaPix = TextEditingController(text: empresa.pix);
    this.modeloId = _modelo(modeloId)?.id;
    _carregarModelo();
  }

  final EmpresaLocal _armazenamento;
  final NumeracaoLocal _numeracao;
  final ModelosLocal _modelosLocal;
  final PropostasLocal _propostasLocal;
  final PdfPropostaService _pdf;
  final DateTime Function() _agora;

  /// Número da próxima proposta nova. Avança quando o PDF de uma proposta
  /// nova chega ao cliente.
  int numero;

  /// Propostas guardadas no aparelho, a mais recente primeiro.
  final List<PropostaSalva> propostas;

  /// Proposta salva em edição. Null é uma proposta que ainda não foi salva.
  String? propostaId;

  /// Número que a proposta em edição já recebeu num PDF anterior.
  int? numeroProposta;

  /// Proposta reaberta mantém o número; proposta nova usa o próximo.
  int get numeroAtual => numeroProposta ?? numero;

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

  /// CPF ou CNPJ do cliente, para a linha de assinatura do aceite.
  final clienteDocumento = TextEditingController();
  final descricao = TextEditingController();
  final quantidade = TextEditingController();
  final valor = TextEditingController();
  final desconto = TextEditingController();
  final visita = TextEditingController();

  /// O que o cliente precisa, em tópicos soltos, para o pedido à IA.
  final topicosIa = TextEditingController();

  /// Dias de validade desta proposta. Vem do modelo.
  final validade = TextEditingController();
  final linhas = <LinhaDigitada>[];

  final List<ModeloProposta> modelos;

  /// Modelo que preencheu os textos. Null é "sem modelo".
  String? modeloId;
  final textos = <TextoEditavel>[];

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
  String? get documentoCliente => _limpo(clienteDocumento);

  /// Aviso para CPF ou CNPJ com dígito errado. Não impede o PDF.
  String? get erroDocumentoCliente {
    final documento = documentoCliente;
    if (documento == null) return null;
    final digitos = somenteDigitos(documento);
    final valido = digitos.length == 11
        ? cpfValido(digitos)
        : cnpjValido(digitos);
    return valido ? null : 'CPF ou CNPJ inválido.';
  }

  /// O Pix vai como documento da empresa no aceite quando é CPF ou CNPJ.
  String? get documentoEmpresa {
    final pix = pixEmpresa;
    if (pix == null) return null;
    return cpfValido(pix) || cnpjValido(pix) ? pix : null;
  }

  /// Fecha a proposta com validade e assinaturas. Vem do modelo e pode ser
  /// trocado só nesta proposta.
  var incluirAceite = false;

  void alternarAceite(bool incluir) {
    incluirAceite = incluir;
    _atualizar();
  }

  String get numeroFormatado => numeroAtual.toString().padLeft(4, '0');

  String get emitidaEm => formatarData(dataCivilSaoPaulo(_agora()));

  /// Null quando o campo não tem um número de 1 a 365.
  int? get validadeDias {
    final dias = int.tryParse(validade.text.trim());
    return dias != null && dias >= 1 && dias <= 365 ? dias : null;
  }

  String? get erroValidade => validadeDias == null ? 'De 1 a 365 dias.' : null;

  /// Com a validade inválida, a folha mostra a do padrão e o PDF não sai.
  String get validaAte => formatarData(
    calcularValidoAte(
      enviadoEm: _agora(),
      validadeDias: validadeDias ?? ModeloProposta.validadePadrao,
    ),
  );

  bool get temMensalidade => linhas.any((linha) => !linha.somaNoOrcamento);

  /// Proposta só de mensalidade, sem desconto nem visita, fica sem total.
  bool get mostraTotal {
    final totais = resumo.totais;
    if (totais == null) return false;
    return linhas.any((linha) => linha.somaNoOrcamento) ||
        totais.totalCentavos > 0;
  }

  /// Com mensalidade na tabela, o total deixa claro que ela não entra.
  String get rotuloTotal =>
      temMensalidade ? 'Total dos valores únicos' : 'Total';

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

  ModeloProposta? get modeloAtual => _modelo(modeloId);

  /// Troca textos, aceite e validade da proposta pelos do modelo.
  void escolherModelo(String? id) {
    modeloId = _modelo(id)?.id;
    _carregarModelo();
    _modelosLocal.salvarEscolhido(modeloId);
    _atualizar();
  }

  void adicionarTexto() {
    textos.add(TextoEditavel(const TextoProposta(titulo: '', corpo: '')));
    _atualizar();
  }

  void removerTexto(int indice) {
    textos.removeAt(indice).dispose();
    _atualizar();
  }

  void definirPosicao(int indice, PosicaoTexto posicao) {
    textos[indice].posicao = posicao;
    _atualizar();
  }

  /// Grava os textos atuais como modelo. Um nome já usado substitui o
  /// modelo daquele nome. Devolve o motivo da recusa, ou null.
  String? salvarComoModelo(String nome) {
    final limpo = nome.trim();
    if (limpo.isEmpty) return 'Dê um nome ao modelo.';
    final valores = [
      for (final texto in textos)
        if (!texto.valor.vazio) texto.valor,
    ];
    if (valores.isEmpty) return 'Escreva ao menos um texto.';
    final indice = modelos.indexWhere(
      (modelo) => modelo.nome.toLowerCase() == limpo.toLowerCase(),
    );
    final modelo = ModeloProposta(
      id: indice < 0
          ? _agora().microsecondsSinceEpoch.toString()
          : modelos[indice].id,
      nome: limpo,
      textos: valores,
      aceite: incluirAceite,
      validadeDias: validadeDias ?? ModeloProposta.validadePadrao,
    );
    if (indice < 0) {
      modelos.add(modelo);
    } else {
      modelos[indice] = modelo;
    }
    modeloId = modelo.id;
    _modelosLocal.salvar(modelos);
    _modelosLocal.salvarEscolhido(modeloId);
    _atualizar();
    return null;
  }

  /// Apaga o modelo. Os textos já na proposta continuam.
  void excluirModelo(String id) {
    modelos.removeWhere((modelo) => modelo.id == id);
    if (modeloId == id) {
      modeloId = null;
      _modelosLocal.salvarEscolhido(null);
    }
    _modelosLocal.salvar(modelos);
    _atualizar();
  }

  /// Pedido para colar numa IA, com os textos antes dos itens. Null quando
  /// ainda não há tópicos.
  String? pedidoIa() {
    final topicos = topicosIa.text.trim();
    if (topicos.isEmpty) return null;
    return montarPedidoIa(
      topicos: topicos,
      cliente: nomeCliente,
      textos: [
        for (final texto in textos)
          if (texto.posicao == PosicaoTexto.antes && !texto.valor.vazio)
            texto.valor,
      ],
    );
  }

  /// Põe cada texto da resposta no texto de mesmo título, ou cria um novo
  /// antes dos itens. Devolve o motivo da recusa, ou null.
  String? aplicarRespostaIa(String resposta) {
    final lidos = lerRespostaIa(resposta);
    if (lidos.isEmpty) {
      return 'Não encontrei os textos na resposta. Copie a resposta inteira '
          'da IA.';
    }
    for (final lido in lidos) {
      final existente = textos.where(
        (texto) =>
            texto.titulo.text.trim().toLowerCase() == lido.titulo.toLowerCase(),
      );
      if (existente.isNotEmpty) {
        existente.first.corpo.text = lido.corpo;
        continue;
      }
      final depois = textos.indexWhere(
        (texto) => texto.posicao == PosicaoTexto.depois,
      );
      textos.insert(depois < 0 ? textos.length : depois, TextoEditavel(lido));
    }
    _atualizar();
    return null;
  }

  Future<ResultadoPdf> gerarPdf() async {
    final totais = resumo.totais;
    if (totais == null ||
        linhas.isEmpty ||
        validadeDias == null ||
        gerandoPdf) {
      return ResultadoPdf.ignorado;
    }
    gerandoPdf = true;
    _atualizar();
    var gerou = false;
    // Proposta reaberta reaproveita o número que já tem.
    final novaNumeracao = numeroProposta == null;
    var resultado = ResultadoPdf.falha;
    try {
      final proposta = PropostaPdf(
        numero: numeroAtual,
        emitidaEm: emitidaEm,
        validaAte: validaAte,
        logo: logo,
        linhas: [
          for (final linha in linhas)
            LinhaPdf(
              nome: linha.item,
              detalhe: linha.cobranca,
              total: formatarReais(linha.totalCentavos),
            ),
        ],
        total: mostraTotal ? formatarReais(totais.totalCentavos) : null,
        rotuloTotal: rotuloTotal,
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
        clienteDocumento: documentoCliente,
        empresaDocumento: documentoEmpresa,
        aceite: incluirAceite,
        textosAntes: _textosPdf(PosicaoTexto.antes),
        textosDepois: _textosPdf(PosicaoTexto.depois),
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
      if (gerou) {
        // O PDF entregue fica salvo com o número que levou.
        if (!_descartado) _registrar(numeroAtual);
        if (novaNumeracao) numero++;
      }
      if (!_descartado) {
        gerandoPdf = false;
        if (gerou) _limpar();
        _atualizar();
      }
    }
    if (gerou && novaNumeracao) await _numeracao.salvar(numero);
    return resultado;
  }

  /// Guarda a proposta atual. Devolve o motivo da recusa, ou null.
  String? salvarProposta() {
    if (nomeCliente == null && linhas.isEmpty) {
      return 'Preencha o cliente ou um item antes de salvar.';
    }
    _registrar(numeroProposta);
    _atualizar();
    return null;
  }

  /// Troca o que está na tela pela proposta salva.
  void abrirProposta(String id) {
    final salva = propostas.where((proposta) => proposta.id == id).firstOrNull;
    if (salva == null) return;
    _limpar();
    clienteNome.text = salva.clienteNome;
    clienteWhatsapp.text = salva.clienteWhatsapp;
    clienteDocumento.text = salva.clienteDocumento;
    modeloId = _modelo(salva.modeloId)?.id;
    for (final texto in textos) {
      texto.dispose();
    }
    textos
      ..clear()
      ..addAll([for (final texto in salva.textos) TextoEditavel(texto)]);
    incluirAceite = salva.aceite;
    validade.text = '${salva.validadeDias}';
    linhas.addAll(salva.linhas);
    descontoTipo = salva.descontoTipo;
    desconto.text = salva.desconto;
    visita.text = salva.visita;
    mostrarAjustes = salva.desconto.isNotEmpty || salva.visita.isNotEmpty;
    propostaId = salva.id;
    numeroProposta = salva.numero;
    _atualizar();
  }

  /// Limpa a tela para uma proposta nova. A salva continua guardada.
  void novaProposta() {
    _limpar();
    _atualizar();
  }

  /// Apaga a proposta salva. Se era a aberta, o que está na tela fica como
  /// proposta nova.
  void excluirProposta(String id) {
    propostas.removeWhere((proposta) => proposta.id == id);
    if (propostaId == id) {
      propostaId = null;
      numeroProposta = null;
    }
    _propostasLocal.salvar(propostas);
    _atualizar();
  }

  void _registrar(int? numeroDaProposta) {
    final id = propostaId ?? _agora().microsecondsSinceEpoch.toString();
    final salva = PropostaSalva(
      id: id,
      atualizadaEm: _agora(),
      numero: numeroDaProposta,
      clienteNome: clienteNome.text.trim(),
      clienteWhatsapp: clienteWhatsapp.text.trim(),
      clienteDocumento: clienteDocumento.text.trim(),
      modeloId: modeloId,
      textos: [
        for (final texto in textos)
          if (!texto.valor.vazio) texto.valor,
      ],
      aceite: incluirAceite,
      validadeDias: validadeDias ?? ModeloProposta.validadePadrao,
      linhas: List.of(linhas),
      descontoTipo: descontoTipo,
      desconto: desconto.text.trim(),
      visita: visita.text.trim(),
    );
    propostas
      ..removeWhere((proposta) => proposta.id == id)
      ..insert(0, salva);
    propostaId = id;
    numeroProposta = numeroDaProposta;
    _propostasLocal.salvar(propostas);
  }

  void _limpar() {
    clienteNome.clear();
    clienteWhatsapp.clear();
    clienteDocumento.clear();
    descricao.clear();
    quantidade.clear();
    valor.clear();
    desconto.clear();
    visita.clear();
    topicosIa.clear();
    linhas.clear();
    erroItem = null;
    modalidade = ModalidadeItem.hora;
    descontoTipo = TipoDesconto.percentual;
    mostrarAjustes = false;
    propostaId = null;
    numeroProposta = null;
    _carregarModelo();
  }

  ModeloProposta? _modelo(String? id) {
    for (final modelo in modelos) {
      if (modelo.id == id) return modelo;
    }
    return null;
  }

  void _carregarModelo() {
    incluirAceite = modeloAtual?.aceite ?? false;
    validade.text =
        '${modeloAtual?.validadeDias ?? ModeloProposta.validadePadrao}';
    for (final texto in textos) {
      texto.dispose();
    }
    textos
      ..clear()
      ..addAll([
        for (final texto in modeloAtual?.textos ?? const <TextoProposta>[])
          TextoEditavel(texto),
      ]);
  }

  List<TextoPdf> _textosPdf(PosicaoTexto posicao) => [
    for (final texto in textos)
      if (texto.posicao == posicao && !texto.valor.vazio)
        TextoPdf(titulo: texto.valor.titulo, corpo: texto.valor.corpo),
  ];

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
    clienteDocumento.dispose();
    descricao.dispose();
    quantidade.dispose();
    valor.dispose();
    desconto.dispose();
    visita.dispose();
    topicosIa.dispose();
    validade.dispose();
    for (final texto in textos) {
      texto.dispose();
    }
    super.dispose();
  }
}
