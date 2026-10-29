
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:frontend_projeto_semestre/core/network/auth_interceptor.dart';
import 'package:frontend_projeto_semestre/core/storage/local_storage_service.dart';
import 'package:frontend_projeto_semestre/features/home/presentation/pages/login_screen.dart';

void main() {
  test(
    'interceptor envia Bearer Token em requisição protegida',
    () async {
      await LocalStorageService.saveToken(
        'token-falso-de-teste',
      );

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

      final resposta = await interceptor.get(
        Uri.parse('http://localhost/demandas'),
      );

      expect(resposta.statusCode, 200);

      interceptor.close();
      await LocalStorageService.removeToken();
    },
  );

  test(
    'interceptor não envia Bearer Token ao fazer login',
    () async {
      await LocalStorageService.saveToken('token-antigo');

      final clienteFalso = MockClient((requisicao) async {
        expect(
          requisicao.headers.containsKey('Authorization'),
          isFalse,
        );

        return http.Response('{}', 200);
      });

      final interceptor = AuthInterceptorClient(
        navigatorKey: GlobalKey<NavigatorState>(),
        inner: clienteFalso,
      );

      final resposta = await interceptor.post(
        Uri.parse('http://localhost/auth/login'),
      );

      expect(resposta.statusCode, 200);

      interceptor.close();
      await LocalStorageService.removeToken();
    },
  );

  testWidgets(
    'HTTP 401 encerra a sessão e redireciona para o login',
    (WidgetTester tester) async {
      await LocalStorageService.saveToken('token-expirado');

      final navigatorKey = GlobalKey<NavigatorState>();

      final clienteFalso = MockClient((requisicao) async {
        expect(
          requisicao.headers['Authorization'],
          'Bearer token-expirado',
        );

        return http.Response(
          '{"detail": "Token expirado"}',
          401,
        );
      });

      final interceptor = AuthInterceptorClient(
        navigatorKey: navigatorKey,
        inner: clienteFalso,
      );

      addTearDown(() async {
        interceptor.close();
        await LocalStorageService.removeToken();
      });

      // Simula uma tela protegida do aplicativo.
      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: navigatorKey,
          home: const Scaffold(
            body: Center(
              child: Text('Tela protegida'),
            ),
          ),
        ),
      );

      // Simula uma requisição com token expirado.
      final resposta = await interceptor.get(
        Uri.parse('http://localhost/demandas'),
      );

      expect(resposta.statusCode, 401);

      // Confirma que o token foi removido.
      final token = await LocalStorageService.getToken();

      expect(token, isNull);

      // Aguarda o redirecionamento para o login.
      await tester.pumpAndSettle();

      // Confirma que a tela de login foi exibida.
      expect(
        find.byType(LoginScreen),
        findsOneWidget,
      );

      // Confirma que a tela protegida foi removida.
      expect(
        find.text('Tela protegida'),
        findsNothing,
      );
    },
  );
}
