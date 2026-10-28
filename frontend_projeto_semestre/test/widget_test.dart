import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend_projeto_semestre/app/app.dart';
import 'package:frontend_projeto_semestre/features/home/presentation/pages/login_screen.dart';

void main() {
  testWidgets(
    'A aplicação inicia exibindo a tela de login',
    (WidgetTester tester) async {
      await tester.pumpWidget(const FaculdadeApp());

      await tester.pump();

      // Verifica se a aplicação iniciou.
      expect(
        find.byType(MaterialApp),
        findsOneWidget,
      );

      // Verifica se a tela de login está presente.
      expect(
        find.byType(LoginScreen),
        findsOneWidget,
      );

      // Verifica os campos do formulário de login.
      expect(
        find.byType(TextFormField),
        findsWidgets,
      );
    },
  );
}
