import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend_projeto_semestre/app/routes/app_routes.dart';
import 'package:frontend_projeto_semestre/features/home/presentation/pages/home_page.dart';

void main() {
  testWidgets('atalho de demandas usa uma rota própria', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: const HomePage(),
        routes: {
          AppRoutes.demandas: (_) =>
              const Scaffold(body: Text('Rota de demandas')),
        },
      ),
    );

    await tester.tap(find.text('Ver lista de demandas'));
    await tester.pumpAndSettle();

    expect(find.text('Rota de demandas'), findsOneWidget);
  });

  test('painel e demandas estão registrados nas rotas da aplicação', () {
    expect(AppRoutes.routes, contains(AppRoutes.painel));
    expect(AppRoutes.routes, contains(AppRoutes.demandas));
    expect(AppRoutes.demandas, isNot(AppRoutes.home));
  });
}
