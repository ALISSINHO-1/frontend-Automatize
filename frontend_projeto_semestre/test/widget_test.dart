import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend_projeto_semestre/app/app.dart';

void main() {
  testWidgets('exige login antes de exibir o dashboard', (tester) async {
    await tester.pumpWidget(const FaculdadeApp());
    await tester.pump();

    expect(find.text('AUTOMATIZE'), findsOneWidget);
    expect(find.text('Bem-vindo de volta!'), findsOneWidget);
    expect(find.byType(TextFormField), findsNWidgets(2));
    expect(find.text('Entrar na plataforma'), findsOneWidget);
    expect(find.text('Visão geral das demandas'), findsNothing);
    expect(find.text('Painel administrativo'), findsNothing);
  });
}
