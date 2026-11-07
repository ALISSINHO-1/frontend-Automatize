import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:frontend_projeto_semestre/features/demands/data/models/pedido_model.dart';
import 'package:frontend_projeto_semestre/features/demands/data/services/demand_service.dart';
import 'package:frontend_projeto_semestre/features/home/presentation/pages/editar_demanda_screen.dart';

void main() {
  const pedidoId = '11111111-1111-4111-8111-111111111111';

  PedidoModel pedidoDeTeste() => PedidoModel.fromJson({
    'id': pedidoId,
    'titulo': 'Manutenção de notebook',
    'descricao': 'Descrição original',
    'status': 'PLANEJAMENTO',
    'percentual_progresso': 15.0,
    'cliente_id': '22222222-2222-4222-8222-222222222222',
  });

  testWidgets('Edição bloqueia títulos inválidos sem enviar PATCH', (
    tester,
  ) async {
    var requisicoes = 0;
    final cliente = MockClient((request) async {
      requisicoes++;
      return http.Response('{}', 200);
    });
    addTearDown(cliente.close);

    await tester.pumpWidget(
      MaterialApp(
        home: EditarDemandaScreen(
          pedido: pedidoDeTeste(),
          demandService: DemandService(client: cliente),
        ),
      ),
    );

    final campos = find.byType(TextFormField);
    for (final titulo in [
      '',
      '   ',
      'AB',
      ' A ',
      List.filled(256, 'A').join(),
    ]) {
      await tester.enterText(campos.at(0), titulo);
      await tester.tap(find.text('Salvar alterações'));
      await tester.pump();

      final mensagem = titulo.trim().isEmpty
          ? 'O título é obrigatório.'
          : titulo.trim().length < 3
          ? 'O título deve ter pelo menos 3 caracteres.'
          : 'O título deve ter no máximo 255 caracteres.';
      expect(find.text(mensagem), findsOneWidget);
      expect(requisicoes, 0);
    }
  });

  testWidgets('Edição bloqueia descrições inválidas sem enviar PATCH', (
    tester,
  ) async {
    var requisicoes = 0;
    final cliente = MockClient((request) async {
      requisicoes++;
      return http.Response('{}', 200);
    });
    addTearDown(cliente.close);

    await tester.pumpWidget(
      MaterialApp(
        home: EditarDemandaScreen(
          pedido: pedidoDeTeste(),
          demandService: DemandService(client: cliente),
        ),
      ),
    );

    final campos = find.byType(TextFormField);
    await tester.enterText(campos.at(0), 'Título válido');

    for (final descricao in ['', '   ', 'ABCD', ' ABCD ']) {
      await tester.enterText(campos.at(1), descricao);
      await tester.tap(find.text('Salvar alterações'));
      await tester.pump();

      expect(
        find.text(
          descricao.trim().isEmpty
              ? 'A descrição é obrigatória.'
              : 'A descrição deve ter pelo menos 5 caracteres.',
        ),
        findsOneWidget,
      );
      expect(requisicoes, 0);
    }
  });

  testWidgets('Edição válida faz um PATCH com ID e dados sem espaços', (
    tester,
  ) async {
    final pedidos = <http.Request>[];
    final cliente = MockClient((request) async {
      pedidos.add(request);
      return http.Response('{}', 200);
    });
    addTearDown(cliente.close);

    await tester.pumpWidget(
      MaterialApp(
        home: EditarDemandaScreen(
          pedido: pedidoDeTeste(),
          demandService: DemandService(client: cliente),
        ),
      ),
    );

    final campos = find.byType(TextFormField);
    await tester.enterText(campos.at(0), '  ABC  ');
    await tester.enterText(campos.at(1), '  12345  ');
    await tester.tap(find.text('Salvar alterações'));
    await tester.pumpAndSettle();

    expect(pedidos, hasLength(1));
    expect(pedidos.single.method, 'PATCH');
    expect(pedidos.single.url.path, endsWith('/demandas/$pedidoId'));
    expect(jsonDecode(pedidos.single.body), {
      'titulo': 'ABC',
      'descricao': '12345',
    });
  });

  testWidgets('Edição aceita título com exatamente 255 caracteres', (
    tester,
  ) async {
    var requisicoes = 0;
    final cliente = MockClient((request) async {
      requisicoes++;
      return http.Response('{}', 200);
    });
    addTearDown(cliente.close);

    await tester.pumpWidget(
      MaterialApp(
        home: EditarDemandaScreen(
          pedido: pedidoDeTeste(),
          demandService: DemandService(client: cliente),
        ),
      ),
    );

    final campos = find.byType(TextFormField);
    await tester.enterText(campos.at(0), List.filled(255, 'A').join());
    await tester.enterText(campos.at(1), 'Descrição válida');
    await tester.tap(find.text('Salvar alterações'));
    await tester.pumpAndSettle();

    expect(requisicoes, 1);
  });
}
