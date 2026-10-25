import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend_projeto_semestre/app/app.dart';

void main() {
  testWidgets('exibe o painel administrativo do AUTOMATIZE', (tester) async {
    await tester.pumpWidget(const FaculdadeApp());

    expect(find.text('AUTOMATIZE'), findsOneWidget);
    expect(find.text('Visão geral das demandas'), findsOneWidget);
    expect(find.text('Painel administrativo'), findsWidgets);
    expect(find.text('Planejamento'), findsOneWidget);
    expect(find.text('Execução'), findsOneWidget);
    expect(find.text('Homologação'), findsOneWidget);
    expect(find.text('Concluído'), findsOneWidget);
    expect(find.byType(FilledButton), findsOneWidget);
  });
}