import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend_projeto_semestre/app/routes/app_routes.dart';
import 'package:frontend_projeto_semestre/features/onboarding/presentation/pages/ambientes_screen.dart';
import 'package:frontend_projeto_semestre/features/onboarding/presentation/pages/cadastro_screen.dart';

void main() {
  testWidgets('cadastro abre os termos sem marcar o aceite', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: const CadastroScreen(),
      routes: AppRoutes.routes,
    ));
    final checkbox = find.byType(CheckboxListTile);
    expect(tester.widget<CheckboxListTile>(checkbox).value, isFalse);

    final link = find.text('Ler os Termos de Uso');
    await tester.ensureVisible(link);
    await tester.tap(link);
    await tester.pumpAndSettle();
    expect(find.text('AUTOMATIZE  /  VERSÃO 1.0'), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(tester.widget<CheckboxListTile>(checkbox).value, isFalse);
  });

  testWidgets('cadastro nao e habilitado sem configuracao explicita', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: CadastroScreen()));
    await tester.enterText(find.byType(TextFormField).at(0), 'Pessoa de Teste');
    await tester.enterText(find.byType(TextFormField).at(1), 'pessoa@example.com');
    await tester.enterText(find.byType(TextFormField).at(2), 'senhaSegura123');
    await tester.enterText(find.byType(TextFormField).at(3), 'senhaSegura123');
    await tester.ensureVisible(find.text('Solicitar minha conta'));
    await tester.tap(find.text('Solicitar minha conta'));
    await tester.pumpAndSettle();
    expect(find.text('Cadastro indisponível no momento.'), findsOneWidget);
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
