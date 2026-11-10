import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend_projeto_semestre/app/routes/app_routes.dart';
import 'package:frontend_projeto_semestre/features/onboarding/presentation/pages/ambientes_screen.dart';
import 'package:frontend_projeto_semestre/features/onboarding/presentation/pages/cadastro_screen.dart';

void main() {
  testWidgets('cadastro desabilitado nao solicita dados pessoais', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: const CadastroScreen(),
      routes: {
        AppRoutes.login: (_) => const Scaffold(body: Text('Login Automatize')),
      },
    ));

    expect(find.text('Novos cadastros indisponíveis'), findsOneWidget);
    expect(find.byType(TextFormField), findsNothing);
    expect(find.byType(CheckboxListTile), findsNothing);
    expect(find.text('Solicitar minha conta'), findsNothing);

    await tester.tap(find.text('Ir para o login'));
    await tester.pumpAndSettle();
    expect(find.text('Login Automatize'), findsOneWidget);
  });

  testWidgets('empresa saas aparece sem abrir painel dev/empresa', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: AmbientesScreen(contexto: {
        'ambientes': [
          {'tipo': 'SAAS', 'nome': 'Empresa Alfa', 'papel': 'GESTOR'}
        ],
      }),
      routes: {
        AppRoutes.painel: (_) =>
            const Scaffold(body: Text('Painel DEV')),
      },
    ));
    expect(find.text('Empresa Alfa'), findsOneWidget);
    expect(find.text('Em preparação'), findsOneWidget);
    expect(find.text('Painel DEV'), findsNothing);
  });
}
