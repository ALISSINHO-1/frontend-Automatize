import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:frontend_projeto_semestre/core/network/auth_interceptor.dart';
import 'package:frontend_projeto_semestre/core/storage/local_storage_service.dart';
import 'package:frontend_projeto_semestre/features/home/presentation/pages/login_screen.dart';

/// Conta quantas vezes a navegação abriu a rota de login.
class _ContadorLogin extends NavigatorObserver {
  int redirecionamentos = 0;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);

    if (route.settings.name == '/login') {
      redirecionamentos++;
    }
  }
}

void main() {
  setUp(LocalStorageService.removeToken);
  tearDown(LocalStorageService.removeToken);

  // TESTE 1
  // Verifica o envio do Bearer Token.
  test('interceptor envia Bearer Token em requisição protegida', () async {
    await LocalStorageService.saveToken('token-falso-de-teste');

    final clienteFalso = MockClient((requisicao) async {
      expect(
        requisicao.headers['Authorization'],
        'Bearer token-falso-de-teste',
      );

      return http.Response('{}', 200);
    });

    final interceptor = AuthInterceptorClient(
      navigatorKey: GlobalKey<NavigatorState>(),
      inner: clienteFalso,
    );

    addTearDown(interceptor.close);

    final resposta = await interceptor.get(
      Uri.parse('http://localhost/demandas'),
    );

    expect(resposta.statusCode, 200);
  });

  // TESTE 2
  // Login não deve enviar um token antigo.
  test('interceptor não envia Bearer Token ao fazer login', () async {
    await LocalStorageService.saveToken('token-antigo');

    final clienteFalso = MockClient((requisicao) async {
      expect(requisicao.headers.containsKey('Authorization'), isFalse);

      return http.Response('{}', 200);
    });

    final interceptor = AuthInterceptorClient(
      navigatorKey: GlobalKey<NavigatorState>(),
      inner: clienteFalso,
    );

    addTearDown(interceptor.close);

    final resposta = await interceptor.post(
      Uri.parse('http://localhost/auth/login'),
    );

    expect(resposta.statusCode, 200);
  });

  // TESTE 3
  // Um HTTP 401 invalida o token e retorna ao login.
  testWidgets('HTTP 401 encerra sessão e redireciona para login', (
    tester,
  ) async {
    await LocalStorageService.saveToken('token-expirado');

    final navigatorKey = GlobalKey<NavigatorState>();

    final clienteFalso = MockClient((requisicao) async {
      expect(requisicao.headers['Authorization'], 'Bearer token-expirado');

      return http.Response('{"detail":"Token expirado"}', 401);
    });

    final interceptor = AuthInterceptorClient(
      navigatorKey: navigatorKey,
      inner: clienteFalso,
    );

    addTearDown(interceptor.close);

    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: navigatorKey,
        home: const Scaffold(body: Center(child: Text('Tela protegida'))),
      ),
    );

    final resposta = await interceptor.get(
      Uri.parse('http://localhost/demandas'),
    );

    expect(resposta.statusCode, 401);

    expect(await LocalStorageService.getToken(), isNull);

    await tester.pumpAndSettle();

    expect(find.byType(LoginScreen), findsOneWidget);

    expect(find.text('Tela protegida'), findsNothing);
  });

  // TESTE 4 — SCRUM-116
  // Duas respostas HTTP 401 simultâneas devem
  // provocar somente um redirecionamento.
  testWidgets('duas respostas 401 redirecionam apenas uma vez', (tester) async {
    await LocalStorageService.saveToken('token-expirado');

    final navigatorKey = GlobalKey<NavigatorState>();
    final contador = _ContadorLogin();

    // Controla a chegada das duas requisições.
    final duasRecebidas = Completer<void>();

    // Controla o momento das respostas da API simulada.
    final liberarRespostas = Completer<void>();

    var quantidadeRequisicoes = 0;

    final clienteFalso = MockClient((requisicao) async {
      expect(requisicao.headers['Authorization'], 'Bearer token-expirado');

      quantidadeRequisicoes++;

      if (quantidadeRequisicoes == 2) {
        duasRecebidas.complete();
      }

      await liberarRespostas.future;

      return http.Response('{"detail":"Token expirado"}', 401);
    });

    final interceptor = AuthInterceptorClient(
      navigatorKey: navigatorKey,
      inner: clienteFalso,
    );

    addTearDown(interceptor.close);

    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: navigatorKey,
        navigatorObservers: [contador],
        home: const Scaffold(body: Text('Tela protegida')),
      ),
    );

    // Inicia duas requisições protegidas.
    final primeira = interceptor.get(Uri.parse('http://localhost/demandas'));

    final segunda = interceptor.get(Uri.parse('http://localhost/auth/me'));

    // Espera as duas utilizarem o token antigo.
    await duasRecebidas.future;

    // Libera as duas respostas HTTP 401.
    liberarRespostas.complete();

    final respostas = await Future.wait([primeira, segunda]);

    expect(respostas[0].statusCode, 401);
    expect(respostas[1].statusCode, 401);

    // O token expirado deve ser removido.
    expect(await LocalStorageService.getToken(), isNull);

    await tester.pumpAndSettle();

    // A navegação deve ocorrer somente uma vez.
    expect(contador.redirecionamentos, 1);

    expect(find.byType(LoginScreen), findsOneWidget);

    expect(find.text('Tela protegida'), findsNothing);
  });

  // TESTE 5 — SCRUM-116
  // Uma resposta antiga do cliente A não pode
  // invalidar a sessão atual do cliente B.
  testWidgets('401 antigo não encerra a sessão de outro usuário', (
    tester,
  ) async {
    // Cliente A autenticado.
    await LocalStorageService.saveToken('token-cliente-A');

    final navigatorKey = GlobalKey<NavigatorState>();

    final requisicaoRecebida = Completer<void>();
    final liberarResposta = Completer<void>();

    final clienteFalso = MockClient((requisicao) async {
      expect(requisicao.headers['Authorization'], 'Bearer token-cliente-A');

      requisicaoRecebida.complete();

      // Simula uma resposta atrasada do servidor.
      await liberarResposta.future;

      return http.Response('{"detail":"Token expirado"}', 401);
    });

    final interceptor = AuthInterceptorClient(
      navigatorKey: navigatorKey,
      inner: clienteFalso,
    );

    addTearDown(interceptor.close);

    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: navigatorKey,
        home: const Scaffold(body: Text('Sessão atual')),
      ),
    );

    // Inicia uma requisição usando a sessão A.
    final requisicaoAntiga = interceptor.get(
      Uri.parse('http://localhost/demandas'),
    );

    await requisicaoRecebida.future;

    // Cliente B entra antes de a resposta chegar.
    await LocalStorageService.saveToken('token-cliente-B');

    // A API devolve o erro referente à sessão A.
    liberarResposta.complete();

    final resposta = await requisicaoAntiga;

    expect(resposta.statusCode, 401);

    // O token da sessão B deve continuar válido.
    expect(await LocalStorageService.getToken(), 'token-cliente-B');

    await tester.pumpAndSettle();

    // Não pode ocorrer redirecionamento ao login.
    expect(find.text('Sessão atual'), findsOneWidget);

    expect(find.byType(LoginScreen), findsNothing);
  });
}
