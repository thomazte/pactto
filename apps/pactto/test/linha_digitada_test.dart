import 'package:flutter_test/flutter_test.dart';
import 'package:pactto/models/atalho_item.dart';
import 'package:pactto/models/linha_digitada.dart';

void main() {
  test(
    'hora, valor fechado, mensalidade e licença descrevem a conta preenchida',
    () {
      expect(
        LinhaDigitada.ler(
          modalidade: ModalidadeItem.hora,
          descricao: 'Desenvolvimento',
          quantidade: '50',
          valor: '60',
        ).texto,
        r'Desenvolvimento — 50 h × R$ 60,00 = R$ 3.000,00',
      );
      expect(
        LinhaDigitada.ler(
          modalidade: ModalidadeItem.valorFechado,
          descricao: 'Implantação',
          quantidade: '1',
          valor: '1.200,00',
        ).texto,
        r'Implantação — R$ 1.200,00',
      );
      expect(
        LinhaDigitada.ler(
          modalidade: ModalidadeItem.mensalidade,
          descricao: '',
          quantidade: '1',
          valor: '350',
        ).texto,
        r'Mensalidade — R$ 350,00 por mês, a partir do uso',
      );
      expect(
        LinhaDigitada.ler(
          modalidade: ModalidadeItem.licenca,
          descricao: '',
          quantidade: '3',
          valor: '40',
        ).texto,
        r'3 licenças × R$ 40,00',
      );
      expect(
        LinhaDigitada.ler(
          modalidade: ModalidadeItem.licenca,
          descricao: '',
          quantidade: '1',
          valor: '40',
        ).texto,
        r'1 licença × R$ 40,00',
      );
    },
  );
}
