import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend_projeto_semestre/app/routes/app_routes.dart';
import 'package:frontend_projeto_semestre/features/home/presentation/pages/home_page.dart';

void main() {
  testWidgets('botão principal da landing abre a rota de login', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: const HomePage(),
        routes: {
          AppRoutes.login: (_) => const Scaffold(body: Text('Rota de login')),
        },
      ),
    );

    await tester.tap(find.text('Entrar na plataforma'));
    await tester.pumpAndSettle();

    expect(find.text('Rota de login'), findsOneWidget);
  });

  test('painel e demandas estão registrados nas rotas da aplicação', () {
    expect(AppRoutes.routes, contains(AppRoutes.painel));
    expect(AppRoutes.routes, contains(AppRoutes.demandas));
    expect(AppRoutes.routes, contains(AppRoutes.comercial));
    expect(AppRoutes.demandas, isNot(AppRoutes.home));
  });
}
