import '../../models/modelo_proposta.dart';

/// Modelos que o aparelho oferece enquanto o prestador não grava os seus.
const modelosPadrao = [
  ModeloProposta(
    id: 'sistema-sob-medida',
    nome: 'Sistema sob medida',
    aceite: true,
    validadeDias: 15,
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
            '- Cadastros: os necessários à operação\n'
            '- Telas e filtros: combinados com o cliente\n'
            '- Documentos: geração em PDF\n'
            '- Acesso: por usuário e senha',
      ),
      TextoProposta(
        titulo: 'Plataformas e hospedagem',
        corpo:
            'O sistema funciona no navegador e como programa instalado no '
            'computador (Windows e Linux), com os mesmos dados nos dois. Uma '
            'versão para celular Android pode ser adicionada depois, sem '
            'refazer o sistema.\n'
            'Os dados ficam em servidor dedicado na nuvem, com acesso por '
            'usuário e senha e cópia de segurança (backup) diária. Servidor, '
            'domínio de acesso e backup estão inclusos na mensalidade.',
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
            '- Novas funcionalidades fora do escopo acima, que serão orçadas '
            'à parte\n'
            '- Equipamentos, impressoras e internet da empresa',
      ),
      TextoProposta(
        titulo: 'Prazos e condições',
        posicao: PosicaoTexto.depois,
        corpo:
            '- Prazo de entrega: [X] dias úteis após a assinatura\n'
            '- Pagamento do desenvolvimento e implantação: 2 parcelas, sendo '
            'a 1ª na assinatura e a 2ª na entrega\n'
            '- Mensalidade: começa no mês seguinte à entrega, com vencimento '
            'todo dia [X]\n'
            '- Período mínimo: 12 meses a partir da entrega\n'
            '- Reajuste: anual, pelo IPCA\n'
            '- Licença: o cliente recebe o direito de uso do sistema; o '
            'código-fonte continua sendo do desenvolvedor\n'
            '- Dados: pertencem ao cliente; em caso de cancelamento, são '
            'entregues em planilha',
      ),
    ],
  ),
];
