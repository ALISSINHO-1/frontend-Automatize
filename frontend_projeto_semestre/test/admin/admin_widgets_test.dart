import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend_projeto_semestre/features/admin/data/models/auditoria_model.dart';
import 'package:frontend_projeto_semestre/features/admin/data/models/usuario_model.dart';
import 'package:frontend_projeto_semestre/features/admin/presentation/widgets/admin_demand_dialogs.dart';
import 'package:frontend_projeto_semestre/features/admin/presentation/widgets/demand_audit_panel.dart';

Widget _app(Widget filho) => MaterialApp(home: Scaffold(body: SingleChildScrollView(child: filho)));

void main() {
  testWidgets('painel separa evidências do registro de ações', (tester) async {
    await tester.pumpWidget(_app(DemandAuditPanel(
      carregar: () async => [
        AuditoriaModel(
          id: '1',
          acao: 'ENVIO_EVIDENCIA',
          detalhes: const {'nome_arquivo': 'laudo.pdf', 'tamanho_bytes': 2048},
          createdAt: DateTime(2026, 10, 2, 9, 5),
        ),
        const AuditoriaModel(id: '2', acao: 'ATRIBUICAO_RESPONSAVEL'),
      ],
    )));
    await tester.pumpAndSettle();

    expect(find.text('Evidências (1)'), findsOneWidget);
    expect(find.text('laudo.pdf'), findsOneWidget);
    expect(find.text('2.0 KB · 02/10/2026 09:05'), findsOneWidget);
    expect(find.text('Registro de ações (2)'), findsOneWidget);
    expect(find.text('Técnico atribuído'), findsOneWidget);
  });

  testWidgets('auditoria mostra autor pelo nome, troca de técnico e o motivo', (tester) async {
    await tester.pumpWidget(_app(DemandAuditPanel(
      nomes: const {'a1': 'Ana Admin'},
      carregar: () async => const [
        AuditoriaModel(
          id: '1',
          usuarioId: 'a1',
          acao: 'ATRIBUICAO_RESPONSAVEL',
          detalhes: {'responsavel_anterior': 't1', 'responsavel_novo': 't2', 'motivo': 'Tiago de férias'},
        ),
        AuditoriaModel(
          id: '2',
          usuarioId: 'x9',
          acao: 'RESOLUCAO_OCORRENCIA',
          detalhes: {'descricao_resolucao': 'Botão corrigido'},
        ),
      ],
    )));
    await tester.pumpAndSettle();

    expect(find.text('Técnico trocado'), findsOneWidget);
    expect(find.text('por Ana Admin'), findsOneWidget);
    expect(find.text('"Tiago de férias"'), findsOneWidget);
    expect(find.text('Ocorrência resolvida'), findsOneWidget);
    // Autor fora da lista de usuários: cai no UUID.
    expect(find.text('por x9'), findsOneWidget);
    expect(find.text('"Botão corrigido"'), findsOneWidget);
  });

  testWidgets('painel mostra erro da API', (tester) async {
    await tester.pumpWidget(_app(DemandAuditPanel(carregar: () async => throw Exception('HTTP 403'))));
    await tester.pumpAndSettle();

    expect(find.textContaining('Não foi possível carregar a auditoria'), findsOneWidget);
  });

  testWidgets('formulário valida campos e exige escolher o cliente', (tester) async {
    DemandFormResult? resultado;
    const clientes = [
      UsuarioModel(id: 'c1', nome: 'Carla', email: 'carla@x.dev', perfil: 'CLIENTE'),
    ];
    await tester.pumpWidget(MaterialApp(
      home: Builder(
        builder: (context) => TextButton(
          onPressed: () async =>
              resultado = await DemandFormDialog.show(context, clientes: clientes),
          child: const Text('abrir'),
        ),
      ),
    ));
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Cadastrar'));
    await tester.pump();
    expect(find.text('Informe o título.'), findsOneWidget);
    expect(find.text('Selecione o cliente.'), findsOneWidget);

    final campos = find.byType(TextFormField);
    await tester.enterText(campos.at(0), 'Rede');
    await tester.enterText(campos.at(1), 'Configurar rede');
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Carla · carla@x.dev').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cadastrar'));
    await tester.pumpAndSettle();

    expect(resultado?.titulo, 'Rede');
    expect(resultado?.clienteId, 'c1');
  });

  testWidgets('sem cliente ativo o cadastro fica desabilitado', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Builder(
        builder: (context) => TextButton(
          onPressed: () => DemandFormDialog.show(context),
          child: const Text('abrir'),
        ),
      ),
    ));
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Nenhum cliente ativo'), findsOneWidget);
    final botao = tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'Cadastrar'));
    expect(botao.onPressed, isNull);
  });

  testWidgets('primeira atribuição não pede motivo', (tester) async {
    AtribuicaoResult? resultado;
    const tecnicos = [UsuarioModel(id: 't1', nome: 'Tiago', perfil: 'TECNICO')];
    await tester.pumpWidget(MaterialApp(
      home: Builder(
        builder: (context) => TextButton(
          onPressed: () async =>
              resultado = await AssignTechnicianDialog.show(context, tecnicos: tecnicos),
          child: const Text('abrir'),
        ),
      ),
    ));
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();

    expect(find.text('Atribuir técnico'), findsOneWidget);
    expect(find.byType(TextFormField), findsNothing);
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tiago').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Atribuir'));
    await tester.pumpAndSettle();

    expect(resultado?.responsavelId, 't1');
    expect(resultado?.motivo, isNull);
  });

  testWidgets('edição não pede cliente', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Builder(
        builder: (context) => TextButton(
          onPressed: () => DemandFormDialog.show(context, tituloInicial: 'T', descricaoInicial: 'D'),
          child: const Text('abrir'),
        ),
      ),
    ));
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();

    expect(find.text('Editar demanda'), findsOneWidget);
    expect(find.byType(TextFormField), findsNWidgets(2));
  });
}
