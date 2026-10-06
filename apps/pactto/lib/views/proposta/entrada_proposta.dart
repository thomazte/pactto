import 'package:dominio/dominio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../controllers/proposta_controller.dart';
import '../../core/formatters/formato_telefone.dart';
import '../../core/theme/tema.dart';
import '../../core/widgets/marca_pix.dart';
import '../../models/atalho_item.dart';
import '../../models/modelo_proposta.dart';

class EntradaProposta extends StatelessWidget {
  const EntradaProposta({super.key, required this.controller});

  final PropostaController controller;

  @override
  Widget build(BuildContext context) {
    final linhas = controller.linhas;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'ORÇAMENTO',
          style: TextStyle(
            color: Cores.tinta,
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.4,
          ),
        ),
        const SizedBox(height: 8),
        Text('Nova proposta', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 6),
        const Text(
          'Os dados da empresa ficam salvos. Preencha o cliente, o item e gere o PDF.',
          style: TextStyle(color: Cores.suave, height: 1.4),
        ),
        const SizedBox(height: 22),
        const _Secao('Sua empresa'),
        TextField(
          key: const Key('empresa_nome'),
          controller: controller.empresaNome,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(labelText: 'Nome da empresa'),
          onChanged: (_) => controller.aoEditarEmpresa(),
        ),
        const SizedBox(height: 8),
        TextField(
          key: const Key('empresa_telefone'),
          controller: controller.empresaTelefone,
          keyboardType: TextInputType.phone,
          inputFormatters: const [FormatoTelefone()],
          decoration: const InputDecoration(
            labelText: 'Telefone',
            hintText: '(62) 99999-0000',
          ),
          onChanged: (_) => controller.aoEditarEmpresa(),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller.empresaEmail,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(labelText: 'E-mail'),
          onChanged: (_) => controller.aoEditarEmpresa(),
        ),
        const SizedBox(height: 8),
        TextField(
          key: const Key('empresa_pix'),
          controller: controller.empresaPix,
          decoration: const InputDecoration(
            labelText: 'Pix',
            hintText: 'Chave Pix',
            prefixIcon: Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: MarcaPix(tamanho: 18),
            ),
            prefixIconConstraints: BoxConstraints(minWidth: 42, minHeight: 18),
          ),
          onChanged: (_) => controller.aoEditarEmpresa(),
        ),
        const SizedBox(height: 8),
        _Logo(controller: controller),
        const SizedBox(height: 22),
        const _Secao('Modelo e textos'),
        _Modelo(controller: controller),
        const SizedBox(height: 22),
        const _Secao('Cliente'),
        TextField(
          key: const Key('cliente_nome'),
          controller: controller.clienteNome,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(labelText: 'Nome do cliente'),
          onChanged: (_) => controller.notificar(),
        ),
        const SizedBox(height: 8),
        TextField(
          key: const Key('cliente_whatsapp'),
          controller: controller.clienteWhatsapp,
          keyboardType: TextInputType.phone,
          inputFormatters: const [FormatoTelefone()],
          decoration: const InputDecoration(
            labelText: 'WhatsApp',
            hintText: '(62) 99999-0000',
          ),
          onChanged: (_) => controller.notificar(),
        ),
        const SizedBox(height: 8),
        TextField(
          key: const Key('cliente_documento'),
          controller: controller.clienteDocumento,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: 'CPF ou CNPJ (opcional)',
            hintText: '00.000.000/0000-00',
            errorText: controller.erroDocumentoCliente,
          ),
          onChanged: (_) => controller.notificar(),
        ),
        const SizedBox(height: 22),
        const _Secao('Itens'),
        TextField(
          key: const Key('descricao'),
          controller: controller.descricao,
          textInputAction: TextInputAction.next,
          decoration: const InputDecoration(
            labelText: 'O que é',
            hintText: 'Suporte mensal, implantação',
          ),
          textCapitalization: TextCapitalization.sentences,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final modalidade in ModalidadeItem.values)
              ChoiceChip(
                label: Text(modalidade.rotulo),
                selected: controller.modalidade == modalidade,
                visualDensity: VisualDensity.compact,
                onSelected: (selecionada) {
                  if (selecionada) controller.definirModalidade(modalidade);
                },
              ),
          ],
        ),
        const SizedBox(height: 10),
        _CamposModalidade(controller: controller),
        if (controller.erroItem != null)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 4),
            child: Text(
              controller.erroItem!,
              key: const Key('erro_item'),
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
                fontSize: 13,
              ),
            ),
          ),
        if (linhas.isNotEmpty) ...[
          const SizedBox(height: 8),
          for (var i = 0; i < linhas.length; i++)
            ListTile(
              contentPadding: EdgeInsets.zero,
              dense: true,
              title: Text(linhas[i].texto),
              trailing: IconButton(
                tooltip: 'Remover',
                onPressed: () => controller.remover(i),
                icon: const Icon(Icons.close, size: 18),
              ),
            ),
        ],
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton(
            onPressed: controller.alternarAjustes,
            child: Text(
              controller.mostrarAjustes
                  ? 'Ocultar ajustes'
                  : 'Desconto ou visita',
            ),
          ),
        ),
        if (controller.mostrarAjustes) ...[
          Row(
            children: [
              ChoiceChip(
                label: const Text('%'),
                selected: controller.descontoTipo == TipoDesconto.percentual,
                onSelected: (_) =>
                    controller.definirTipoDesconto(TipoDesconto.percentual),
              ),
              const SizedBox(width: 8),
              ChoiceChip(
                label: const Text(r'R$'),
                selected: controller.descontoTipo == TipoDesconto.fixo,
                onSelected: (_) =>
                    controller.definirTipoDesconto(TipoDesconto.fixo),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: controller.desconto,
            decoration: InputDecoration(
              labelText: controller.descontoTipo == TipoDesconto.percentual
                  ? 'Desconto %'
                  : 'Desconto R\$',
              hintText: controller.descontoTipo == TipoDesconto.percentual
                  ? '10'
                  : '50,00',
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (_) => controller.notificar(),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: controller.visita,
            decoration: const InputDecoration(
              labelText: 'Visita',
              hintText: '0,00',
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (_) => controller.notificar(),
          ),
        ],
      ],
    );
  }
}

class _CamposModalidade extends StatelessWidget {
  const _CamposModalidade({required this.controller});

  final PropostaController controller;

  @override
  Widget build(BuildContext context) {
    final modalidade = controller.modalidade;
    final botao = IconButton.filled(
      key: const Key('adicionar'),
      tooltip: 'Adicionar',
      style: IconButton.styleFrom(
        backgroundColor: Cores.azul,
        foregroundColor: Colors.white,
        disabledBackgroundColor: const Color(0xFFE2E8F0),
      ),
      onPressed: controller.adicionar,
      icon: const Icon(Icons.add),
    );
    final valor = TextField(
      key: const Key('valor'),
      controller: controller.valor,
      decoration: InputDecoration(
        labelText: switch (modalidade) {
          ModalidadeItem.hora => 'Valor da hora',
          ModalidadeItem.valorFechado => 'Valor único',
          ModalidadeItem.mensalidade => 'Valor por mês',
          ModalidadeItem.licenca => 'Valor unitário',
        },
        hintText: switch (modalidade) {
          ModalidadeItem.hora => '60,00',
          ModalidadeItem.valorFechado => '1.200,00',
          ModalidadeItem.mensalidade => '350,00',
          ModalidadeItem.licenca => '40,00',
        },
      ),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      onChanged: (_) => controller.aoEditarItem(),
      onSubmitted: (_) => controller.adicionar(),
    );

    if (!modalidade.informaQuantidade) {
      return Row(
        children: [
          Expanded(child: valor),
          const SizedBox(width: 8),
          botao,
        ],
      );
    }

    return Row(
      children: [
        SizedBox(
          width: modalidade == ModalidadeItem.hora ? 96 : 124,
          child: TextField(
            key: const Key('quantidade'),
            controller: controller.quantidade,
            decoration: InputDecoration(
              labelText: modalidade == ModalidadeItem.hora
                  ? 'Horas'
                  : 'Quantidade',
              hintText: modalidade == ModalidadeItem.hora ? '50' : '1',
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (_) => controller.aoEditarItem(),
            onSubmitted: (_) => controller.adicionar(),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(child: valor),
        const SizedBox(width: 8),
        botao,
      ],
    );
  }
}

class _Logo extends StatelessWidget {
  const _Logo({required this.controller});

  final PropostaController controller;

  Future<void> _escolher(BuildContext context) async {
    final mensageiro = ScaffoldMessenger.of(context);
    String? mensagem;
    try {
      final arquivo = await FilePicker.pickFile(
        dialogTitle: 'Logo da empresa',
        type: FileType.custom,
        allowedExtensions: const ['png', 'jpg', 'jpeg'],
      );
      if (arquivo == null) return;
      mensagem = controller.definirLogo(await arquivo.readAsBytes());
    } catch (_) {
      mensagem = 'Não foi possível abrir a imagem.';
    }
    if (mensagem == null) return;
    mensageiro.showSnackBar(SnackBar(content: Text(mensagem)));
  }

  @override
  Widget build(BuildContext context) {
    final logo = controller.logo;
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Cores.linha),
          ),
          child: logo == null
              ? const Icon(Icons.image_outlined, color: Cores.suave)
              : Image.memory(logo, fit: BoxFit.cover),
        ),
        const SizedBox(width: 10),
        TextButton(
          key: const Key('escolher_logo'),
          onPressed: () => _escolher(context),
          child: Text(logo == null ? 'Escolher logo' : 'Trocar logo'),
        ),
        if (controller.temLogoProprio)
          TextButton(
            key: const Key('logo_padrao'),
            onPressed: controller.usarLogoPadrao,
            child: const Text('Usar o padrão'),
          ),
      ],
    );
  }
}

class _Modelo extends StatelessWidget {
  const _Modelo({required this.controller});

  final PropostaController controller;

  Future<void> _salvar(BuildContext context) async {
    final nome = TextEditingController(
      text: controller.modeloAtual?.nome ?? '',
    );
    final escolhido = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Salvar como modelo'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              key: const Key('nome_modelo'),
              controller: nome,
              autofocus: true,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(labelText: 'Nome do modelo'),
              onSubmitted: (texto) => Navigator.pop(context, texto),
            ),
            const SizedBox(height: 8),
            const Text(
              'Um nome que já existe substitui aquele modelo.',
              style: TextStyle(color: Cores.suave, fontSize: 13),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            key: const Key('confirmar_modelo'),
            onPressed: () => Navigator.pop(context, nome.text),
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
    nome.dispose();
    if (escolhido == null || !context.mounted) return;
    final erro = controller.salvarComoModelo(escolhido);
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(erro ?? 'Modelo salvo.')));
  }

  Future<void> _excluir(BuildContext context, ModeloProposta modelo) async {
    final confirmou = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Excluir "${modelo.nome}"?'),
        content: const Text('Os textos desta proposta continuam como estão.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    if (confirmou == true) controller.excluirModelo(modelo.id);
  }

  @override
  Widget build(BuildContext context) {
    final atual = controller.modeloAtual;
    final textos = controller.textos;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // A chave muda com a escolha, para o campo refletir o modelo salvo
        // ou excluído fora dele.
        KeyedSubtree(
          key: ValueKey('${atual?.id}/${controller.modelos.length}'),
          child: DropdownButtonFormField<String?>(
            key: const Key('modelo'),
            initialValue: atual?.id,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Modelo'),
            items: [
              const DropdownMenuItem(value: null, child: Text('Sem modelo')),
              for (final modelo in controller.modelos)
                DropdownMenuItem(value: modelo.id, child: Text(modelo.nome)),
            ],
            onChanged: controller.escolherModelo,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Escolher um modelo troca os textos desta proposta. '
          'O que você editar aqui só muda o modelo se salvar.',
          style: TextStyle(color: Cores.suave, fontSize: 13, height: 1.4),
        ),
        const SizedBox(height: 12),
        _EscreverComIa(controller: controller),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Incluir aceite com assinaturas',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    Text(
                      'Validade, "De acordo" e linhas de assinatura no fim do PDF.',
                      style: TextStyle(color: Cores.suave, fontSize: 13),
                    ),
                  ],
                ),
              ),
              Switch(
                key: const Key('incluir_aceite'),
                value: controller.incluirAceite,
                onChanged: controller.alternarAceite,
              ),
            ],
          ),
        ),
        for (var i = 0; i < textos.length; i++)
          _CampoTexto(controller: controller, indice: i),
        Wrap(
          spacing: 4,
          children: [
            TextButton.icon(
              key: const Key('adicionar_texto'),
              onPressed: controller.adicionarTexto,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Adicionar texto'),
            ),
            TextButton(
              key: const Key('salvar_modelo'),
              onPressed: () => _salvar(context),
              child: const Text('Salvar como modelo'),
            ),
            if (atual != null)
              TextButton(
                onPressed: () => _excluir(context, atual),
                child: const Text('Excluir modelo'),
              ),
          ],
        ),
      ],
    );
  }
}

/// A IA fica fora do app: o pedido vai para a área de transferência, o
/// prestador cola no Claude e traz a resposta de volta.
class _EscreverComIa extends StatelessWidget {
  const _EscreverComIa({required this.controller});

  final PropostaController controller;

  Future<void> _copiar(BuildContext context) async {
    final mensageiro = ScaffoldMessenger.of(context);
    final pedido = controller.pedidoIa();
    if (pedido == null) {
      mensageiro.showSnackBar(
        const SnackBar(
          content: Text('Escreva primeiro o que o cliente precisa.'),
        ),
      );
      return;
    }
    await Clipboard.setData(ClipboardData(text: pedido));
    mensageiro.showSnackBar(
      const SnackBar(
        content: Text('Pedido copiado. Cole no Claude e copie a resposta.'),
      ),
    );
  }

  Future<void> _colar(BuildContext context) async {
    final mensageiro = ScaffoldMessenger.of(context);
    String? mensagem;
    try {
      final dados = await Clipboard.getData(Clipboard.kTextPlain);
      final texto = dados?.text?.trim() ?? '';
      mensagem = texto.isEmpty
          ? 'Copie a resposta da IA antes de colar.'
          : controller.aplicarRespostaIa(texto) ?? 'Textos atualizados.';
    } catch (_) {
      mensagem = 'Não foi possível ler a área de transferência.';
    }
    mensageiro.showSnackBar(SnackBar(content: Text(mensagem)));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
      decoration: BoxDecoration(
        color: Cores.azulSuave.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Escrever com IA',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          const Text(
            'Escreva em tópicos o que o cliente precisa. Copie o pedido, cole '
            'no Claude (claude.ai), copie a resposta e toque em "Colar resposta".',
            style: TextStyle(color: Cores.suave, fontSize: 13, height: 1.4),
          ),
          const SizedBox(height: 8),
          TextField(
            key: const Key('topicos_ia'),
            controller: controller.topicosIa,
            minLines: 2,
            maxLines: null,
            keyboardType: TextInputType.multiline,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'O que o cliente precisa',
              hintText: 'Sistema de OS, controle de garantia, PDF da OS',
            ),
          ),
          Wrap(
            spacing: 4,
            children: [
              TextButton.icon(
                key: const Key('copiar_pedido_ia'),
                onPressed: () => _copiar(context),
                icon: const Icon(Icons.copy, size: 18),
                label: const Text('Copiar pedido para IA'),
              ),
              TextButton.icon(
                key: const Key('colar_resposta_ia'),
                onPressed: () => _colar(context),
                icon: const Icon(Icons.content_paste, size: 18),
                label: const Text('Colar resposta'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CampoTexto extends StatelessWidget {
  const _CampoTexto({required this.controller, required this.indice});

  final PropostaController controller;
  final int indice;

  @override
  Widget build(BuildContext context) {
    final texto = controller.textos[indice];
    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.fromLTRB(12, 12, 4, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Cores.linha),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  key: Key('texto_titulo_$indice'),
                  controller: texto.titulo,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Título',
                    hintText: 'Escopo',
                  ),
                  onChanged: (_) => controller.notificar(),
                ),
              ),
              IconButton(
                tooltip: 'Remover texto',
                onPressed: () => controller.removerTexto(indice),
                icon: const Icon(Icons.close, size: 18),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: TextField(
              key: Key('texto_corpo_$indice'),
              controller: texto.corpo,
              minLines: 3,
              maxLines: null,
              keyboardType: TextInputType.multiline,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Texto',
                hintText: 'Comece a linha com "- " para virar tópico.',
              ),
              onChanged: (_) => controller.notificar(),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            children: [
              for (final posicao in PosicaoTexto.values)
                ChoiceChip(
                  label: Text(posicao.rotulo),
                  selected: texto.posicao == posicao,
                  visualDensity: VisualDensity.compact,
                  onSelected: (selecionada) {
                    if (selecionada) {
                      controller.definirPosicao(indice, posicao);
                    }
                  },
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Secao extends StatelessWidget {
  const _Secao(this.rotulo);

  final String rotulo;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: Cores.azul,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(rotulo, style: Theme.of(context).textTheme.titleMedium),
        ],
      ),
    );
  }
}
