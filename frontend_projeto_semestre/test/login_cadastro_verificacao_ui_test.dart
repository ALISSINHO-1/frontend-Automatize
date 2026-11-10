import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:frontend_projeto_semestre/app/routes/app_routes.dart';
import 'package:frontend_projeto_semestre/features/home/presentation/pages/login_screen.dart';
import 'package:frontend_projeto_semestre/features/onboarding/presentation/pages/verificar_email_screen.dart';

void main() {
  testWidgets('login apresenta o link criar conta sob o aviso de seguranca', (tester) async {
    tester.view.physicalSize = const Size(1280, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(MaterialApp(
      home: const LoginScreen(),
      routes: {
        AppRoutes.cadastro: (_) => const Scaffold(body: Text('Cadastro publico')),
      },
    ));

    final aviso = find.text('Acesso destinado aos usuários da plataforma');
    final cadastro = find.text('Crie sua conta');
    expect(aviso, findsOneWidget);
    expect(cadastro, findsOneWidget);
    expect(tester.getTopLeft(cadastro).dy, greaterThan(tester.getTopLeft(aviso).dy));

    await tester.ensureVisible(cadastro);
    await tester.tap(cadastro);
    await tester.pumpAndSettle();
    expect(find.text('Cadastro publico'), findsOneWidget);
  });

  testWidgets('token de e-mail exige confirmacao explicita do usuario', (tester) async {
    var chamadas = 0;
    final client = MockClient((request) async {
      chamadas++;
      expect(request.method, 'POST');
      expect(request.url.path, '/auth/verificar-email');
      expect(jsonDecode(request.body), {'token': '1234567890123456789012345'});
      return http.Response('', 204);
    });
    addTearDown(client.close);

    await tester.pumpWidget(MaterialApp(
      home: VerificarEmailScreen(
        token: '1234567890123456789012345',
        client: client,
      ),
      routes: {
        AppRoutes.login: (_) => const Scaffold(body: Text('Login do Automatize')),
      },
    ));

    expect(chamadas, 0);
    await tester.tap(find.text('Confirmar e-mail'));
    await tester.pumpAndSettle();
    expect(chamadas, 1);
    expect(find.text('E-mail confirmado'), findsOneWidget);
    await tester.tap(find.text('Ir para o login'));
    await tester.pumpAndSettle();
    expect(find.text('Login do Automatize'), findsOneWidget);
  });
}
