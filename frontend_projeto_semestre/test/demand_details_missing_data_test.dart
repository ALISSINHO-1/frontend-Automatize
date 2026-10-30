import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend_projeto_semestre/features/demands/presentation/pages/demand_details_page.dart';

void main() {
  testWidgets('detalhes sem pedido não abrem anexos com valor nulo', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: DemandDetailsPage(demandId: 'sem-dados'),
    ));
    final anexos = find.widgetWithText(FilledButton, 'Abrir anexos');
    await tester.ensureVisible(anexos);
    expect(tester.widget<FilledButton>(anexos).onPressed, isNull);
    expect(tester.takeException(), isNull);
  });
}
