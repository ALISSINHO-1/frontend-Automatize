import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:frontend_projeto_semestre/features/demands/data/services/demand_service.dart';
import 'package:frontend_projeto_semestre/features/home/presentation/pages/nova_demanda_screen.dart';

void main() {
  testWidgets(
    'Nao envia demanda quando o titulo esta vazio ou so tem espacos',
    (tester) async {
      var requisicoes = 0;

      // Simula a API sem conectar ao backend real.
      final cliente = MockClient((request) async {
        requisicoes++;

        return http.Response('{}', 201);
      });

      final servico = DemandService(client: cliente);

      addTearDown(cliente.close);

      await tester.pumpWidget(
        MaterialApp(home: NovaDemandaScreen(demandService: servico)),
      );

      // TESTE 1: titulo vazio.
      await tester.tap(find.text('Salvar Demanda'));
      await tester.pump();

      expect(find.text('O título é obrigatório.'), findsOneWidget);

      // Nenhuma requisicao pode ser enviada.
      expect(requisicoes, 0);

      // TESTE 2: titulo apenas com espacos.
      await tester.enterText(find.byType(TextFormField).first, '   ');

      await tester.tap(find.text('Salvar Demanda'));
      await tester.pump();

      expect(find.text('O título é obrigatório.'), findsOneWidget);

      // Continua sem realizar chamadas HTTP.
      expect(requisicoes, 0);
    },
  );
}
