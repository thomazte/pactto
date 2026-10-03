import 'package:flutter/material.dart';

import '../../controllers/proposta_controller.dart';
import '../../core/theme/tema.dart';
import '../../models/empresa.dart';
import 'entrada_proposta.dart';
import 'folha_proposta.dart';

class TelaProposta extends StatefulWidget {
  const TelaProposta({super.key, this.empresa = const Empresa()});

  final Empresa empresa;

  @override
  State<TelaProposta> createState() => _TelaPropostaState();
}

class _TelaPropostaState extends State<TelaProposta> {
  late final PropostaController _controller = PropostaController(
    empresa: widget.empresa,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _gerarPdf() async {
    final resultado = await _controller.gerarPdf();
    if (!mounted) return;
    final mensagem = switch (resultado) {
      ResultadoPdf.baixado => 'PDF baixado.',
      ResultadoPdf.falha => 'Não foi possível gerar o PDF.',
      ResultadoPdf.gerado ||
      ResultadoPdf.cancelado ||
      ResultadoPdf.ignorado => null,
    };
    if (mensagem == null) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(mensagem)));
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        final entrada = EntradaProposta(controller: _controller);
        final folha = FolhaProposta(controller: _controller, onPdf: _gerarPdf);
        return Scaffold(
          body: LayoutBuilder(
            builder: (context, constraints) {
              final largo = constraints.maxWidth >= 900;
              if (!largo) {
                return ColoredBox(
                  color: Cores.fundo,
                  child: SafeArea(
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                      children: [entrada, const SizedBox(height: 20), folha],
                    ),
                  ),
                );
              }
              return SafeArea(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(
                      width: 440,
                      child: ColoredBox(
                        color: Cores.painel,
                        child: ListView(
                          padding: const EdgeInsets.fromLTRB(28, 32, 24, 32),
                          children: [entrada],
                        ),
                      ),
                    ),
                    Expanded(
                      child: ColoredBox(
                        color: Cores.fundo,
                        child: Align(
                          alignment: Alignment.topCenter,
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 560),
                            child: ListView(
                              padding: const EdgeInsets.fromLTRB(
                                28,
                                36,
                                36,
                                40,
                              ),
                              children: [folha],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}
