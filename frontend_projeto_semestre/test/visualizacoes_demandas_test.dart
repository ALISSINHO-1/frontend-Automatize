import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend_projeto_semestre/features/home/presentation/pages/demanda_store.dart';
import 'package:frontend_projeto_semestre/features/home/presentation/pages/visualizacoes_demandas.dart';

void main() {
  const demanda = DemandaItem(
    id: '1',
    codigo: 'DEM-001',
    titulo: 'Integração com a API',
    descricao: 'Validar integração',
    estado: 'EXECUCAO',
    progresso: 50,
    responsavelId: 'tecnico-1',
  );

  Widget app(Widget child) => MaterialApp(
    theme: ThemeData.dark(),
    home: Scaffold(body: SizedBox(width: 1200, height: 760, child: child)),
  );

  testWidgets('quadro exibe colunas, demanda e progresso', (tester) async {
    await tester.pumpWidget(
      app(
        QuadroDemandas(
          demandas: const [demanda],
          estados: const [
            'Planejamento',
            'Execução',
            'Homologação',
            'Concluído',
          ],
          rotuloEstado: (estado) => switch (estado) {
            'EXECUCAO' => 'Execução',
            _ => estado,
          },
          corEstado: (_) => Colors.blue,
          abrir: (_) {},
        ),
      ),
    );

    expect(find.text('Planejamento'), findsOneWidget);
    expect(find.text('Integração com a API'), findsOneWidget);
    expect(find.text('DEM-001'), findsOneWidget);
    expect(find.text('Técnico atribuído'), findsOneWidget);
    expect(find.text('50,0%'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
  });

  testWidgets('calendário cabe em tela estreita e permite trocar de mês', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(280, 580));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      app(CalendarioDemandas(demandas: const [demanda], abrir: (_) {})),
    );

    expect(find.text('Dom'), findsOneWidget);
    expect(find.text('Seg'), findsOneWidget);
    expect(find.text('Sáb'), findsOneWidget);
    expect(find.text('Sem marcos registrados neste dia.'), findsOneWidget);
    final data = MaterialLocalizations.of(
      tester.element(find.byType(CalendarioDemandas)),
    ).formatCompactDate(DateTime.now());
    expect(find.text(data), findsOneWidget);

    await tester.tap(find.byTooltip('Próximo mês'));
    await tester.pumpAndSettle();

    expect(find.text(data), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
