import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend_projeto_semestre/core/storage/local_storage_service.dart';
import 'package:frontend_projeto_semestre/features/admin/data/services/admin_demand_service.dart';
import 'package:frontend_projeto_semestre/features/admin/presentation/pages/admin_users_page.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

http.Response _json(Object? body, [int status = 200]) => http.Response.bytes(
  utf8.encode(jsonEncode(body)),
  status,
  headers: {'content-type': 'application/json'},
);

Map<String, Object?> _usuario(String id, String nome, String perfil, {bool ativo = true}) => {
  'id': id,
  'nome': nome,
  'email': '${nome.toLowerCase()}@x.dev',
  'perfil': perfil,
  'ativo': ativo,
  'created_at': '2026-10-01T10:00:00Z',
};

final _usuarios = [
  _usuario('eu', 'Ana', 'ADMIN'),
  _usuario('t1', 'Tiago', 'TECNICO'),
  _usuario('c1', 'Carla', 'CLIENTE', ativo: false),
];

void main() {
  setUp(() => LocalStorageService.saveToken('token'));

  /// Abre a tela; devolve as chamadas de escrita (método, caminho e corpo).
  Future<List<String>> abrir(
    WidgetTester tester, {
    http.Response Function(http.Request)? escrita,
  }) async {
    tester.view.physicalSize = const Size(1440, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final chamadas = <String>[];
    await tester.pumpWidget(MaterialApp(
      home: AdminUsersPage(
        idUsuarioAtual: 'eu',
        adminService: AdminDemandService(
          client: MockClient((req) async {
            if (req.method == 'GET') return _json(_usuarios);
            chamadas.add('${req.method} ${req.url.path} ${req.body}');
            return escrita?.call(req) ?? _json(_usuarios.first);
          }),
        ),
      ),
    ));
    await tester.pumpAndSettle();
    return chamadas;
  }

  testWidgets('lista, filtra por perfil e protege a própria conta', (tester) async {
    await abrir(tester);

    expect(find.text('Ana (você)'), findsOneWidget);
    expect(find.text('Inativo'), findsOneWidget);
    // O backend recusa alterar a própria conta: só os outros dois têm ações.
    expect(find.byTooltip('Ações do usuário'), findsNWidgets(2));

    await tester.tap(find.text('Técnico (1)'));
    await tester.pumpAndSettle();
    expect(find.text('Tiago'), findsOneWidget);
    expect(find.text('Carla'), findsNothing);
  });

  testWidgets('inativa com confirmação e reativa', (tester) async {
    final chamadas = await abrir(tester);

    await tester.tap(find.byTooltip('Ações do usuário').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Inativar'));
    await tester.pumpAndSettle();
    expect(find.textContaining('perde o acesso imediatamente'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Inativar'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Ações do usuário').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Reativar'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Reativar'));
    await tester.pumpAndSettle();

    expect(chamadas, [
      'PATCH /usuarios/t1/ativo {"ativo":false}',
      'PATCH /usuarios/c1/ativo {"ativo":true}',
    ]);
  });

  testWidgets('troca de perfil oferece só os outros perfis e mostra a regra do backend', (tester) async {
    await abrir(
      tester,
      escrita: (_) => _json({
        'detail': 'Nao e possivel alterar o perfil este tecnico: ele e responsavel por 2 '
            'demanda(s) em aberto. Reatribua-as antes.',
      }, 409),
    );

    await tester.tap(find.byTooltip('Ações do usuário').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Alterar perfil'));
    await tester.pumpAndSettle();
    expect(find.text('Tornar Técnico'), findsNothing);
    await tester.tap(find.text('Tornar Cliente'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Reatribua-as antes'), findsOneWidget);
  });

  testWidgets('cadastra usuário validando os campos', (tester) async {
    final chamadas = await abrir(tester);

    await tester.tap(find.text('Novo usuário'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cadastrar'));
    await tester.pump();
    expect(find.textContaining('Informe o nome'), findsOneWidget);
    expect(find.text('Informe um e-mail válido.'), findsOneWidget);
    expect(find.text('A senha deve ter no mínimo 8 caracteres.'), findsOneWidget);
    expect(find.text('Selecione o perfil.'), findsOneWidget);

    final campos = find.byType(TextFormField);
    await tester.enterText(campos.at(0), 'Rita Souza');
    await tester.enterText(campos.at(1), 'rita@x.dev');
    await tester.enterText(campos.at(2), 'senha-forte');
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Técnico').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cadastrar'));
    await tester.pumpAndSettle();

    expect(chamadas, [
      'POST /usuarios {"nome":"Rita Souza","email":"rita@x.dev","senha":"senha-forte","perfil":"TECNICO"}',
    ]);
    expect(find.text('Usuário Rita Souza cadastrado.'), findsOneWidget);
  });
}
