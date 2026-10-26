import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend_projeto_semestre/app/app.dart';

void main() {
  testWidgets(
    'A aplicação inicia exibindo a tela de login',
    (WidgetTester tester) async {
      await tester.pumpWidget(const FaculdadeApp());

      await tester.pump();

      // Verifica se a aplicação iniciou corretamente.
      expect(
        find.byType(MaterialApp),
        findsOneWidget,
      );

      // Verifica se existem campos de entrada no login.
      expect(
        find.byType(TextFormField),
        findsWidgets,
      );
    },
  );
}
