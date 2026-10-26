import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:frontend_projeto_semestre/app/app.dart';
import 'package:frontend_projeto_semestre/app/routes/app_routes.dart';
import 'package:frontend_projeto_semestre/features/demands/data/services/demand_service.dart';
import 'package:frontend_projeto_semestre/features/home/data/auth_service.dart';

class _CurrentUserProvider implements CurrentUserProvider {
  _CurrentUserProvider(this.role);
  final UserRole role;

  @override
  Future<AuthenticatedUser> fetchCurrentUser(String accessToken) async =>
      AuthenticatedUser(id: 'user-${role.apiValue}', role: role);
}

Future<void> _loginAs(
  WidgetTester tester,
  UserRole role, {
  bool demandTokenExpired = false,
}) async {
  final auth = AuthService(
    client: MockClient(
      (_) async => http.Response(
        jsonEncode({
          'access_token': 'jwt-${role.apiValue}',
          'token_type': 'bearer',
        }),
        200,
      ),
    ),
    userProvider: _CurrentUserProvider(role),
  );
  final services = <DemandService>[];
  addTearDown(() {
    auth.dispose();
    for (final service in services) {
      service.dispose();
    }
  });

  await tester.pumpWidget(
    FaculdadeApp(
      authService: auth,
      demandServiceFactory: (token, onUnauthorized) {
        final service = DemandService(
          accessToken: token,
          onUnauthorized: onUnauthorized,
          client: MockClient((request) async {
            expect(request.headers['Authorization'], 'Bearer $token');
            return http.Response(
              demandTokenExpired ? '{}' : '[]',
              demandTokenExpired ? 401 : 200,
            );
          }),
        );
        services.add(service);
        return service;
      },
    ),
  );
  final fields = find.byType(TextFormField);
  await tester.enterText(fields.at(0), 'conta@exemplo.test');
  await tester.enterText(fields.at(1), 'senha-falsa-de-teste');
  await tester.ensureVisible(find.text('Entrar na plataforma'));
  await tester.tap(find.text('Entrar na plataforma'));
  await tester.pumpAndSettle();
}

void main() {
  for (final role in UserRole.values) {
    testWidgets('login de ${role.apiValue} abre o painel correspondente', (
      tester,
    ) async {
      await _loginAs(tester, role);
      final expectedTitle = switch (role) {
        UserRole.admin => 'Painel administrativo',
        UserRole.tecnico => 'Painel técnico',
        UserRole.cliente => 'Portal do cliente',
      };
      expect(find.text(expectedTitle), findsWidgets);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });
  }

  testWidgets('cliente digitando a rota administrativa recebe acesso negado', (
    tester,
  ) async {
    await _loginAs(tester, UserRole.cliente);
    final context = tester.element(find.text('Portal do cliente').first);
    Navigator.of(context).pushNamed(AppRoutes.admin);
    await tester.pumpAndSettle();

    expect(
      find.text('Seu perfil CLIENTE não pode abrir esta página.'),
      findsOneWidget,
    );
    expect(find.text('Painel administrativo'), findsNothing);
  });

  testWidgets('logout limpa a sessão e as rotas protegidas voltam ao login', (
    tester,
  ) async {
    await _loginAs(tester, UserRole.tecnico);
    await tester.tap(find.byTooltip('Sair').first);
    await tester.pumpAndSettle();
    expect(find.text('Bem-vindo de volta!'), findsOneWidget);

    tester
        .state<NavigatorState>(find.byType(Navigator))
        .pushNamed(AppRoutes.cliente);
    await tester.pumpAndSettle();
    expect(find.text('Bem-vindo de volta!'), findsOneWidget);
    expect(find.text('Portal do cliente'), findsNothing);
  });

  testWidgets('401 from a protected API route ends the session', (
    tester,
  ) async {
    await _loginAs(tester, UserRole.cliente, demandTokenExpired: true);

    expect(find.text('Bem-vindo de volta!'), findsOneWidget);
    expect(find.text('Portal do cliente'), findsNothing);
  });
}
