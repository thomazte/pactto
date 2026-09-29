# Pactto

Aplicativo para o prestador montar uma proposta comercial e gerar o PDF que o cliente lê. Os dados da empresa ficam salvos no aparelho. O cliente, os itens, o desconto e a visita entram na hora.

## Estrutura

O repositório é um workspace Dart.

| Pasta | Papel |
| --- | --- |
| `apps/pactto` | App Flutter. A tela segue MVC: `models`, `views`, `controllers` e `services`. |
| `packages/dominio` | Regras de dinheiro, validação e estado do orçamento, sem interface. |

## Requisitos

- [Flutter](https://flutter.dev/install) com Dart `3.13` ou mais recente

Na raiz do repositório:

```bash
flutter pub get
```

## Rodar

O `lib/main.dart` fica no app, não na raiz.

```bash
cd apps/pactto
flutter run
```

Para escolher o celular:

```bash
flutter devices
flutter run -d <id-do-aparelho>
```

## Testes

App:

```bash
cd apps/pactto
flutter test
```

Domínio:

```bash
cd packages/dominio
dart test
```

## Licença

MIT. Veja [LICENSE](LICENSE).
