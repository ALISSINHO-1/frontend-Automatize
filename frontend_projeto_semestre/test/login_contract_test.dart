import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:frontend_projeto_semestre/app/routes/app_routes.dart';
import 'package:frontend_projeto_semestre/core/auth/auth_guard.dart';
import 'package:frontend_projeto_semestre/core/storage/local_storage_service.dart';
import 'package:frontend_projeto_semestre/features/home/presentation/pages/login_screen.dart';

void main() {
  setUp(LocalStorageService.removeToken);
  tearDown(LocalStorageService.removeToken);

  Future<void> submit(WidgetTester tester, http.Client client) async {
    tester.view.physicalSize = const Size(1280, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        home: LoginScreen(client: client),
        routes: {
          AppRoutes.painel: (_) =>
              const Scaffold(body: Text('Área autenticada')),
          AppRoutes.cadastroPendente: (_) =>
              const Scaffold(body: Text('Cadastro pendente')),
          AppRoutes.admin: (_) =>
              const Scaffold(body: Text('Área administrativa')),
          AppRoutes.tecnico: (_) =>
              const Scaffold(body: Text('Área técnica')),
        },
      ),
    );
    await tester.enterText(
      find.byType(TextFormField).at(0),
      'cliente@example.com',
    );
    await tester.enterText(find.byType(TextFormField).at(1), 'senha-de-teste');
    await tester.ensureVisible(find.text('Entrar na plataforma'));
    await tester.tap(find.text('Entrar na plataforma'));
    await tester.pumpAndSettle();
  }

  testWidgets('login usa o contrato da FastAPI e só navega após token válido', (
    tester,
  ) async {
    final client = MockClient((request) async {
      if (request.method == 'POST') {
        expect(request.url.path, '/auth/login');
        expect(request.headers.containsKey('Authorization'), isFalse);
        expect(jsonDecode(request.body), {
          'email': 'cliente@example.com',
          'senha': 'senha-de-teste',
        });
        return http.Response(
          '{"access_token":"jwt-teste","token_type":"bearer"}',
          200,
        );
      }
      expect(request.method, 'GET');
      expect(request.url.path, '/auth/contexto');
      expect(request.headers['Authorization'], 'Bearer jwt-teste');
      return http.Response(
        '{"perfil":"CLIENTE","situacao_cadastro":"ATIVO","ambientes":[]}',
        200,
      );
    });
    addTearDown(client.close);
    await submit(tester, client);
    expect(await LocalStorageService.getToken(), 'jwt-teste');
    expect(find.text('Área autenticada'), findsOneWidget);
    expect(find.byType(LoginScreen), findsNothing);
  });

  testWidgets('conta pendente nunca abre painel operacional', (tester) async {
    final client = MockClient((request) async {
      if (request.url.path == '/auth/login') {
        return http.Response(
          '{"access_token":"jwt-pendente","token_type":"bearer"}', 200);
      }
      expect(request.url.path, '/auth/contexto');
      return http.Response(
        '{"perfil":"CLIENTE","situacao_cadastro":"PENDENTE","ambientes":[]}', 200);
    });
    addTearDown(client.close);
    await submit(tester, client);
    expect(find.text('Cadastro pendente'), findsOneWidget);
    expect(find.text('Área autenticada'), findsNothing);
  });

  for (final response in [
    http.Response('{}', 401),
    http.Response('{}', 422),
    http.Response('{"token":"campo-nao-contratado"}', 200),
    http.Response('{"access_token":" "}', 200),
  ]) {
    testWidgets(
      'login rejeitado ou sem access_token não mantém sessão (${response.statusCode}: ${response.body})',
      (tester) async {
        await LocalStorageService.saveToken('sessao-antiga');
        final client = MockClient((_) async => response);
        addTearDown(client.close);
        await submit(tester, client);
        expect(await LocalStorageService.getToken(), isNull);
        expect(find.byType(LoginScreen), findsOneWidget);
        expect(find.text('Área autenticada'), findsNothing);
      },
    );
  }

  testWidgets('rota direta sem sessão volta ao login e remove tela protegida', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: const AuthGuard(child: Scaffold(body: Text('Tela privada'))),
        routes: {'/login': (_) => const LoginScreen()},
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.text('Tela privada'), findsNothing);
  });
}
