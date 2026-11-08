import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend_projeto_semestre/core/storage/local_storage_service.dart';
import 'package:frontend_projeto_semestre/features/admin/data/services/admin_demand_service.dart';
import 'package:frontend_projeto_semestre/features/admin/data/services/usuario_atual_store.dart';
import 'package:frontend_projeto_semestre/features/admin/presentation/pages/admin_panel_page.dart';
import 'package:frontend_projeto_semestre/features/admin/presentation/widgets/admin_guard.dart';
import 'package:frontend_projeto_semestre/features/demands/data/services/demand_service.dart';
import 'package:frontend_projeto_semestre/shared/widgets/main_layout.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

const _cliente = '33333333-3333-4333-8333-333333333333';
const _tecnico = '44444444-4444-4444-8444-444444444444';
const _outroTecnico = '55555555-5555-4555-8555-555555555555';

// O mock devolve todos; o filtro por perfil/ativo é do backend.
final _usuarios = [
  {'id': _cliente, 'nome': 'Carla Cliente', 'email': 'carla@x.dev', 'perfil': 'CLIENTE', 'ativo': true},
  {'id': _tecnico, 'nome': 'Tiago Técnico', 'email': 'tiago@x.dev', 'perfil': 'TECNICO', 'ativo': true},
  {'id': _outroTecnico, 'nome': 'Rita Técnica', 'email': 'rita@x.dev', 'perfil': 'TECNICO', 'ativo': true},
];

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
void _perfil(String perfil, {String nome = 'Ana Admin'}) {
  UsuarioAtualStore.instance.criarServico = () => AdminDemandService(
    client: MockClient(
      (_) async => _json({
        'id': 'u1',
        'nome': nome,
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

  testWidgets('menu lateral mostra a identidade da sessão atual', (tester) async {
    const casos = [
      ('ADMIN', 'Ana Souza', 'Administrador', 'AS', 'ÁREA ADMINISTRATIVA'),
      ('TECNICO', 'Tiago Dias', 'Técnico', 'TD', 'ÁREA TÉCNICA'),
      ('CLIENTE', 'Carla Lima', 'Cliente', 'CL', 'ÁREA DO CLIENTE'),
    ];

    for (final (perfil, nome, rotulo, iniciais, area) in casos) {
      await tester.pumpWidget(const SizedBox.shrink());
      await LocalStorageService.saveToken('token-$perfil');
      _perfil(perfil, nome: nome);
      await abrir(tester, const MainLayout(child: SizedBox.shrink()));

      expect(find.text(nome), findsOneWidget);
      expect(find.text(rotulo), findsOneWidget);
      expect(find.text(iniciais), findsOneWidget);
      expect(find.text(area), findsOneWidget);
      expect(
        find.text('Painel administrativo'),
        perfil == 'ADMIN' ? findsOneWidget : findsNothing,
      );
    }
  });

  testWidgets('conta por estado, filtra pelo card e cadastra escolhendo o cliente', (tester) async {
    _perfil('ADMIN');
    final demandas = [
      _demanda('1', 'Portal interno', 'PLANEAMENTO'),
      _demanda('2', 'App de vistoria', 'HOMOLOGACAO'),
      _demanda('3', 'Painel financeiro', 'CONCLUIDO'),
    ];
    Map<String, dynamic>? corpoCriacao;
    final consultasUsuarios = <String>[];

    await abrir(
      tester,
      AdminPanelPage(
        service: DemandService(client: MockClient((_) async => _json(demandas))),
        adminService: AdminDemandService(
          client: MockClient((request) async {
            if (request.url.path == '/usuarios') {
              consultasUsuarios.add(request.url.query);
              return _json(_usuarios);
            }
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
    expect(consultasUsuarios.last, contains('perfil=CLIENTE'));
    expect(consultasUsuarios.last, contains('ativo=true'));
    final campos = find.byType(TextFormField);
    await tester.enterText(campos.at(0), 'Migração de e-mail');
    await tester.enterText(campos.at(1), 'Migrar caixas de e-mail');
    await tester.tap(find.text('Cadastrar'));
    await tester.pump();
    expect(find.text('Selecione o cliente.'), findsOneWidget);

    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Carla Cliente · carla@x.dev').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cadastrar'));
    await tester.pumpAndSettle();

    expect(corpoCriacao, {
      'titulo': 'Migração de e-mail',
      'descricao': 'Migrar caixas de e-mail',
      'cliente_id': _cliente,
    });
    expect(find.text('Migração de e-mail'), findsOneWidget);
  });

  testWidgets('mostra o técnico pelo nome e a troca exige motivo', (tester) async {
    _perfil('ADMIN');
    final demanda = _demanda('1', 'Portal interno', 'EXECUCAO')..['responsavel_id'] = _tecnico;
    Map<String, dynamic>? corpoAtribuicao;

    await abrir(
      tester,
      AdminPanelPage(
        service: DemandService(client: MockClient((_) async => _json([demanda]))),
        adminService: AdminDemandService(
          client: MockClient((request) async {
            if (request.url.path == '/usuarios') return _json(_usuarios);
            corpoAtribuicao = jsonDecode(request.body) as Map<String, dynamic>;
            return _json(demanda);
          }),
        ),
      ),
    );

    expect(find.text('Técnico: Tiago Técnico'), findsOneWidget);

    await tester.tap(find.byTooltip('Ações da demanda'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Atribuir/trocar técnico'));
    await tester.pumpAndSettle();

    expect(find.text('Trocar técnico'), findsOneWidget);
    expect(find.text('Responsável atual: Tiago Técnico'), findsOneWidget);
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    // O técnico atual não é oferecido de novo (o backend responderia 409).
    expect(find.text('Tiago Técnico · tiago@x.dev'), findsNothing);
    await tester.tap(find.text('Rita Técnica · rita@x.dev').last);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Trocar'));
    await tester.pump();
    expect(find.textContaining('Descreva o motivo'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField), 'Tiago entrou de férias');
    await tester.tap(find.text('Trocar'));
    await tester.pumpAndSettle();

    expect(corpoAtribuicao, {'responsavel_id': _outroTecnico, 'motivo': 'Tiago entrou de férias'});
  });
}
