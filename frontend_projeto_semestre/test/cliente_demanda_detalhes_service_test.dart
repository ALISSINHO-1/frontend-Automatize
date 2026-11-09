
import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:frontend_projeto_semestre/core/storage/local_storage_service.dart';
import 'package:frontend_projeto_semestre/features/demands/data/services/cliente_demanda_detalhes_service.dart';

void main() {
  const id = '550e8400-e29b-41d4-a716-446655440000';

  setUp(
    () => LocalStorageService.saveToken('token-cliente-A'),
  );

  tearDown(LocalStorageService.removeToken);

  http.Response jsonResponse(
    Object? data,
    int status,
  ) =>
      http.Response.bytes(
        utf8.encode(jsonEncode(data)),
        status,
        headers: {
          'content-type': 'application/json; charset=utf-8',
        },
      );

  test(
    'detalhes, historico e etapas carregam somente por GET',
    () async {
      final chamadas = <String>[];

      final mock = MockClient((request) async {
        expect(request.method, 'GET');
        chamadas.add(request.url.path);

        switch (request.url.path) {
          case '/demandas/$id':
            return jsonResponse({
              'id': id,
              'codigo_identificador': 'DEM-001',
              'titulo': 'Demanda A',
              'descricao': 'Descrição da demanda A',
              'status': 'PLANEAMENTO',
              'percentual_progresso': '37.50',
              'cliente_id': 'cliente-A',
              'responsavel_id': null,
              'created_at': null,
              'updated_at': null,
            }, 200);

          case '/demandas/$id/historico':
            return jsonResponse([
              {
                'id': 'evento-1',
                'acao': 'DEMANDA_CRIADA',
                'usuario_id': null,
                'detalhes': null,
                'created_at': null,
              },
            ], 200);

          case '/demandas/$id/etapas':
            return jsonResponse([
              {
                'id': 'etapa-1',
                'pedido_id': id,
                'descricao': 'Revisão',
                'ordem': 1,
                'concluida': false,
                'concluida_em': null,
                'concluida_por_id': null,
                'criado_por_id': 'usuario-1',
                'created_at': '2026-11-08T10:00:00Z',
              },
            ], 200);

          default:
            throw StateError(
              'Rota não esperada: ${request.url.path}',
            );
        }
      });

      final service =
          ClienteDemandaDetalhesService(client: mock);

      addTearDown(mock.close);

      final result = await service.carregar(id);

      expect(result.demanda['titulo'], 'Demanda A');

      expect(
        result.demanda['percentual_progresso'],
        '37.50',
      );

      expect(
        result.historico.single['acao'],
        'DEMANDA_CRIADA',
      );

      expect(
        result.etapas.single['descricao'],
        'Revisão',
      );

      expect(
        chamadas,
        containsAll([
          '/demandas/$id',
          '/demandas/$id/historico',
          '/demandas/$id/etapas',
        ]),
      );

      expect(chamadas, hasLength(3));
    },
  );

  test(
    'demanda de outro cliente retorna 404 '
    'e não consulta dados adicionais',
    () async {
      final chamadas = <String>[];

      final mock = MockClient((request) async {
        chamadas.add(request.url.path);

        return jsonResponse({
          'detail': 'Demanda não encontrada.',
        }, 404);
      });

      final service =
          ClienteDemandaDetalhesService(client: mock);

      addTearDown(mock.close);

      await expectLater(
        service.carregar(id),
        throwsA(
          isA<ClienteDetalhesException>().having(
            (e) => e.statusCode,
            'statusCode',
            404,
          ),
        ),
      );

      expect(chamadas, ['/demandas/$id']);
    },
  );

  test(
    'resposta antiga do cliente A não aparece '
    'depois da troca para B',
    () async {
      final recebeu = Completer<void>();
      final liberar = Completer<http.Response>();

      final chamadas = <String>[];

      final mock = MockClient((request) async {
        chamadas.add(request.url.path);

        if (!recebeu.isCompleted) {
          recebeu.complete();
        }

        return liberar.future;
      });

      final service =
          ClienteDemandaDetalhesService(client: mock);

      addTearDown(mock.close);

      final carregamentoA = service.carregar(id);

      await recebeu.future;

      await LocalStorageService.saveToken(
        'token-cliente-B',
      );

      liberar.complete(
        jsonResponse({
          'id': id,
          'codigo_identificador': 'DEM-A',
          'titulo': 'Demanda exclusiva de A',
        }, 200),
      );

      await expectLater(
        carregamentoA,
        throwsA(
          isA<ClienteDetalhesException>(),
        ),
      );

      expect(chamadas, ['/demandas/$id']);

      expect(
        await LocalStorageService.getToken(),
        'token-cliente-B',
      );
    },
  );

  test(
    'sem token não consulta a API',
    () async {
      await LocalStorageService.removeToken();

      var chamadas = 0;

      final mock = MockClient((_) async {
        chamadas++;

        return jsonResponse({}, 200);
      });

      final service =
          ClienteDemandaDetalhesService(client: mock);

      addTearDown(mock.close);

      await expectLater(
        service.carregar(id),
        throwsA(
          isA<ClienteDetalhesException>(),
        ),
      );

      expect(chamadas, 0);
    },
  );
}
