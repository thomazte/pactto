import 'package:dominio/dominio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pactto/core/constants/empresa_padrao.dart';
import 'package:pactto/models/empresa.dart';
import 'package:pactto/services/empresa_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('sem nada gravado, vale a empresa padrão', () async {
    SharedPreferences.setMockInitialValues({});
    final empresa = await const EmpresaLocal().carregar();
    expect(empresa.nome, '69.408.874 THOMAZ ARTHUR CORREIA DE OLIVEIRA');
    expect(empresa.telefone, '(62) 98483-5669');
    expect(empresa.email, 'zamoht.exe@gmail.com');
    expect(empresa.pix, '69.408.874/0001-89');
    expect(cnpjValido(empresa.pix), isTrue);
  });

  test('o que foi editado vale, e campo apagado volta ao padrão', () async {
    SharedPreferences.setMockInitialValues({});
    await const EmpresaLocal().salvar(
      const Empresa(nome: 'Outra Ltda', telefone: '', email: ' ', pix: ''),
    );
    final empresa = await const EmpresaLocal().carregar();
    expect(empresa.nome, 'Outra Ltda');
    expect(empresa.telefone, empresaPadrao.telefone);
    expect(empresa.email, empresaPadrao.email);
    expect(empresa.pix, empresaPadrao.pix);
  });
}
