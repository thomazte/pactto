import 'package:dominio/dominio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../controllers/proposta_controller.dart';
import '../../core/formatters/formato_telefone.dart';
import '../../core/theme/tema.dart';
import '../../core/widgets/marca_pix.dart';
import '../../models/atalho_item.dart';

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
        if (logo != null)
          TextButton(
            key: const Key('remover_logo'),
            onPressed: controller.removerLogo,
            child: const Text('Remover'),
          ),
      ],
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
