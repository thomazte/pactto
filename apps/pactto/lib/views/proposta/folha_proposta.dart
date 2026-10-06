import 'package:dominio/dominio.dart';
import 'package:flutter/material.dart';

import '../../controllers/proposta_controller.dart';
import '../../models/linha_texto.dart';
import '../../models/modelo_proposta.dart';
import '../../core/theme/tema.dart';
import '../../core/widgets/marca_pix.dart';

class FolhaProposta extends StatelessWidget {
  const FolhaProposta({
    super.key,
    required this.controller,
    required this.onPdf,
  });

  final PropostaController controller;
  final VoidCallback onPdf;

  @override
  Widget build(BuildContext context) {
    final linhas = controller.linhas;
    final resumo = controller.resumo;
    final totais = resumo.totais;
    final empresaNome = controller.nomeEmpresa;
    final empresaLinhas = controller.linhasEmpresa;
    final empresaPix = controller.pixEmpresa;
    final clienteNome = controller.nomeCliente;
    final clienteContato = controller.contatoCliente;
    final logo = controller.logo;
    List<TextoProposta> textos(PosicaoTexto posicao) => [
      for (final texto in controller.textos)
        if (texto.posicao == posicao && !texto.valor.vazio) texto.valor,
    ];
    final antes = textos(PosicaoTexto.antes);
    final depois = textos(PosicaoTexto.depois);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Cores.papel,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0x14000000)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 28,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ColoredBox(
              color: Cores.azul,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(28, 22, 28, 20),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'PROPOSTA Nº ${controller.numeroFormatado}',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.5,
                            ),
                          ),
                          const SizedBox(height: 6),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              empresaNome ?? 'Sua empresa',
                              maxLines: 1,
                              softWrap: false,
                              style: TextStyle(
                                color: empresaNome == null
                                    ? Colors.white.withValues(alpha: 0.65)
                                    : Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.4,
                              ),
                            ),
                          ),
                          if (empresaLinhas.isNotEmpty || empresaPix != null)
                            const SizedBox(height: 6),
                          for (final linha in empresaLinhas)
                            Text(
                              linha,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                height: 1.35,
                              ),
                            ),
                          if (empresaPix != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Row(
                                children: [
                                  const MarcaPix(
                                    tamanho: 14,
                                    cor: Colors.white,
                                  ),
                                  const SizedBox(width: 6),
                                  Flexible(
                                    child: Text(
                                      empresaPix,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 13,
                                        height: 1.35,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (logo != null) ...[
                      const SizedBox(width: 16),
                      ClipRRect(
                        key: const Key('logo_folha'),
                        borderRadius: BorderRadius.circular(10),
                        child: Image.memory(
                          logo,
                          width: 56,
                          height: 56,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 22, 28, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    clienteNome == null
                        ? 'Para o cliente'
                        : 'Para $clienteNome',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (clienteContato != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      clienteContato,
                      style: const TextStyle(color: Cores.suave),
                    ),
                  ],
                  const SizedBox(height: 2),
                  Text(
                    'Emitida em ${controller.emitidaEm}. '
                    'Válida até ${controller.validaAte}.',
                    key: const Key('datas'),
                    style: const TextStyle(color: Cores.suave, fontSize: 13),
                  ),
                  const SizedBox(height: 16),
                  for (final texto in antes) _TextoFolha(texto),
                  if (antes.isNotEmpty)
                    const Padding(
                      padding: EdgeInsets.only(bottom: 10),
                      child: Text(
                        'Investimento',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  if (linhas.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Text(
                        'Os itens aparecem aqui, do jeito que o cliente vai ler.',
                        style: TextStyle(color: Cores.suave, height: 1.4),
                      ),
                    )
                  else
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _TabelaFolha(
                        cabecalho: const ['Item', 'Cobrança', 'Valor'],
                        pesos: const [5, 2, 2],
                        linhas: [
                          for (final linha in linhas)
                            [
                              linha.item,
                              linha.cobranca,
                              formatarReais(linha.totalCentavos),
                            ],
                        ],
                      ),
                    ),
                  if (resumo.mensagem != null)
                    Text(
                      resumo.mensagem!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    )
                  else if (totais != null && linhas.isNotEmpty) ...[
                    if (totais.descontoCentavos > 0)
                      _LinhaValor(
                        'Desconto',
                        formatarReais(totais.descontoCentavos),
                      ),
                    if (totais.taxaDeslocamentoCentavos > 0)
                      _LinhaValor(
                        'Visita',
                        formatarReais(totais.taxaDeslocamentoCentavos),
                      ),
                    if (controller.mostraTotal) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              controller.rotuloTotal,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Total grande encolhe em vez de estourar a linha.
                          Flexible(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerRight,
                              child: Text(
                                formatarReais(totais.totalCentavos),
                                key: const Key('total'),
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineMedium,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                  if (depois.isNotEmpty) const SizedBox(height: 20),
                  for (final texto in depois) _TextoFolha(texto),
                  if (controller.incluirAceite)
                    _AceiteFolha(controller: controller),
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed:
                        linhas.isEmpty ||
                            totais == null ||
                            controller.validadeDias == null ||
                            controller.gerandoPdf
                        ? null
                        : onPdf,
                    child: Text(
                      controller.gerandoPdf ? 'Gerando PDF…' : 'Gerar PDF',
                    ),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    key: const Key('salvar_proposta_folha'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(46),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: () {
                      final erro = controller.salvarProposta();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(erro ?? 'Proposta salva.')),
                      );
                    },
                    icon: const Icon(Icons.save_outlined, size: 18),
                    label: const Text('Salvar proposta'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Mesmo texto que o PDF desenha: linha com "- " vira tópico.
class _TextoFolha extends StatelessWidget {
  const _TextoFolha(this.texto);

  final TextoProposta texto;

  @override
  Widget build(BuildContext context) {
    Widget conteudo(LinhaTexto linha) => Text.rich(
      TextSpan(
        children: [
          if (linha.rotulo != null)
            TextSpan(
              text: linha.rotulo,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          TextSpan(text: linha.resto),
        ],
      ),
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (texto.titulo.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                texto.titulo,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          for (final linha in lerCorpo(texto.corpo))
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: linha.topico
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(width: 14, child: Text('•')),
                        Expanded(child: conteudo(linha)),
                      ],
                    )
                  : conteudo(linha),
            ),
        ],
      ),
    );
  }
}

/// Resumo do aceite que o PDF desenha com linhas de assinatura.
class _AceiteFolha extends StatelessWidget {
  const _AceiteFolha({required this.controller});

  final PropostaController controller;

  @override
  Widget build(BuildContext context) {
    final cliente = controller.nomeCliente ?? 'Cliente';
    final empresa = controller.nomeEmpresa ?? 'Prestador';
    return Padding(
      key: const Key('aceite_folha'),
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Aceite',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text('Esta proposta é válida até ${controller.validaAte}.'),
          const Text('De acordo,'),
          const SizedBox(height: 10),
          Text(
            'Assinaturas: $cliente e $empresa',
            style: const TextStyle(color: Cores.suave, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

/// Mesma tabela que o PDF desenha: cabeçalho, traço sob cada linha e a
/// última coluna à direita.
class _TabelaFolha extends StatelessWidget {
  const _TabelaFolha({
    required this.cabecalho,
    required this.pesos,
    required this.linhas,
  });

  final List<String> cabecalho;
  final List<int> pesos;
  final List<List<String>> linhas;

  @override
  Widget build(BuildContext context) {
    TableRow linha(List<String> celulas, {required bool topo}) {
      return TableRow(
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: topo ? Cores.suave : Cores.linha,
              width: topo ? 1 : 0.8,
            ),
          ),
        ),
        children: [
          for (var i = 0; i < celulas.length; i++)
            Padding(
              padding: EdgeInsets.fromLTRB(
                i == 0 ? 0 : 6,
                7,
                i == celulas.length - 1 ? 0 : 6,
                7,
              ),
              child: Text(
                celulas[i],
                textAlign: i == celulas.length - 1
                    ? TextAlign.right
                    : TextAlign.left,
                style: TextStyle(
                  fontSize: topo ? 12 : 13.5,
                  fontWeight: topo ? FontWeight.w700 : FontWeight.w500,
                  color: topo ? Cores.suave : Cores.tinta,
                ),
              ),
            ),
        ],
      );
    }

    return Table(
      columnWidths: {
        for (var i = 0; i < pesos.length; i++)
          i: FlexColumnWidth(pesos[i].toDouble()),
      },
      children: [
        linha(cabecalho, topo: true),
        for (final celulas in linhas) linha(celulas, topo: false),
      ],
    );
  }
}

class _LinhaValor extends StatelessWidget {
  const _LinhaValor(this.rotulo, this.valor);

  final String rotulo;
  final String valor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Text(rotulo, style: const TextStyle(color: Cores.suave)),
          const Spacer(),
          Text(valor),
        ],
      ),
    );
  }
}
