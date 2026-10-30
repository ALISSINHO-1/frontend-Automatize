import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend_projeto_semestre/features/admin/data/models/auditoria_model.dart';
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

  testWidgets('painel mostra erro da API', (tester) async {
    await tester.pumpWidget(_app(DemandAuditPanel(carregar: () async => throw Exception('HTTP 403'))));
    await tester.pumpAndSettle();

    expect(find.textContaining('Não foi possível carregar a auditoria'), findsOneWidget);
  });

  testWidgets('formulário valida campos e UUID do cliente', (tester) async {
    DemandFormResult? resultado;
    await tester.pumpWidget(MaterialApp(
      home: Builder(
        builder: (context) => TextButton(
          onPressed: () async => resultado = await DemandFormDialog.show(context),
          child: const Text('abrir'),
        ),
      ),
    ));
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Cadastrar'));
    await tester.pump();
    expect(find.text('Informe o título.'), findsOneWidget);

    final campos = find.byType(TextFormField);
    await tester.enterText(campos.at(0), 'Rede');
    await tester.enterText(campos.at(1), 'Configurar rede');
    await tester.enterText(campos.at(2), 'abc');
    await tester.tap(find.text('Cadastrar'));
    await tester.pump();
    expect(find.text('Identificador inválido (UUID).'), findsOneWidget);

    await tester.enterText(campos.at(2), '');
    await tester.tap(find.text('Cadastrar'));
    await tester.pump();
    expect(find.text('Informe o identificador.'), findsOneWidget);

    const cliente = '3f2c1b9a-8d7e-4c6b-9a1f-2e3d4c5b6a70';
    await tester.enterText(campos.at(2), cliente);
    await tester.tap(find.text('Cadastrar'));
    await tester.pumpAndSettle();

    expect(resultado?.titulo, 'Rede');
    expect(resultado?.clienteId, cliente);
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
