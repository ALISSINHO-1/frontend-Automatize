import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:frontend_projeto_semestre/core/auth/auth_guard.dart';
import 'package:frontend_projeto_semestre/core/auth/current_user_session.dart';
import 'package:frontend_projeto_semestre/core/storage/local_storage_service.dart';
import 'package:frontend_projeto_semestre/features/home/presentation/pages/login_screen.dart';

void main() {
  setUp(() async {
    await LocalStorageService.removeToken();
    currentUserSession.clear();
  });

  tearDown(() async {
    await LocalStorageService.removeToken();
    currentUserSession.clear();
  });

  Future<void> submit(WidgetTester tester, http.Client client) async {
    tester.view.physicalSize = const Size(1280, 1000);
    tester.view.devicePixelRatio = 1;

    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: LoginScreen(client: client),
        routes: {
          '/home': (_) => const Scaffold(body: Text('Área autenticada')),
          '/tecnico': (_) => const Scaffold(body: Text('Área técnica')),
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

  testWidgets('login consulta /auth/me, salva token e navega como cliente', (
    tester,
  ) async {
    final requisicoes = <String>[];

    final client = MockClient((request) async {
      requisicoes.add('${request.method} ${request.url.path}');

      if (request.url.path == '/auth/login') {
        expect(request.method, 'POST');

        expect(request.headers.containsKey('Authorization'), isFalse);

        expect(jsonDecode(request.body), {
          'email': 'cliente@example.com',
          'senha': 'senha-de-teste',
        });

        return http.Response(
          jsonEncode({'access_token': 'jwt-teste', 'token_type': 'bearer'}),
          200,
        );
      }

      if (request.url.path == '/auth/me') {
        expect(request.method, 'GET');

        expect(request.headers['Authorization'], 'Bearer jwt-teste');

        return http.Response(
          jsonEncode({
            'id': 'cliente-123',
            'perfil': 'CLIENTE',
            'nome': 'Cliente Teste',
            'email': 'cliente@example.com',
          }),
          200,
        );
      }

      return http.Response('{}', 404);
    });

    addTearDown(client.close);

    await submit(tester, client);

    expect(requisicoes, ['POST /auth/login', 'GET /auth/me']);

    expect(await LocalStorageService.getToken(), 'jwt-teste');

    expect(find.text('Área autenticada'), findsOneWidget);

    expect(find.byType(LoginScreen), findsNothing);
  });

  testWidgets('técnico autenticado é direcionado para sua área', (
    tester,
  ) async {
    final requisicoes = <String>[];

    final client = MockClient((request) async {
      requisicoes.add('${request.method} ${request.url.path}');

      if (request.url.path == '/auth/login') {
        expect(request.method, 'POST');

        return http.Response(
          jsonEncode({'access_token': 'jwt-tecnico', 'token_type': 'bearer'}),
          200,
        );
      }

      if (request.url.path == '/auth/me') {
        expect(request.method, 'GET');

        expect(request.headers['Authorization'], 'Bearer jwt-tecnico');

        return http.Response(
  jsonEncode({
    'id': 'tecnico-123',
    'perfil': 'TECNICO',
    'nome': 'Técnico Teste',
  }),
  200,
  headers: {
    'content-type': 'application/json; charset=utf-8',
  },
);      }

      return http.Response('{}', 404);
    });

    addTearDown(client.close);

    await submit(tester, client);

    expect(requisicoes, [
      'POST /auth/login',
      'GET /auth/me',
    ], reason: 'O login deve consultar o perfil do técnico.');

    expect(await LocalStorageService.getToken(), 'jwt-tecnico');

    expect(find.text('Área técnica'), findsOneWidget);

    expect(find.byType(LoginScreen), findsNothing);
  });

  for (final response in [
    http.Response('{}', 401),
    http.Response('{}', 422),
    http.Response('{"token":"campo-nao-contratado"}', 200),
    http.Response('{"access_token":" "}', 200),
  ]) {
    testWidgets('login inválido não mantém sessão '
        '(${response.statusCode}: ${response.body})', (tester) async {
      await LocalStorageService.saveToken('sessao-antiga');

      final client = MockClient((request) async {
        expect(request.url.path, '/auth/login');
        return response;
      });

      addTearDown(client.close);

      await submit(tester, client);

      expect(await LocalStorageService.getToken(), isNull);

      expect(find.byType(LoginScreen), findsOneWidget);

      expect(find.text('Área autenticada'), findsNothing);
    });
  }

  testWidgets('/auth/me rejeitado não salva token nem libera acesso', (
    tester,
  ) async {
    final client = MockClient((request) async {
      if (request.url.path == '/auth/login') {
        return http.Response(
          '{"access_token":"jwt-invalido","token_type":"bearer"}',
          200,
        );
      }

      if (request.url.path == '/auth/me') {
        return http.Response('{}', 401);
      }

      return http.Response('{}', 404);
    });

    addTearDown(client.close);

    await submit(tester, client);

    expect(await LocalStorageService.getToken(), isNull);

    expect(find.byType(LoginScreen), findsOneWidget);

    expect(find.text('Área autenticada'), findsNothing);
  });

  testWidgets('rota direta sem sessão volta ao login', (tester) async {
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
