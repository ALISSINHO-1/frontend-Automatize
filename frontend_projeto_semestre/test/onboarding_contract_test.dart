import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend_projeto_semestre/app/routes/app_routes.dart';
import 'package:frontend_projeto_semestre/features/onboarding/presentation/pages/ambientes_screen.dart';
import 'package:frontend_projeto_semestre/features/onboarding/presentation/pages/cadastro_screen.dart';

void main() {
  testWidgets('cadastro consulta a API antes de solicitar dados pessoais', (tester) async {
    var chamadas = 0;
    final client = MockClient((request) async {
      chamadas++;
      expect(request.method, 'GET');
      expect(request.url.path, '/auth/conta/config');
      return http.Response(
        '{"cadastro_habilitado":false,"recuperacao_habilitada":false,"turnstile_site_key":""}', 200,
      );
    });
    addTearDown(client.close);
    await tester.pumpWidget(MaterialApp(
      home: CadastroScreen(client: client),
      routes: {
        AppRoutes.login: (_) => const Scaffold(body: Text('Login Automatize')),
      },
    ));
    await tester.pumpAndSettle();
    expect(chamadas, 1);
    expect(find.text('Não foi possível abrir o cadastro'), findsOneWidget);
    expect(find.byType(TextFormField), findsNothing);
    expect(find.text('Solicitar minha conta'), findsNothing);
    await tester.tap(find.text('Ir para o login'));
    await tester.pumpAndSettle();
    expect(find.text('Login Automatize'), findsOneWidget);
  });

  testWidgets('cadastro livre mostra formulario quando a API esta pronta', (tester) async {
    final client = MockClient((request) async {
      expect(request.url.path, '/auth/conta/config');
      return http.Response(
        '{"cadastro_habilitado":true,"recuperacao_habilitada":false,"turnstile_site_key":"sitekey-publica"}',
        200,
      );
    });
    addTearDown(client.close);
    await tester.pumpWidget(MaterialApp(
      home: CadastroScreen(client: client),
      routes: {
        AppRoutes.termosUso: AppRoutes.routes[AppRoutes.termosUso]!,
        AppRoutes.politicaPrivacidade: AppRoutes.routes[AppRoutes.politicaPrivacidade]!,
      },
    ));
    await tester.pumpAndSettle();
    expect(find.text('Criar minha conta'), findsOneWidget);
    expect(find.byType(TextFormField), findsNWidgets(4));
    expect(find.text('Ler os Termos de Uso'), findsOneWidget);
    expect(find.text('Ler a Política de Privacidade'), findsOneWidget);
    expect(find.text('Solicitar minha conta'), findsNothing);
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
