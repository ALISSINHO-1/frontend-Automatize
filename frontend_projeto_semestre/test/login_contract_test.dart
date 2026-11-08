import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:frontend_projeto_semestre/core/auth/auth_guard.dart';
import 'package:frontend_projeto_semestre/core/storage/local_storage_service.dart';
import 'package:frontend_projeto_semestre/features/admin/data/models/usuario_atual_model.dart';
import 'package:frontend_projeto_semestre/features/admin/data/services/usuario_atual_store.dart';
import 'package:frontend_projeto_semestre/features/home/presentation/pages/demanda_store.dart';
import 'package:frontend_projeto_semestre/features/home/presentation/pages/login_screen.dart';

void main() {
  // Reinicia os dados entre os testes.
  setUp(() async {
    await LocalStorageService.removeToken();

    UsuarioAtualStore.instance.limparSessao();
    DemandaStore.instance.limpar();
  });

  tearDown(() async {
    await LocalStorageService.removeToken();

    UsuarioAtualStore.instance.limparSessao();
    DemandaStore.instance.limpar();
  });

  // Cria um usuário falso para testar o perfil.
  UsuarioAtualModel usuario(String perfil) {
    return UsuarioAtualModel(
      id: 'usuario-1',
      nome: 'Usuario de teste',
      email: 'cliente@example.com',
      perfil: perfil,
    );
  }

  // Preenche o formulário e envia o login.
  Future<void> submit(
    WidgetTester tester,
    http.Client client, {
    Future<UsuarioAtualModel?> Function()? carregarUsuario,
  }) async {
    tester.view.physicalSize = const Size(1280, 1000);
    tester.view.devicePixelRatio = 1;

    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: LoginScreen(client: client, carregarUsuario: carregarUsuario),
        routes: {
          '/home': (_) => const Scaffold(body: Text('Portal CLIENTE')),
          '/admin': (_) => const Scaffold(body: Text('Portal ADMIN')),
          '/login': (_) => const LoginScreen(),
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

  // Simula a resposta de login válida.
  MockClient loginValido() {
    return MockClient((request) async {
      expect(request.method, 'POST');
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
    });
  }

  testWidgets('CLIENTE navega para o portal do cliente', (tester) async {
    final client = loginValido();
    addTearDown(client.close);

    var consultasPerfil = 0;

    await submit(
      tester,
      client,
      carregarUsuario: () async {
        consultasPerfil++;
        return usuario('CLIENTE');
      },
    );

    expect(consultasPerfil, 1);

    expect(await LocalStorageService.getToken(), 'jwt-teste');

    expect(find.text('Portal CLIENTE'), findsOneWidget);

    expect(find.byType(LoginScreen), findsNothing);
  });

  testWidgets('ADMIN navega para o portal administrativo', (tester) async {
    final client = loginValido();
    addTearDown(client.close);

    await submit(
      tester,
      client,
      carregarUsuario: () async {
        return usuario('ADMIN');
      },
    );

    expect(await LocalStorageService.getToken(), 'jwt-teste');

    expect(find.text('Portal ADMIN'), findsOneWidget);

    expect(find.text('Portal CLIENTE'), findsNothing);
  });

  testWidgets('TECNICO não acessa portais de outros perfis', (tester) async {
    final client = loginValido();
    addTearDown(client.close);

    await submit(
      tester,
      client,
      carregarUsuario: () async {
        return usuario('TECNICO');
      },
    );

    expect(await LocalStorageService.getToken(), isNull);

    expect(find.text('Portal técnico indisponível'), findsOneWidget);

    expect(find.text('Portal CLIENTE'), findsNothing);

    expect(find.text('Portal ADMIN'), findsNothing);
  });

  testWidgets('Perfil desconhecido recebe acesso negado', (tester) async {
    final client = loginValido();
    addTearDown(client.close);

    await submit(
      tester,
      client,
      carregarUsuario: () async {
        return usuario('OUTRO');
      },
    );

    expect(await LocalStorageService.getToken(), isNull);

    expect(find.text('Acesso negado'), findsOneWidget);

    expect(find.text('Portal CLIENTE'), findsNothing);

    expect(find.text('Portal ADMIN'), findsNothing);
  });

  testWidgets('Falha ao identificar perfil não mantém sessão', (tester) async {
    final client = loginValido();
    addTearDown(client.close);

    await submit(
      tester,
      client,
      carregarUsuario: () async {
        throw const FormatException('perfil inválido');
      },
    );

    expect(await LocalStorageService.getToken(), isNull);

    expect(find.byType(LoginScreen), findsOneWidget);

    expect(find.text('Portal CLIENTE'), findsNothing);
  });

  // Testa respostas inválidas da API.
  for (final response in [
    http.Response('{}', 401),
    http.Response('{}', 422),
    http.Response('{"token":"campo-nao-contratado"}', 200),
    http.Response('{"access_token":" "}', 200),
  ]) {
    testWidgets('Login rejeitado ou sem access_token não mantém sessão '
        '(${response.statusCode}: ${response.body})', (tester) async {
      await LocalStorageService.saveToken('sessao-antiga');

      final client = MockClient((_) async => response);

      addTearDown(client.close);

      var consultasPerfil = 0;

      await submit(
        tester,
        client,
        carregarUsuario: () async {
          consultasPerfil++;
          return usuario('CLIENTE');
        },
      );

      expect(consultasPerfil, 0);

      expect(await LocalStorageService.getToken(), isNull);

      expect(find.byType(LoginScreen), findsOneWidget);

      expect(find.text('Portal CLIENTE'), findsNothing);
    });
  }

  testWidgets('Rota direta sem sessão volta ao login', (tester) async {
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
