# Frontend - Projeto Semestral

Frontend **exclusivamente web** do projeto semestral, desenvolvido com Flutter Web e preparado para integração com um backend FastAPI.

O objetivo funcional do sistema ainda será definido. Por isso, esta base evita criar regras de negócio, módulos ou telas que ainda não foram aprovados.

## Stack

- Flutter Web
- Dart
- Material 3
- FastAPI no backend
- API configurável por `--dart-define`

## Estrutura

```text
lib/
├── app/
│   ├── app.dart
│   └── routes/
│       └── app_routes.dart
├── core/
│   ├── config/
│   │   └── app_config.dart
│   ├── network/
│   │   └── api_paths.dart
│   └── theme/
│       └── app_theme.dart
├── features/
│   └── home/
│       └── presentation/
│           └── pages/
│               └── home_page.dart
├── shared/
│   └── widgets/
│       └── info_card.dart
└── main.dart
```

### Responsabilidade das pastas

- `app`: inicialização do aplicativo e rotas globais.
- `core`: configurações e recursos usados por toda a aplicação.
- `features`: módulos funcionais. Novas funcionalidades devem nascer aqui.
- `shared`: componentes reutilizáveis sem regra de negócio específica.

## Pré-requisitos

Instale o Flutter SDK com suporte web e confirme o ambiente:

```bash
flutter doctor
flutter devices
```

O navegador deve aparecer entre os dispositivos disponíveis.

## Instalação

Na pasta deste projeto:

```bash
flutter pub get
```

## Executar no navegador

Com o FastAPI local na porta padrão configurada no projeto:

```bash
flutter run -d chrome
```

Para usar outra URL do backend:

```bash
flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:8000
```

Também é possível informar o ambiente:

```bash
flutter run -d chrome \
  --dart-define=APP_ENV=development \
  --dart-define=API_BASE_URL=http://localhost:8000
```

## Build para publicação

```bash
flutter build web --release \
  --dart-define=APP_ENV=production \
  --dart-define=API_BASE_URL=https://api.exemplo.com
```

Os arquivos estáticos serão gerados em:

```text
build/web/
```

Esses arquivos podem ser publicados por um servidor web, como Nginx ou Apache.

## Integração com FastAPI

A URL base está centralizada em:

```text
lib/core/config/app_config.dart
```

Os caminhos dos endpoints devem ser declarados em:

```text
lib/core/network/api_paths.dart
```

Não coloque URLs do backend diretamente dentro das páginas.

## Próximos passos

Quando o objetivo e as funcionalidades do sistema forem definidos:

1. criar uma pasta em `lib/features/` para cada módulo funcional;
2. adicionar as rotas correspondentes em `app_routes.dart`;
3. implementar a camada responsável pelas requisições HTTP ao FastAPI;
4. criar modelos apenas quando a estrutura real dos dados estiver definida;
5. substituir a página inicial informativa pelas telas reais do sistema.

## Versionamento automatico com Git Hook

O repositorio inclui um hook de versionamento na raiz de `FrontEnd`.

Depois de clonar o repositorio, instale uma vez:

```bash
./setup_hooks.sh
```

No Windows, tambem e possivel executar `setup_hook.bat` com duplo clique.

Padrao de commit aceito:

```text
FEAT: descricao
FIX: descricao
CHORE: descricao
```

O hook atualiza automaticamente a versao do `pubspec.yaml`, o `CHANGELOG.md`, a mensagem do commit e a tag Git local.
