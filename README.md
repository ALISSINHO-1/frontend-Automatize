# Projeto Semestral - UNICIVE

Projeto acadêmico desenvolvido como parte das atividades semestrais da **UNICIVE**.

O objetivo é desenvolver uma aplicação completa, contemplando **frontend, backend, banco de dados, integração via API, versionamento e publicação em ambiente Linux**.

> **Status:** Em planejamento e desenvolvimento inicial.

---

## 📌 Sobre o projeto

Este repositório será utilizado para o desenvolvimento do projeto semestral da faculdade.

A aplicação será construída utilizando uma arquitetura dividida em três partes principais:

* **Frontend:** Flutter / Dart
* **Backend:** FastAPI / Python
* **Banco de dados:** PostgreSQL

A administração e visualização do banco será realizada através do **DBeaver**.

A versão web do frontend será gerada utilizando **Flutter Web** e, futuramente, poderá ser publicada em um servidor Linux utilizando **Nginx**.

---

## 🎯 Objetivo do sistema

> **Em definição pela equipe.**

O problema que o sistema irá resolver e o segmento da empresa fictícia ainda serão definidos durante o planejamento do projeto.

Quando definido, esta seção deverá responder:

* Qual problema o sistema resolve?
* Para quem o sistema foi criado?
* Quais processos serão controlados?
* Qual é o principal benefício da aplicação?

---

## 👥 Público-alvo

> **Ainda não definido.**

O público será determinado após a definição da empresa fictícia e das funcionalidades principais do sistema.

---

## 🚧 Status do projeto

O projeto encontra-se atualmente em fase de:

**Planejamento e definição de requisitos.**

### Já definido

* [x] Frontend com Flutter
* [x] Linguagem Dart no frontend
* [x] Backend com FastAPI
* [x] Linguagem Python no backend
* [x] Comunicação através de API REST
* [x] Banco de dados relacional
* [x] PostgreSQL como banco de dados
* [x] DBeaver para administração do banco
* [x] Git para controle de versão
* [x] GitHub para armazenamento do repositório
* [x] Possibilidade de execução em Linux
* [x] Flutter Web para versão web
* [x] Nginx como opção principal de servidor web

### Ainda será definido

* [ ] Nome da empresa fictícia
* [ ] Segmento da empresa
* [ ] Problema que será resolvido
* [ ] Público-alvo
* [ ] Funcionalidades principais
* [ ] Regras de negócio
* [ ] Entidades do banco
* [ ] Modelo do banco de dados
* [ ] Endpoints da API
* [ ] Telas do sistema
* [ ] Identidade visual
* [ ] Requisitos funcionais
* [ ] Requisitos não funcionais

---

# 🏗️ Arquitetura

A arquitetura planejada para o projeto é:

```text
┌─────────────────────────┐
│         USUÁRIO         │
└────────────┬────────────┘
             │
             ▼
┌─────────────────────────┐
│      FLUTTER WEB        │
│        Frontend         │
│          Dart           │
└────────────┬────────────┘
             │
             │ HTTP / JSON
             ▼
┌─────────────────────────┐
│        FASTAPI          │
│        Backend          │
│         Python          │
└────────────┬────────────┘
             │
             │ SQL
             ▼
┌─────────────────────────┐
│      POSTGRESQL         │
│     Banco de dados      │
└─────────────────────────┘
```

Durante o desenvolvimento:

```text
DBeaver
   │
   ▼
PostgreSQL
```

O **DBeaver não é o banco de dados**. Ele será utilizado apenas como ferramenta gráfica para administrar e consultar o PostgreSQL.

---

# 🔄 Fluxo da aplicação

Um fluxo comum da aplicação deverá funcionar da seguinte maneira:

```text
Usuário
   ↓
Flutter
   ↓
Requisição HTTP
   ↓
FastAPI
   ↓
Regra de negócio
   ↓
PostgreSQL
   ↓
FastAPI
   ↓
JSON
   ↓
Flutter
   ↓
Usuário
```

### Exemplo

Ao consultar uma lista de registros:

1. O usuário abre uma tela no Flutter.
2. O Flutter envia uma requisição para o FastAPI.
3. O FastAPI recebe a requisição.
4. O backend executa as regras necessárias.
5. O FastAPI consulta o PostgreSQL.
6. O PostgreSQL retorna os dados.
7. O FastAPI transforma os dados em uma resposta.
8. A resposta é enviada em JSON.
9. O Flutter recebe os dados.
10. A interface é atualizada.

---

# 🛠️ Tecnologias

## Frontend

### Flutter

Responsável pela interface da aplicação.

Será utilizado também para gerar a versão Web do sistema.

### Dart

Linguagem utilizada pelo Flutter.

---

## Backend

### Python

Linguagem utilizada para desenvolver a API.

### FastAPI

Framework utilizado para construção do backend e da API REST.

O backend será responsável por:

* receber requisições;
* validar dados;
* executar regras de negócio;
* consultar o banco;
* cadastrar informações;
* atualizar registros;
* excluir registros;
* retornar respostas para o frontend.

---

## Banco de dados

### PostgreSQL

Banco de dados relacional utilizado pelo sistema.

Será responsável pelo armazenamento permanente das informações da aplicação.

### DBeaver

Ferramenta gráfica utilizada para:

* administrar o PostgreSQL;
* executar comandos SQL;
* consultar dados;
* visualizar tabelas;
* criar estruturas;
* auxiliar durante o desenvolvimento.

---

## Versionamento

### Git

Utilizado para controle de versão do projeto.

### GitHub

Utilizado para armazenar remotamente o repositório e permitir colaboração entre os integrantes.

---

## Servidor

### Linux

Ambiente planejado para execução da versão publicada do projeto.

### Nginx

Servidor web planejado para disponibilizar o Flutter Web e encaminhar requisições da API para o FastAPI.

---

# 🌐 Comunicação da API

Frontend e backend deverão se comunicar utilizando **HTTP**.

Os dados serão enviados principalmente no formato:

```json
{
  "exemplo": "valor"
}
```

Os principais métodos HTTP utilizados deverão ser:

| Método | Finalidade             |
| ------ | ---------------------- |
| GET    | Consultar dados        |
| POST   | Cadastrar dados        |
| PUT    | Atualizar um recurso   |
| PATCH  | Atualizar parcialmente |
| DELETE | Excluir um recurso     |

---

# ♻️ CRUD

Boa parte das funcionalidades do sistema provavelmente seguirá o conceito de CRUD:

```text
C - Create
R - Read
U - Update
D - Delete
```

Correspondência aproximada:

| CRUD   | HTTP      | SQL    |
| ------ | --------- | ------ |
| Create | POST      | INSERT |
| Read   | GET       | SELECT |
| Update | PUT/PATCH | UPDATE |
| Delete | DELETE    | DELETE |

As entidades que possuirão CRUD ainda serão determinadas após a definição das regras de negócio.

---

# 📁 Estrutura do projeto

A organização definitiva das pastas ainda será definida conforme o desenvolvimento.

Uma estrutura possível será:

```text
Projeto-Semestral-UNICIVE/
│
├── frontend/
│   └── Aplicação Flutter
│
├── backend/
│   └── API FastAPI
│
├── database/
│   └── Scripts e documentação do PostgreSQL
│
├── docs/
│   └── Documentação do projeto
│
├── .gitignore
│
└── README.md
```

> Esta estrutura representa o planejamento inicial e poderá ser alterada conforme a evolução do projeto.

---

# 💻 Ambiente de desenvolvimento

Cada integrante deverá possuir um ambiente preparado para trabalhar no projeto.

## Programas principais

* Git
* Python
* Flutter SDK
* PostgreSQL
* DBeaver
* Visual Studio Code ou outra IDE compatível

Também será necessário um navegador para executar e testar o Flutter Web.

---

# 📥 Clonando o projeto

Para obter uma cópia do projeto:

```bash
git clone https://github.com/ALISSINHO-1/Projeto-Semestral-UNICIVE.git
```

Depois:

```bash
cd Projeto-Semestral-UNICIVE
```

---

# 🐍 Backend

O backend será desenvolvido utilizando Python e FastAPI.

Uma prática recomendada será utilizar um ambiente virtual Python.

Exemplo:

```bash
python -m venv .venv
```

### Windows

```bash
.venv\Scripts\activate
```

### Linux

```bash
source .venv/bin/activate
```

As dependências do backend deverão posteriormente ser registradas em um arquivo como:

```text
requirements.txt
```

Quando esse arquivo existir:

```bash
pip install -r requirements.txt
```

---

# ⚡ Executando o FastAPI

A forma definitiva dependerá da estrutura criada para o backend.

Um exemplo comum será:

```bash
fastapi dev main.py
```

ou:

```bash
uvicorn main:app --reload
```

Depois de iniciado, o backend ficará disponível em um endereço local.

A documentação automática da API também poderá ser acessada através da rota:

```text
/docs
```

---

# 🐘 Banco de dados

O banco utilizado será:

```text
PostgreSQL
```

Durante o desenvolvimento ele poderá ser administrado pelo DBeaver.

As seguintes informações de conexão serão necessárias:

```text
Host
Porta
Banco
Usuário
Senha
```

Essas credenciais **não devem ser colocadas diretamente no código-fonte**.

---

# 🔐 Variáveis de ambiente

Dados sensíveis deverão ser armazenados em variáveis de ambiente.

Exemplo:

```env
DB_HOST=localhost
DB_PORT=5432
DB_NAME=projeto
DB_USER=usuario
DB_PASSWORD=senha
```

O arquivo real:

```text
.env
```

não deverá ser enviado para o repositório.

Um arquivo de exemplo poderá ser criado:

```text
.env.example
```

Exemplo:

```env
DB_HOST=
DB_PORT=5432
DB_NAME=
DB_USER=
DB_PASSWORD=
```

---

# 🎨 Frontend

O frontend será construído utilizando Flutter.

Após instalar o Flutter, o ambiente deverá ser verificado através de:

```bash
flutter doctor
```

Para verificar os dispositivos disponíveis:

```bash
flutter devices
```

---

# 🌍 Flutter Web

O sistema será preparado para execução através do navegador.

Durante o desenvolvimento:

```bash
flutter run -d chrome
```

Para gerar uma versão de produção:

```bash
flutter build web
```

Os arquivos gerados poderão posteriormente ser colocados no servidor web.

Não será necessário converter manualmente o projeto Flutter para HTML, CSS ou Java.

---

# 🐧 Publicação em Linux

A arquitetura planejada para produção é:

```text
Internet
   │
   ▼
Nginx
   │
   ├──────────────► Flutter Web
   │
   └──── /api ───► FastAPI
                      │
                      ▼
                  PostgreSQL
```

O Nginx poderá:

* disponibilizar os arquivos do Flutter Web;
* receber acessos HTTP/HTTPS;
* encaminhar chamadas da API para o FastAPI.

---

# 🧪 Testes

Antes de uma funcionalidade ser considerada concluída deverão ser validados:

### Frontend

* carregamento da tela;
* formulários;
* validações;
* navegação;
* comunicação com API;
* comportamento no navegador.

### Backend

* endpoints;
* validação dos dados;
* regras de negócio;
* tratamento de erros;
* conexão com o banco.

### Banco

* criação das tabelas;
* relacionamentos;
* constraints;
* inserção;
* consulta;
* atualização;
* exclusão.

### Integração

O fluxo completo deverá ser validado:

```text
Flutter → FastAPI → PostgreSQL → FastAPI → Flutter
```

---

# 🌿 Git

O projeto utilizará Git para controle das alterações.

Fluxo básico:

```bash
git pull
git status
git add .
git commit -m "tipo: descrição"
git push
```

---

# 📝 Padrão de commits

Para manter o histórico organizado, poderá ser utilizado o seguinte padrão:

```text
tipo: descrição
```

Exemplos:

```text
feat: adiciona tela de login
fix: corrige validação do cadastro
docs: atualiza README
refactor: reorganiza serviço de usuários
test: adiciona testes da API
chore: atualiza dependências
```

---

# 🔢 Versionamento

O projeto poderá utilizar versionamento semântico:

```text
MAJOR.MINOR.PATCH
```

Exemplo:

```text
1.0.0
```

### PATCH

Correções:

```text
1.0.0 → 1.0.1
```

### MINOR

Novas funcionalidades compatíveis:

```text
1.0.1 → 1.1.0
```

### MAJOR

Mudanças incompatíveis ou grandes versões:

```text
1.1.0 → 2.0.0
```

---

# 🪝 Git Hooks

O projeto também poderá utilizar Git Hooks para automatizar verificações relacionadas aos commits.

Alguns exemplos:

```text
pre-commit
commit-msg
post-commit
```

Esses scripts poderão ser utilizados para garantir padrões do projeto antes ou depois da criação de commits.

---

# 🗺️ Roadmap

## Etapa 1 - Planejamento

* [ ] Definir empresa fictícia
* [ ] Definir problema
* [ ] Definir público-alvo
* [ ] Definir funcionalidades
* [ ] Definir regras de negócio

## Etapa 2 - Modelagem

* [ ] Criar requisitos
* [ ] Identificar entidades
* [ ] Criar modelo do banco
* [ ] Definir relacionamentos
* [ ] Criar scripts SQL

## Etapa 3 - Backend

* [ ] Criar estrutura FastAPI
* [ ] Configurar PostgreSQL
* [ ] Configurar conexão com o banco
* [ ] Criar modelos
* [ ] Criar endpoints
* [ ] Criar validações
* [ ] Implementar regras de negócio
* [ ] Criar testes

## Etapa 4 - Frontend

* [ ] Criar projeto Flutter
* [ ] Definir identidade visual
* [ ] Criar componentes
* [ ] Criar telas
* [ ] Configurar rotas
* [ ] Integrar com FastAPI
* [ ] Criar validações

## Etapa 5 - Integração

* [ ] Integrar Flutter e FastAPI
* [ ] Testar operações CRUD
* [ ] Testar tratamento de erros
* [ ] Testar fluxo completo

## Etapa 6 - Publicação

* [ ] Gerar Flutter Web
* [ ] Preparar servidor Linux
* [ ] Configurar backend
* [ ] Configurar PostgreSQL
* [ ] Configurar Nginx
* [ ] Configurar variáveis de ambiente
* [ ] Publicar aplicação
* [ ] Realizar testes em produção

## Etapa 7 - Entrega

* [ ] Revisar código
* [ ] Revisar banco
* [ ] Revisar documentação
* [ ] Atualizar README
* [ ] Criar versão final
* [ ] Preparar apresentação

---

# 🧠 Mapa geral

```text
PROJETO SEMESTRAL
│
├── Planejamento
│   ├── Empresa
│   ├── Problema
│   ├── Público
│   ├── Requisitos
│   └── Regras de negócio
│
├── Frontend
│   ├── Flutter
│   ├── Dart
│   ├── Telas
│   ├── Componentes
│   └── API
│
├── Backend
│   ├── Python
│   ├── FastAPI
│   ├── Endpoints
│   ├── Validações
│   └── Regras
│
├── Banco
│   ├── PostgreSQL
│   ├── Tabelas
│   ├── Relacionamentos
│   └── DBeaver
│
├── Versionamento
│   ├── Git
│   ├── GitHub
│   ├── Commits
│   └── Git Hooks
│
└── Produção
    ├── Flutter Web
    ├── Linux
    ├── Nginx
    ├── FastAPI
    └── PostgreSQL
```

---

# 👨‍💻 Equipe

Projeto desenvolvido por estudantes da UNICIVE.

| Integrante | Responsabilidade |
| ---------- | ---------------- |
| A definir  | A definir        |
| A definir  | A definir        |
| A definir  | A definir        |

As responsabilidades serão preenchidas após a divisão das atividades do projeto.

---

# 🎓 Contexto acadêmico

Este sistema está sendo desenvolvido como **Projeto Semestral da UNICIVE**, com o objetivo de aplicar na prática conhecimentos relacionados a:

* desenvolvimento de software;
* programação frontend;
* programação backend;
* APIs REST;
* banco de dados;
* integração de sistemas;
* controle de versão;
* infraestrutura;
* documentação;
* trabalho em equipe.

---

# 📚 Documentação

A documentação do projeto deverá evoluir juntamente com o desenvolvimento.

O README não deve ser considerado estático.

Sempre que forem definidos novos requisitos, tecnologias, procedimentos de instalação ou mudanças importantes na arquitetura, este documento deverá ser atualizado.

---

## ⚠️ Observação

As regras de negócio, funcionalidades, público-alvo e empresa fictícia ainda estão em fase de definição.

As informações técnicas apresentadas neste documento representam a arquitetura planejada atualmente e poderão evoluir durante o desenvolvimento.

---

## 📄 Licença

Projeto acadêmico desenvolvido para fins educacionais.

A licença definitiva do repositório ainda será definida.
