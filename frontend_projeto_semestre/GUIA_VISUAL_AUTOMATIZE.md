# GUIA VISUAL E PADRÕES DE FRONTEND
## AUTOMATIZE

**Projeto:** AUTOMATIZE  
**Tecnologia:** Flutter / Dart  
**Identidade visual:** Dashboard administrativo, tema escuro  
**Referência:** Redesign visual desenvolvido na branch `feat/redesign-visual`

---

## 1. Objetivo

Este documento estabelece os padrões visuais e de implementação do frontend do AUTOMATIZE.

Todas as novas telas devem manter consistência com a identidade visual existente, reutilizando cores, componentes e estruturas de navegação sempre que possível.

O objetivo é permitir que diferentes desenvolvedores trabalhem no projeto sem criar interfaces visualmente incompatíveis.

## 2. Identidade visual

O AUTOMATIZE utiliza uma identidade visual moderna, baseada em:

- Fundo escuro em tons de azul-marinho.
- Roxo como cor principal de destaque.
- Ciano, verde e âmbar como cores secundárias e de status.
- Cards com cantos arredondados.
- Bordas discretas.
- Textos claros, com hierarquia visual definida.
- Interações suaves ao passar o mouse.

As telas devem priorizar legibilidade, organização e consistência.

## 3. Paleta de cores oficial

As cores estão centralizadas em:

`lib/core/theme/redesign_colors.dart`

| Propriedade | Cor hexadecimal | Utilização |
|---|---|---|
| `background` | `#0C1020` | Fundo principal |
| `sidebar` | `#10162B` | Menu lateral |
| `card` | `#171D32` | Cards e superfícies |
| `purple` | `#7667F5` | Destaques e ações principais |
| `cyan` | `#35C8F5` | Informações e indicadores |
| `amber` | `#F2AE60` | Atenção e homologação |
| `green` | `#34D5AE` | Conclusão e sucesso |
| `textPrimary` | `#E7E9FF` | Textos principais |
| `textSecondary` | `#A7AEC8` | Textos secundários |
| `border` | `#303956` | Bordas e divisórias |

**Regra:** não utilizar valores hexadecimais diretamente nas novas telas quando já existir uma cor equivalente em `RedesignColors`.

Exemplo:

```dart
Container(
  color: RedesignColors.card,
  child: const Text(
    'AUTOMATIZE',
    style: TextStyle(
      color: RedesignColors.textPrimary,
    ),
  ),
)
```

## 4. Estrutura geral do layout

O frontend utiliza um layout administrativo compartilhado, composto por:

1. Sidebar lateral.
2. Barra superior.
3. Área principal de conteúdo.

O layout está implementado em:

`lib/features/home/presentation/widgets/admin_layout.dart`

A sidebar está em:

`lib/features/home/presentation/widgets/admin_sidebar.dart`

**Regra importante:** novas páginas não devem recriar manualmente a sidebar ou a barra superior.

Esses elementos são compartilhados pelo aplicativo.

A estrutura atual utiliza uma sidebar fixa em larguras de tela a partir de 900 pixels. Abaixo disso, a sidebar não é exibida. Essa condição não deve ser alterada sem uma revisão de responsividade.

## 5. Navegação

As rotas nomeadas do aplicativo estão centralizadas em:

`lib/app/routes/app_routes.dart`

Rotas existentes:

| Rota | Finalidade |
|---|---|
| `/` | Visão geral |
| `/demand-list` | Listagem de demandas |
| `/demand-history` | Histórico geral |
| `/demand-attachments` | Central de anexos |
| `/demand-details` | Detalhes de uma demanda |

**Ao criar uma nova tela:**

- Registrar a rota quando ela precisar de navegação nomeada.
- Preservar as rotas existentes.
- Utilizar o `Navigator` do Flutter.
- Não criar uma segunda sidebar.
- Não substituir a configuração global do aplicativo.

A navegação da sidebar utiliza o `adminNavigatorKey` e o `adminNavigationController`.

Não modificar esses elementos sem avaliar o impacto sobre as demais páginas.

## 6. Padrão de páginas

As páginas devem utilizar o fundo oficial e manter espaçamento consistente.

Exemplo de estrutura:

```dart
Scaffold(
  backgroundColor: RedesignColors.background,
  body: SafeArea(
    child: SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        24, 28, 24, 48,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: 1100,
          ),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              // Conteúdo da página.
            ],
          ),
        ),
      ),
    ),
  ),
)
```

Essa estrutura é uma referência, não uma exigência para todas as telas. Páginas com listas extensas podem utilizar `ListView` e `Expanded`, desde que respeitem as restrições de layout.

## 7. Tipografia

O projeto utiliza a tipografia configurada no tema Flutter.

Referências de tamanho:

| Elemento | Tamanho recomendado |
|---|---|
| Título principal | 26–28 px |
| Título de seção | 17–20 px |
| Texto principal | 14–15 px |
| Texto secundário | 12–14 px |
| Rótulos pequenos | 10–11 px |

Utilizar:

- `RedesignColors.textPrimary` para informações principais.
- `RedesignColors.textSecondary` para descrições e informações auxiliares.
- `FontWeight.bold` ou `FontWeight.w600` para títulos e destaques.

Evitar misturar muitas fontes, tamanhos e pesos na mesma tela.

## 8. Cards e containers

Os cards são elementos centrais do redesign.

Padrão recomendado:

```dart
Container(
  padding: const EdgeInsets.all(24),
  decoration: BoxDecoration(
    color: RedesignColors.card,
    borderRadius: BorderRadius.circular(16),
    border: Border.all(
      color: RedesignColors.border,
    ),
  ),
  child: const Text(
    'Conteúdo do card',
    style: TextStyle(
      color: RedesignColors.textPrimary,
    ),
  ),
)
```

Referências:

- Cantos arredondados entre 12 e 16 px.
- Bordas discretas.
- Espaçamento interno entre 16 e 26 px.
- Separação consistente entre cards.

Evitar sombras excessivas, cores muito saturadas e efeitos que prejudiquem a leitura.

## 9. Botões e interações

Ações principais devem utilizar a cor roxa oficial.

Exemplo:

```dart
FilledButton.icon(
  onPressed: () {},
  icon: const Icon(Icons.add_rounded),
  label: const Text('Nova ação'),
  style: FilledButton.styleFrom(
    backgroundColor: RedesignColors.purple,
    foregroundColor: Colors.white,
    padding: const EdgeInsets.symmetric(
      horizontal: 20,
      vertical: 15,
    ),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(11),
    ),
  ),
)
```

Recomendações:

- Utilizar textos objetivos nos botões.
- Priorizar ícones do Material Design.
- Manter áreas clicáveis confortáveis.
- Utilizar efeitos de hover discretos em componentes interativos.
- Não apresentar uma ação como funcional quando ela ainda não estiver implementada.

## 10. Espaçamentos

Referências de espaçamento:

| Situação | Espaçamento |
|---|---|
| Entre ícone e texto | 8–12 px |
| Entre elementos relacionados | 8–16 px |
| Entre cards | 12–22 px |
| Entre seções | 24–32 px |
| Padding principal | 24 px |
| Padding interno de cards | 16–26 px |

Os valores podem variar conforme a necessidade, desde que mantenham uma composição visual consistente.

## 11. Status e indicadores

As cores devem representar significados consistentes.

| Status | Cor recomendada |
|---|---|
| Planejamento | Roxo |
| Execução | Ciano |
| Homologação | Âmbar |
| Concluído | Verde |

Referência de implementação:

`lib/features/demands/presentation/pages/demand_details_page.dart`

Novos status devem ser avaliados antes da escolha de cores adicionais.

## 12. Pesquisa e filtros

A pesquisa global da barra superior está atualmente associada à listagem de demandas.

Arquivos relacionados:

- `admin_layout.dart`
- `admin_search_controller.dart`
- `demand_list_page.dart`

**Regra:** não reutilizar a pesquisa de demandas para outras telas sem implementar o comportamento correspondente.

Os filtros devem manter a mesma identidade visual e oferecer feedback claro sobre a seleção ativa.

## 13. Anexos

O aplicativo possui dois níveis de navegação para anexos.

**Central de Anexos**

`demand_attachments_hub_page.dart`

Permite selecionar uma demanda e acessar diretamente seus anexos.

**Anexos da Demanda**

`demand_attachments_page.dart`

Permite selecionar arquivos localmente e realizar validações demonstrativas.

O parâmetro `fromAttachmentsHub` identifica se a tela foi acessada pela Central, ajustando o texto do botão de retorno.

**Limitação atual:** os arquivos selecionados não são persistidos nem enviados para a API. A interface não deve apresentar arquivos como enviados ou salvos sem integração real.

## 14. Dados e integração

O frontend utiliza dados demonstrativos em partes do sistema.

Referência:

`lib/features/demands/data/mock/demand_mock_data.dart`

Regras:

- Não apresentar dados fictícios como dados reais.
- Não alterar contratos da API apenas para adaptar o layout.
- Preservar os modelos de dados existentes.
- Separar alterações visuais de mudanças de regras de negócio.
- Manter mensagens claras quando uma funcionalidade depender de integração futura.

## 15. Organização dos arquivos

A estrutura do projeto separa responsabilidades por funcionalidade.

Exemplo:

```text
lib/
├── app/
│   ├── app.dart
│   └── routes/
│       └── app_routes.dart
├── core/
│   └── theme/
│       └── redesign_colors.dart
└── features/
    ├── home/
    │   └── presentation/
    │       ├── pages/
    │       └── widgets/
    └── demands/
        ├── data/
        │   ├── mock/
        │   └── models/
        └── presentation/
            ├── pages/
            └── widgets/
```

Manter novas telas e componentes nos diretórios correspondentes às suas funcionalidades.

Componentes reutilizáveis devem ser separados quando isso reduzir duplicação e facilitar manutenção.

## 16. Responsividade

As telas devem evitar larguras rígidas que provoquem overflow.

Recomendações:

- Utilizar `Expanded` e `Flexible` quando apropriado.
- Utilizar `Wrap` para grupos de elementos que precisem quebrar linha.
- Utilizar `ConstrainedBox` para limitar a largura máxima.
- Verificar o comportamento de textos longos.
- Testar diferentes tamanhos de janela.

A ausência da sidebar em telas abaixo de 900 px é uma característica da implementação atual, não uma solução completa de navegação mobile.

## 17. Checklist para novas telas

Antes de considerar uma tela pronta:

- [ ] Utiliza `RedesignColors`.
- [ ] Mantém a identidade escura do AUTOMATIZE.
- [ ] Respeita o layout compartilhado.
- [ ] Não duplica sidebar ou topbar.
- [ ] Possui títulos e espaçamentos consistentes.
- [ ] Mantém navegação e botões funcionais.
- [ ] Preserva dados, modelos e contratos existentes.
- [ ] Não apresenta funcionalidades demonstrativas como integrações reais.
- [ ] Não apresenta overflow visível.
- [ ] Passa no comando `flutter analyze`.
- [ ] Foi testada no navegador.

## 18. Fluxo de colaboração

O redesign foi desenvolvido na branch:

`feat/redesign-visual`

As próximas implementações devem seguir o fluxo de branches e revisão definido pela equipe.

Recomendações:

1. Atualizar a base de trabalho conforme orientação do responsável pelo repositório.
2. Desenvolver novas funcionalidades em branches próprias.
3. Seguir os padrões deste documento.
4. Executar `flutter analyze`.
5. Testar as funcionalidades alteradas.
6. Abrir Pull Request para revisão.
7. Evitar alterações diretas na branch principal sem aprovação.

---

**AUTOMATIZE — Guia Visual de Frontend**

Este documento representa os padrões observados e recomendados para o redesign atual. Deve ser atualizado conforme novos componentes, funcionalidades e decisões da equipe forem incorporados ao projeto.
