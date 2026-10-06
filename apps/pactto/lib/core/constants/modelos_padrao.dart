import '../../models/modelo_proposta.dart';

/// Modelos que o aparelho oferece enquanto o prestador não grava os seus.
const modelosPadrao = [
  ModeloProposta(
    id: 'sistema-sob-medida',
    nome: 'Sistema sob medida',
    aceite: true,
    textos: [
      TextoProposta(
        titulo: 'Apresentação',
        corpo:
            'Proposta de desenvolvimento, implantação e manutenção de um '
            'sistema feito sob medida para a rotina da sua empresa.',
      ),
      TextoProposta(
        titulo: 'Escopo',
        corpo:
            'O sistema entregue inclui:\n'
            '- Cadastros necessários à operação\n'
            '- Telas e filtros combinados com o cliente\n'
            '- Geração de documentos em PDF\n'
            '- Acesso por usuário e senha',
      ),
      TextoProposta(
        titulo: 'Plataformas e hospedagem',
        corpo:
            'O sistema funciona no navegador e como programa instalado no '
            'computador, com os mesmos dados nos dois.\n'
            'Os dados ficam em servidor dedicado na nuvem, com cópia de '
            'segurança diária. Servidor e backup estão inclusos na mensalidade.',
      ),
      TextoProposta(
        titulo: 'O que a mensalidade cobre',
        posicao: PosicaoTexto.depois,
        corpo:
            'Inclui:\n'
            '- Servidor, acesso pela internet e backup diário\n'
            '- Correção de erros e atualizações do sistema\n'
            '- Suporte por WhatsApp em horário comercial\n'
            '- Pequenos ajustes, até 2 horas por mês\n'
            'Não inclui:\n'
            '- Novas funcionalidades fora do escopo, orçadas à parte\n'
            '- Equipamentos, impressoras e internet da empresa',
      ),
      TextoProposta(
        titulo: 'Prazos e condições',
        posicao: PosicaoTexto.depois,
        corpo:
            '- Prazo de entrega: [X] dias úteis após a assinatura\n'
            '- Desenvolvimento e implantação em 3 parcelas: a 1ª na '
            'assinatura, a 2ª na entrega e a 3ª 30 dias após a entrega\n'
            '- Mensalidade a partir do mês seguinte à entrega, com vencimento '
            'todo dia [X]\n'
            '- Período mínimo de 12 meses a partir da entrega\n'
            '- Reajuste anual pelo IPCA\n'
            '- O cliente recebe o direito de uso do sistema; o código-fonte '
            'continua sendo do desenvolvedor\n'
            '- Os dados pertencem ao cliente e, em caso de cancelamento, são '
            'entregues em planilha',
      ),
    ],
  ),
];
