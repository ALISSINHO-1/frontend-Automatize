import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend_projeto_semestre/core/storage/local_storage_service.dart';
import 'package:frontend_projeto_semestre/features/admin/data/services/admin_demand_service.dart';
import 'package:frontend_projeto_semestre/features/admin/data/services/usuario_atual_store.dart';
import 'package:frontend_projeto_semestre/features/admin/presentation/pages/admin_panel_page.dart';
import 'package:frontend_projeto_semestre/features/admin/presentation/widgets/admin_guard.dart';
import 'package:frontend_projeto_semestre/features/demands/data/services/demand_service.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

const _cliente = '33333333-3333-4333-8333-333333333333';

Map<String, Object?> _demanda(String id, String titulo, String status) => {
  'id': id,
  'codigo_identificador': 'DEM-$id',
  'titulo': titulo,
  'descricao': 'Descrição',
  'status': status,
  'percentual_progresso': '0.00',
  'cliente_id': _cliente,
  'responsavel_id': null,
  'created_at': '2026-10-01T10:00:00Z',
  'updated_at': null,
};

http.Response _json(Object? body, [int status = 200]) => http.Response.bytes(
  utf8.encode(jsonEncode(body)),
  status,
  headers: {'content-type': 'application/json'},
);

/// Faz o `/auth/me` responder com [perfil] sem tocar na rede.
void _perfil(String perfil) {
  UsuarioAtualStore.instance.criarServico = () => AdminDemandService(
    client: MockClient(
      (_) async => _json({
        'id': 'u1',
        'nome': 'Ana Admin',
        'email': 'a@x.dev',
        'perfil': perfil,
      }),
    ),
  );
}

void main() {
  setUp(() async {
    UsuarioAtualStore.instance.reiniciar();
    await LocalStorageService.saveToken('token-${DateTime.now().microsecondsSinceEpoch}');
  });

  Future<void> abrir(WidgetTester tester, Widget tela) async {
    tester.view.physicalSize = const Size(1440, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(home: tela));
    await tester.pumpAndSettle();
  }

  testWidgets('perfil que não é ADMIN vê acesso restrito', (tester) async {
    _perfil('CLIENTE');
    await abrir(tester, const AdminGuard(child: Text('conteúdo admin')));

    expect(find.text('Acesso restrito'), findsOneWidget);
    expect(find.text('conteúdo admin'), findsNothing);
  });

  testWidgets('ADMIN entra e vê o item do menu', (tester) async {
    _perfil('ADMIN');
    await abrir(
      tester,
      AdminGuard(
        child: AdminPanelPage(
          service: DemandService(client: MockClient((_) async => _json([]))),
          adminService: AdminDemandService(client: MockClient((_) async => _json(null))),
        ),
      ),
    );

    expect(find.text('Painel administrativo'), findsWidgets);
    expect(find.text('Nenhuma demanda encontrada.'), findsOneWidget);
  });

  testWidgets('conta por estado, filtra pelo card e cadastra com cliente', (tester) async {
    _perfil('ADMIN');
    final demandas = [
      _demanda('1', 'Portal interno', 'PLANEAMENTO'),
      _demanda('2', 'App de vistoria', 'HOMOLOGACAO'),
      _demanda('3', 'Painel financeiro', 'CONCLUIDO'),
    ];
    Map<String, dynamic>? corpoCriacao;

    await abrir(
      tester,
      AdminPanelPage(
        service: DemandService(client: MockClient((_) async => _json(demandas))),
        adminService: AdminDemandService(
          client: MockClient((request) async {
            corpoCriacao = jsonDecode(request.body) as Map<String, dynamic>;
            demandas.add(_demanda('4', corpoCriacao!['titulo'] as String, 'PLANEAMENTO'));
            return _json({'id': '4'}, 201);
          }),
        ),
      ),
    );

    expect(find.text('3 demanda(s) cadastrada(s).'), findsOneWidget);

    await tester.tap(find.text('Homologação'));
    await tester.pumpAndSettle();
    expect(find.text('App de vistoria'), findsOneWidget);
    expect(find.text('Portal interno'), findsNothing);
    await tester.tap(find.text('Limpar filtro'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Nova demanda'));
    await tester.pumpAndSettle();
    final campos = find.byType(TextFormField);
    await tester.enterText(campos.at(0), 'Migração de e-mail');
    await tester.enterText(campos.at(1), 'Migrar caixas de e-mail');
    await tester.enterText(campos.at(2), _cliente);
    await tester.tap(find.text('Cadastrar'));
    await tester.pumpAndSettle();

    expect(corpoCriacao, {
      'titulo': 'Migração de e-mail',
      'descricao': 'Migrar caixas de e-mail',
      'cliente_id': _cliente,
    });
    expect(find.text('Migração de e-mail'), findsOneWidget);
  });
}
