import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:frontend_projeto_semestre/features/onboarding/presentation/pages/verificar_email_screen.dart';
import 'package:frontend_projeto_semestre/features/onboarding/presentation/pages/redefinir_senha_screen.dart';

void main() {
  testWidgets('confirma e-mail somente com POST explicito', (tester) async {
    var chamadas = 0;
    final client = MockClient((req) async {
      chamadas++;
      expect(req.method, 'POST');
      expect(req.url.path, '/auth/verificar-email');
      expect(jsonDecode(req.body), {'token': 'token-valido-com-mais-de-vinte-caracteres'});
      return http.Response('', 204);
    });
    addTearDown(client.close);
    await tester.pumpWidget(MaterialApp(home: VerificarEmailScreen(
      token: 'token-valido-com-mais-de-vinte-caracteres', client: client)));
    expect(chamadas, 0);
    await tester.tap(find.text('Confirmar e-mail'));
    await tester.pumpAndSettle();
    expect(chamadas, 1);
    expect(find.text('E-mail confirmado'), findsOneWidget);
  });

  testWidgets('redefine senha sem colocar token na URL da API', (tester) async {
    final client = MockClient((req) async {
      expect(req.method, 'POST');
      expect(req.url.path, '/auth/senha/redefinir');
      final data = jsonDecode(req.body);
      expect(data['token'], 'token-de-redefinicao-com-mais-de-vinte-caracteres');
      expect(data['nova_senha'], 'SenhaSegura123');
      return http.Response('', 204);
    });
    addTearDown(client.close);
    await tester.pumpWidget(MaterialApp(home: RedefinirSenhaScreen(
      token: 'token-de-redefinicao-com-mais-de-vinte-caracteres', client: client)));
    await tester.enterText(find.byType(TextFormField).at(0), 'SenhaSegura123');
    await tester.enterText(find.byType(TextFormField).at(1), 'SenhaSegura123');
    await tester.tap(find.text('Redefinir senha'));
    await tester.pumpAndSettle();
    expect(find.text('Senha alterada com sucesso'), findsOneWidget);
  });

  testWidgets('token curto nao provoca requisicao', (tester) async {
    var chamadas = 0;
    final client = MockClient((_) async {
      chamadas++;
      return http.Response('', 200);
    });
    addTearDown(client.close);
    await tester.pumpWidget(MaterialApp(home: VerificarEmailScreen(
      token: 'invalid', client: client)));
    await tester.tap(find.text('Confirmar e-mail'));
    await tester.pumpAndSettle();
    expect(chamadas, 0);
    expect(find.text('Link de verificação inválido.'), findsOneWidget);
  });
}
