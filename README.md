# Automatize - Frontend

Frontend da plataforma **Automatize**, projeto acadêmico desenvolvido utilizando **Flutter e Dart**.

A aplicação é responsável pela interação entre o usuário e os serviços disponibilizados pelo backend, oferecendo uma interface responsiva para consulta, cadastro, acompanhamento e gerenciamento das informações do sistema.

O frontend foi planejado para funcionar principalmente em ambiente **Web**, mantendo uma arquitetura compatível com outros dispositivos suportados pelo Flutter.

---

## Sobre o projeto

O **Automatize** é uma aplicação desenvolvida com o objetivo de centralizar processos operacionais e facilitar a interação entre usuários, serviços e informações da aplicação.

O frontend representa a camada visual do sistema e é responsável por apresentar os dados recebidos da API de maneira organizada, responsiva e acessível.

A comunicação com o backend ocorre através de uma **API REST**, utilizando requisições HTTP e dados no formato JSON.

---

## Responsabilidades do frontend

O frontend é responsável por:

- apresentar as interfaces do sistema;
- permitir interação com os usuários;
- realizar navegação entre telas;
- coletar dados através de formulários;
- realizar validações de interface;
- enviar requisições para a API;
- interpretar respostas do backend;
- apresentar mensagens de sucesso e erro;
- controlar estados de carregamento;
- exibir informações retornadas pela API;
- permitir envio de arquivos e anexos quando necessário;
- adaptar a interface para diferentes tamanhos de tela.

As regras críticas de negócio devem permanecer no backend.

---

## Tecnologias

O frontend utiliza:

- Flutter;
- Dart;
- Flutter Web;
- HTTP/HTTPS;
- JSON;
- REST API.

Outras dependências poderão ser adicionadas conforme a evolução do projeto.

---

## Arquitetura

A comunicação principal do sistema funciona da seguinte maneira:

```text
┌──────────────────────┐
│       Usuário        │
└──────────┬───────────┘
           │
           ▼
┌──────────────────────┐
│       Flutter        │
│       Frontend       │
│        Dart          │
└──────────┬───────────┘
           │
           │ HTTP / JSON
           ▼
┌──────────────────────┐
│       FastAPI        │
│       Backend        │
└──────────┬───────────┘
           │
           ▼
┌──────────────────────┐
│     PostgreSQL       │
│    Banco de dados    │
└──────────────────────┘
