import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:frontend_projeto_semestre/features/demands/data/models/pedido_model.dart';
import 'package:frontend_projeto_semestre/features/demands/data/services/demand_service.dart';
import 'package:frontend_projeto_semestre/features/home/presentation/pages/editar_demanda_screen.dart';

void main() {
  testWidgets('Edicao nao envia PATCH com titulo vazio ou apenas espacos', (
    tester,
  ) async {
    var requisicoes = 0;

    // API simulada para verificar se houve envio.
    final cliente = MockClient((request) async {
      requisicoes++;
      return http.Response('{}', 200);
    });

    addTearDown(cliente.close);

    final servico = DemandService(client: cliente);

    final pedido = PedidoModel.fromJson({
      'id': '11111111-1111-4111-8111-111111111111',
      'titulo': 'Manutenção de notebook',
      'descricao': 'Descrição original',
      'status': 'PLANEJAMENTO',
      'percentual_progresso': 15.0,
      'cliente_id': '22222222-2222-4222-8222-222222222222',
    });

    await tester.pumpWidget(
      MaterialApp(
        home: EditarDemandaScreen(pedido: pedido, demandService: servico),
      ),
    );

    // TESTE 1: título vazio.
    await tester.enterText(find.byType(TextFormField).first, '');

    await tester.tap(find.text('Salvar alterações'));
    await tester.pump();

    expect(find.text('O título é obrigatório.'), findsOneWidget);

    expect(requisicoes, 0);

    // TESTE 2: título somente com espaços.
    await tester.enterText(find.byType(TextFormField).first, '   ');

    await tester.tap(find.text('Salvar alterações'));
    await tester.pump();

    expect(find.text('O título é obrigatório.'), findsOneWidget);

    // Nenhuma requisição HTTP foi enviada.
    expect(requisicoes, 0);
  });
}
