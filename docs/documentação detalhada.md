# Documentação detalhada

Versão do aplicativo: 0.1.0.

O Pactto é o aplicativo com o qual o prestador monta uma proposta e entrega um PDF ao cliente. O repositório separa a interface Flutter das regras de cálculo. Esta página descreve o comportamento da versão atual e as regras já definidas no pacote de domínio.

## 1. Repositório

Workspace Dart, com a raiz em `pubspec.yaml`.

| Caminho | Responsabilidade |
| --- | --- |
| `apps/pactto` | Aplicativo Flutter. Identificador Android: `br.com.pactto`. |
| `packages/dominio` | Dinheiro, validação, validade e máquina de estados. Não desenha tela. |

A interface segue MVC.

| Pasta em `apps/pactto/lib` | Conteúdo |
| --- | --- |
| `models` | Empresa, item digitado, resumo e dados do PDF. |
| `views/proposta` | Formulário, pré-visualização e composição da tela. |
| `controllers` | Estado da proposta e ações do prestador. |
| `services` | Gravação local da empresa e geração do PDF. |
| `core` | Tema, máscara de telefone e marca Pix. |

O ponto de entrada é `apps/pactto/lib/main.dart`. Um `flutter run` na raiz do repositório não encontra esse arquivo.

## 2. Uso da tela

Ao abrir, o aplicativo carrega nome, telefone, e-mail e Pix gravados no aparelho. O prestador informa o cliente, acrescenta itens e acompanha a folha ao lado, ou abaixo, em telas com menos de 900 px de largura.

Cada item tem descrição, quantidade e valor. A quantidade vazia vale 1. Sem valor, o item não entra. Quantidade ou valor ilegível, quantidade zero ou valor negativo também impedem a entrada: o motivo aparece abaixo dos campos e some quando o prestador volta a digitar. Atalhos preenchem a descrição e o tipo:

| Atalho | Tipo |
| --- | --- |
| Hora de desenvolvimento | Mão de obra |
| Suporte | Mão de obra |
| Licença | Material |

Descrição vazia aparece como "Serviço" ou "Licença", conforme o tipo. Desconto e visita ficam ocultos até o prestador abrir "Desconto ou visita". O desconto é percentual ou fixo em reais. A visita é uma taxa somada depois do desconto.

O botão "Gerar PDF" só fica ativo com ao menos um item e com o total calculado. Depois que o PDF é impresso, compartilhado ou baixado, cliente, itens, desconto e visita são apagados. Se o prestador fechar a impressão ou o compartilhamento sem concluir, a proposta continua preenchida. Os dados da empresa permanecem.

Telefone e WhatsApp aceitam a máscara brasileira: celular `(62) 98483-5669` e fixo `(62) 3483-5669`. Um prefixo `55` com 12 ou 13 dígitos é removido antes da máscara.

## 3. Cálculo usado pela tela

Valores trafegam em centavos inteiros. Quantidade trafega em milésimos: `2,5` é `2500`. O total da linha é quantidade vezes valor unitário, com divisão half-up na terceira casa. Meio milésimo ou mais sobe um centavo. Exemplo: `2,5 × 33,33` fecha em `R$ 83,33`.

A base do desconto é a soma das linhas. O percentual incide só sobre essa base. A visita entra depois e não entra na base do percentual. O total é base menos desconto, mais visita.

O campo percentual usa a mesma leitura de moeda. `10` e `10,00` valem 10%. `100` vale 100%. Acima de 100% o cálculo recusa o desconto. Desconto fixo maior que a base também é recusado. Quantidade aceita no máximo três casas decimais, com vírgula. Moeda aceita o formato brasileiro, com ponto de milhar e até duas casas: `1.234,50`.

Para o teclado numérico sem vírgula, um texto sem vírgula com um único ponto seguido de um ou dois dígitos lê o ponto como vírgula: `10.5` vale `10,50` e `2.5` horas valem `2,5`. Com três dígitos depois do ponto, `1.234` continua milhar na moeda e é recusado na quantidade, que não tem milhar. Valores grandes demais para o cálculo são recusados com "Valor alto demais.".

Mensagens exibidas na folha e abaixo dos campos do item:

| Situação | Texto |
| --- | --- |
| Desconto maior que os itens | O desconto passa do valor dos itens. |
| Percentual fora de 0 a 100 | O desconto vai de 0 a 100%. |
| Quantidade ilegível | Quantidade inválida. Exemplo: 2,5. |
| Valor ilegível | Valor inválido. Exemplo: 180,00. |
| Valor acima do limite do cálculo | Valor alto demais. |
| Valor do item negativo | O valor não pode ser negativo. |
| Visita negativa | A visita não pode ser negativa. |
| Outra falha de domínio | Confira os valores para continuar. |

Falha ao gerar ou entregar o PDF mostra "Não foi possível gerar o PDF." No navegador, a entrega bem-sucedida mostra "PDF baixado."

## 4. Persistência e PDF

A empresa é gravada em `SharedPreferences` a cada alteração, nas chaves `empresa_nome`, `empresa_telefone`, `empresa_email` e `empresa_pix`. Não há conta nem servidor.

O PDF é uma página A4, com as fontes DejaVu embutidas, para o texto em português sair corretamente. O arquivo se chama `proposta.pdf`. No celular, o aplicativo abre a impressão do sistema e, se ela falhar, oferece compartilhamento. No navegador, o arquivo é compartilhado para download.

A folha e o PDF informam validade de 7 dias. Esse prazo é texto da proposta, não uma data calculada na tela.

## 5. Regras de domínio ainda fora da tela

O pacote `dominio` já contém regras que a versão 0.1.0 não expõe na interface. Elas não alteram o PDF atual. Ficam aqui para o contrato do cálculo permanecer explícito.

### 5.1 Dinheiro

A soma e o arredondamento usam `BigInt` e só então cabem num inteiro de 64 bits. Valor negativo no arredondamento, ou acima do limite, é erro de domínio. Preço unitário negativo e taxa de visita negativa são recusados. Preço zero é permitido.

### 5.2 Estado do orçamento

Estados: rascunho, enviado, aprovado, recusado, concluído e expirado.

| De | Para | Quem pode | Condição |
| --- | --- | --- | --- |
| Rascunho | Enviado | Prestador | — |
| Enviado | Aprovado | Cliente ou prestador | — |
| Enviado | Recusado | Cliente ou prestador | Motivo com pelo menos 10 caracteres |
| Enviado | Expirado | Sistema | — |
| Enviado | Rascunho | Cliente | Motivo com pelo menos 10 caracteres |
| Aprovado | Concluído | Prestador | — |
| Recusado | Rascunho | Prestador | — |
| Expirado | Rascunho | Prestador | — |

Qualquer outra passagem é transição inválida.

### 5.3 Validade

O dia civil é o de São Paulo, UTC−3, sem horário de verão. A validade aceita de 1 a 365 dias, contados a partir da data civil do envio. Uma proposta só vence se estiver enviada e se o dia civil atual for posterior ao último dia válido.

### 5.4 Envio, pagamento e documentos

A validação de envio exige Pix no perfil, WhatsApp do cliente e ao menos um item. À vista exige um meio: Pix, dinheiro ou ambos, sem parcelas e sem entrada. Parcelamento exige de 2 a 24 parcelas, sem entrada. O resto dos centavos cai nas primeiras parcelas. Entrada mais saldo exige entrada maior que zero e menor que o total.

CPF e CNPJ são validados pelos dígitos verificadores. Sequências de um único dígito repetido são inválidas. O valor normalizado guarda só os dígitos.

## 6. Verificação

Na raiz, uma vez:

```bash
flutter pub get
```

Aplicativo:

```bash
cd apps/pactto
flutter test
```

Domínio:

```bash
cd packages/dominio
dart test
```

## 7. Licença

MIT. O texto está em [LICENSE](../LICENSE).
