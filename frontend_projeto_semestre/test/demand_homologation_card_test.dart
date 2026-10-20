
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend_projeto_semestre/features/demands/presentation/widgets/demand_homologation_card.dart';

void main() {
  testWidgets('Exibe homologação quando a demanda está em homologação',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: DemandHomologationCard(
            status: 'HOMOLOGACAO',
          ),
        ),
      ),
    );

    expect(find.text('Homologação da demanda'), findsOneWidget);
    expect(find.text('Aprovar'), findsOneWidget);
    expect(find.text('Reprovar'), findsOneWidget);
  });

  testWidgets('Oculta homologação quando a demanda está em execução',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: DemandHomologationCard(
            status: 'EXECUCAO',
          ),
        ),
      ),
    );

    expect(find.text('Homologação da demanda'), findsNothing);
    expect(find.text('Aprovar'), findsNothing);
    expect(find.text('Reprovar'), findsNothing);
  });

  testWidgets('Mantém ações desabilitadas sem integração',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: DemandHomologationCard(
            status: 'HOMOLOGACAO',
          ),
        ),
      ),
    );

    final aprovar = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Aprovar'),
    );

    final reprovar = tester.widget<OutlinedButton>(
      find.widgetWithText(OutlinedButton, 'Reprovar'),
    );

    expect(aprovar.onPressed, isNull);
    expect(reprovar.onPressed, isNull);
  });
}
