import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:frontend_projeto_semestre/core/auth/cliente_guard.dart';
import 'package:frontend_projeto_semestre/core/storage/local_storage_service.dart';
import 'package:frontend_projeto_semestre/features/admin/data/services/admin_demand_service.dart';
import 'package:frontend_projeto_semestre/features/admin/data/services/usuario_atual_store.dart';

void main() {
  setUp(() async {
    await LocalStorageService.removeToken();
    UsuarioAtualStore.instance.reiniciar();
  });

  tearDown(() async {
    await LocalStorageService.removeToken();
    UsuarioAtualStore.instance.reiniciar();
  });

  Future<void> abrirRota(WidgetTester tester, String perfil) async {
    // Simula a resposta de GET /auth/me.
    final client = MockClient((request) async {
      expect(request.method, 'GET');
      expect(request.url.path, '/auth/me');

      return http.Response(
        jsonEncode({
          'id': 'usuario-123',
          'nome': 'Usuario Teste',
          'email': 'usuario@teste.com',
          'perfil': perfil,
        }),
        200,
        headers: {'content-type': 'application/json'},
      );
    });

    addTearDown(client.close);

    UsuarioAtualStore.instance.criarServico = () =>
        AdminDemandService(client: client);

    await LocalStorageService.saveToken('token-teste-$perfil');

    await tester.pumpWidget(
      const MaterialApp(
        home: ClienteGuard(
          child: Scaffold(
            body: Center(child: Text('Conteúdo privado do cliente')),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();
  }

  testWidgets('CLIENTE consegue visualizar o portal', (tester) async {
    await abrirRota(tester, 'CLIENTE');

    expect(find.text('Conteúdo privado do cliente'), findsOneWidget);

    expect(find.text('Acesso negado'), findsNothing);
  });

  for (final perfil in ['ADMIN', 'TECNICO', 'DESCONHECIDO']) {
    testWidgets('$perfil não consegue visualizar o portal CLIENTE', (
      tester,
    ) async {
      await abrirRota(tester, perfil);

      expect(find.text('Conteúdo privado do cliente'), findsNothing);

      expect(find.text('Acesso negado'), findsOneWidget);
    });
  }
}
