import 'package:dominio/dominio.dart';
import 'package:flutter/material.dart';

import '../../controllers/proposta_controller.dart';
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
    final somadas = [
      for (final linha in linhas)
        if (linha.somaNoOrcamento) linha,
    ];
    final mensalidades = [
      for (final linha in linhas)
        if (!linha.somaNoOrcamento) linha,
    ];
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
                    for (final linha in somadas) ...[
                      Text(
                        linha.texto,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const Divider(height: 22, color: Cores.linha),
                    ],
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
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Text(
                          'Total',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          formatarReais(totais.totalCentavos),
                          key: const Key('total'),
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                      ],
                    ),
                    if (mensalidades.isNotEmpty) ...[
                      const Divider(height: 28, color: Cores.linha),
                      for (final linha in mensalidades)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Text(linha.texto),
                        ),
                    ],
                  ],
                  if (depois.isNotEmpty) const SizedBox(height: 20),
                  for (final texto in depois) _TextoFolha(texto),
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed:
                        linhas.isEmpty ||
                            totais == null ||
                            controller.gerandoPdf
                        ? null
                        : onPdf,
                    child: Text(
                      controller.gerandoPdf ? 'Gerando PDF…' : 'Gerar PDF',
                    ),
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
    final linhas = texto.corpo
        .split('\n')
        .map((linha) => linha.trim())
        .where((linha) => linha.isNotEmpty);
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
          for (final linha in linhas)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: linha.startsWith('- ')
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(width: 14, child: Text('•')),
                        Expanded(child: Text(linha.substring(2).trim())),
                      ],
                    )
                  : Text(linha, style: const TextStyle(color: Cores.tinta)),
            ),
        ],
      ),
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
