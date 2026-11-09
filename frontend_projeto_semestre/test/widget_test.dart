import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend_projeto_semestre/app/app.dart';
import 'package:frontend_projeto_semestre/features/home/presentation/pages/login_screen.dart';
import 'package:frontend_projeto_semestre/features/home/presentation/pages/home_page.dart';

void main() {
  testWidgets('A aplicação inicia exibindo a tela de login', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const FaculdadeApp());

    await tester.pump();

    // Verifica se a aplicação iniciou.
    expect(find.byType(MaterialApp), findsOneWidget);

    // Verifica se a tela de login está presente.
    expect(find.byType(LoginScreen), findsOneWidget);

    // Verifica os campos do formulário de login.
    expect(find.byType(TextFormField), findsWidgets);
  });

  testWidgets('as etapas do informativo expandem e recolhem', (tester) async {
    tester.view.physicalSize = const Size(1440, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const MaterialApp(home: HomePage()));

    await tester.tap(find.text('Conheça a plataforma'));
    await tester.pumpAndSettle();

    const etapas = {
      '01 · Registro e triagem': 'O cliente abre a demanda',
      '02 · Atendimento e acompanhamento': 'Depois da atribuição',
      '03 · Validação da entrega': 'Quando a demanda chega à homologação',
    };
    for (final etapa in etapas.entries) {
      final titulo = find.text(etapa.key);
      final detalhes = find.textContaining(etapa.value);
      expect(detalhes, findsNothing);
      await tester.tap(titulo);
      await tester.pumpAndSettle();
      expect(detalhes, findsOneWidget);
      await tester.tap(titulo);
      await tester.pumpAndSettle();
      expect(detalhes, findsNothing);
    }
  });
}
