
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:frontend_projeto_semestre/features/demands/data/models/historico_estado_model.dart';
import 'package:frontend_projeto_semestre/features/demands/presentation/widgets/demand_history_timeline.dart';

void main() {
  Widget criarTela({
    required List<HistoricoEstadoModel> historico,
    bool carregando = false,
    String? erro,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: DemandHistoryTimeline(
            historico: historico,
            carregando: carregando,
            erro: erro,
          ),
        ),
      ),
    );
  }

  testWidgets('Exibe mensagem quando o historico esta vazio', (tester) async {
    await tester.pumpWidget(criarTela(historico: []));

    expect(find.text('Histórico de estados'), findsOneWidget);
    expect(
      find.text('Nenhuma alteração de estado registrada.'),
      findsOneWidget,
    );
  });

  testWidgets('Exibe historico em ordem cronologica', (tester) async {
    final historico = [
      HistoricoEstadoModel(
        estadoAnterior: 'EXECUCAO',
        novoEstado: 'HOMOLOGACAO',
        usuarioResponsavel: 'usuario-2',
        dataHora: DateTime(2026, 10, 18, 15, 30),
      ),
      HistoricoEstadoModel(
        estadoAnterior: null,
        novoEstado: 'ABERTA',
        usuarioResponsavel: 'usuario-1',
        dataHora: DateTime(2026, 10, 17, 10, 0),
      ),
    ];

    await tester.pumpWidget(criarTela(historico: historico));

    expect(find.text('Início → ABERTA'), findsOneWidget);
    expect(find.text('EXECUCAO → HOMOLOGACAO'), findsOneWidget);
    expect(find.text('usuario-1'), findsOneWidget);
    expect(find.text('usuario-2'), findsOneWidget);
    expect(find.text('17/10/2026 às 10:00'), findsOneWidget);
    expect(find.text('18/10/2026 às 15:30'), findsOneWidget);

    final primeiraTransicao = tester.getTopLeft(
      find.text('Início → ABERTA'),
    );
    final segundaTransicao = tester.getTopLeft(
      find.text('EXECUCAO → HOMOLOGACAO'),
    );

    expect(primeiraTransicao.dy, lessThan(segundaTransicao.dy));
  });

  testWidgets('Exibe erro quando informado', (tester) async {
    await tester.pumpWidget(
      criarTela(
        historico: [],
        erro: 'Não foi possível carregar o histórico.',
      ),
    );

    expect(
      find.text('Não foi possível carregar o histórico.'),
      findsOneWidget,
    );
  });

  testWidgets('Exibe carregamento quando solicitado', (tester) async {
    await tester.pumpWidget(
      criarTela(
        historico: [],
        carregando: true,
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}
