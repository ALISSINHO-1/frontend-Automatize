import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend_projeto_semestre/features/admin/data/models/usuario_atual_model.dart';
import 'package:frontend_projeto_semestre/features/admin/data/services/admin_demand_service.dart';
import 'package:frontend_projeto_semestre/features/admin/presentation/pages/clientes_page.dart';
import 'package:frontend_projeto_semestre/features/demands/data/services/demand_service.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

class _Api {
  final requisicoes = <String>[];
  String status = 'PLANEAMENTO';
  bool rejeitar = false;

  http.Response responder(http.Request req) {
    requisicoes.add('${req.method} ${req.url.path}');
    Object dados;
    var codigo = 200;
    switch (req.url.path) {
      case '/usuarios':
      case '/usuarios/clientes':
        dados = req.url.queryParameters['perfil'] == 'TECNICO'
            ? []
            : [
                {
                  'id': 'alpha',
                  'nome': 'Empresa Alpha',
                  'perfil': 'CLIENTE',
                  'ativo': true,
                },
                {
                  'id': 'beta',
                  'nome': 'Empresa Beta',
                  'perfil': 'CLIENTE',
                  'ativo': false,
                },
              ];
      case '/demandas':
        dados = [
          {
            'id': 'd1',
            'codigo_identificador': 'DEM-1',
            'titulo': 'Implantação',
            'cliente_id': 'alpha',
            'responsavel_id': 'tecnico',
            'percentual_progresso': '50.00',
            'status': status,
          },
        ];
      case '/demandas/d1/etapas':
        dados = [
          {'id': 't1', 'descricao': 'Configurar banco', 'concluida': true},
          {'id': 't2', 'descricao': 'Executar testes', 'concluida': false},
        ];
      case '/demandas/d1/quadro/movimentos':
        final movimento = jsonDecode(req.body) as Map;
        expect(movimento['origem'], status);
        if (rejeitar) {
          codigo = 409;
          dados = {'detail': 'Conclua as tarefas antes de avançar.'};
        } else {
          status = movimento['destino'] as String;
          dados = {};
        }
      default:
        throw StateError('Requisição inesperada ${req.url}');
    }
    return http.Response.bytes(utf8.encode(jsonEncode(dados)), codigo);
  }
}

Future<void> _abrir(WidgetTester tester, _Api api, String perfil) async {
  final httpClient = MockClient((req) async => api.responder(req));
  addTearDown(httpClient.close);
  await tester.pumpWidget(
    MaterialApp(
      home: ClientesPage(
        adminService: AdminDemandService(client: httpClient),
        demandService: DemandService(client: httpClient),
        carregarUsuario: () async => UsuarioAtualModel(
          id: 'tecnico',
          nome: 'Pessoa de teste',
          email: '',
          perfil: perfil,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void _dimensoes(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

void main() {
  testWidgets('grade, lista, busca, filtros e navegação até as tarefas', (
    tester,
  ) async {
    _dimensoes(tester, const Size(1440, 1000));
    await _abrir(tester, _Api(), 'ADMIN');
    expect(find.text('Novo Cliente'), findsOneWidget);
    expect(find.text('Empresa Alpha'), findsOneWidget);
    expect(find.text('50%'), findsOneWidget);

    await tester.tap(find.byTooltip('Lista'));
    await tester.pumpAndSettle();
    expect(find.byType(DataTable), findsOneWidget);
    await tester.tap(find.text('Inativos (1)'));
    await tester.pumpAndSettle();
    expect(find.text('Empresa Beta'), findsOneWidget);
    expect(find.text('Empresa Alpha'), findsNothing);

    await tester.tap(find.text('Todos (2)'));
    await tester.enterText(
      find.byKey(const Key('busca-clientes')),
      'Configurar banco',
    );
    await tester.pumpAndSettle();
    expect(find.text('Empresa Beta'), findsNothing);

    await tester.tap(find.text('Empresa Alpha'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Implantação'));
    await tester.pumpAndSettle();
    expect(find.text('Tarefas da demanda'), findsOneWidget);
    expect(find.text('Configurar banco'), findsOneWidget);
  });

  testWidgets(
    'quadro carrega a posição gravada e mantém a coluna quando a API rejeita',
    (tester) async {
      _dimensoes(tester, const Size(1440, 1100));
      final api = _Api();
      await _abrir(tester, api, 'TECNICO');
      expect(find.text('Novo Cliente'), findsNothing);
      expect(api.requisicoes, contains('GET /usuarios/clientes'));

      await tester.tap(find.byTooltip('Quadro'));
      await tester.pumpAndSettle();
      expect(find.text('Demandas por cliente'), findsOneWidget);
      final origem = tester.getCenter(find.text('Implantação'));
      final destino = tester.getCenter(find.text('Execução'));
      final gesto = await tester.startGesture(origem);
      await gesto.moveBy(const Offset(20, 0));
      await tester.pump();
      await gesto.moveTo(destino + const Offset(0, 55));
      await tester.pump();
      await gesto.up();
      await tester.pumpAndSettle();
      expect(api.status, 'EXECUCAO');
      expect(api.requisicoes.where((r) => r == 'GET /demandas').length, 2);

      api.rejeitar = true;
      await tester.tap(find.byTooltip('Avançar para Homologação'));
      await tester.pumpAndSettle();
      expect(api.status, 'EXECUCAO');
      expect(find.text('Conclua as tarefas antes de avançar.'), findsOneWidget);
      expect(find.byTooltip('Avançar para Homologação'), findsOneWidget);

      await tester.tap(find.byTooltip('Atualizar clientes'));
      await tester.pumpAndSettle();
      expect(find.byTooltip('Avançar para Homologação'), findsOneWidget);
    },
  );

  testWidgets('cliente não consulta o diretório da equipe', (tester) async {
    final api = _Api();
    await _abrir(tester, api, 'CLIENTE');
    expect(
      find.text('Área disponível para administradores e técnicos.'),
      findsOneWidget,
    );
    expect(api.requisicoes, isEmpty);
  });

  testWidgets('grade e quadro cabem em celular com rolagem', (tester) async {
    _dimensoes(tester, const Size(390, 780));
    await _abrir(tester, _Api(), 'ADMIN');
    final quadro = find.byTooltip('Quadro');
    await tester.ensureVisible(quadro);
    await tester.tap(quadro);
    await tester.pumpAndSettle();
    expect(find.text('Demandas por cliente'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
