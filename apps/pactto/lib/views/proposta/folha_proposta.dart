import 'package:dominio/dominio.dart';
import 'package:flutter/material.dart';

import '../../controllers/proposta_controller.dart';
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'PROPOSTA',
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
                            const MarcaPix(tamanho: 14, cor: Colors.white),
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
                  const Text(
                    'Válida por 7 dias.',
                    style: TextStyle(color: Cores.suave, fontSize: 13),
                  ),
                  const SizedBox(height: 16),
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
