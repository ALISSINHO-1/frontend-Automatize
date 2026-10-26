import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:frontend_projeto_semestre/features/demands/data/services/demand_service.dart';

void main() {
  test(
    'sends Bearer and parses the documented decimal-string progress',
    () async {
      final service = DemandService(
        accessToken: 'jwt-falso-de-teste',
        client: MockClient((request) async {
          expect(request.method, 'GET');
          expect(request.url.path, '/demandas');
          expect(request.headers['Authorization'], 'Bearer jwt-falso-de-teste');
          expect(request.url.queryParameters, {'offset': '0', 'limit': '100'});
          return http.Response(
            jsonEncode([
              {
                'id': 'demand-1',
                'codigo_identificador': 'DEM-0001',
                'titulo': 'Demanda de teste',
                'descricao': 'Resposta mockada da API.',
                'status': 'EXECUCAO',
                'percentual_progresso': '37.50',
                'cliente_id': 'client-1',
                'responsavel_id': 'tech-1',
                'created_at': '2026-10-26T10:00:00Z',
                'updated_at': '2026-10-26T11:00:00Z',
              },
            ]),
            200,
          );
        }),
      );
      addTearDown(service.dispose);

      final demands = await service.buscarDemandas();

      expect(demands.single.percentualProgresso, 37.5);
      expect(demands.single.id, 'demand-1');
    },
  );

  test('loads every authorized page for complete dashboard totals', () async {
    final offsets = <String?>[];
    final service = DemandService(
      accessToken: 'jwt-admin-mock',
      client: MockClient((request) async {
        offsets.add(request.url.queryParameters['offset']);
        final offset = int.parse(request.url.queryParameters['offset']!);
        final count = offset == 0 ? 100 : 1;
        return http.Response(
          jsonEncode(
            List.generate(count, (index) {
              final id = offset + index;
              return {
                'id': 'demand-$id',
                'titulo': 'Demand $id',
                'descricao': '',
                'status': 'PLANEAMENTO',
                'percentual_progresso': '15.00',
                'cliente_id': 'client-$id',
                'responsavel_id': null,
              };
            }),
          ),
          200,
        );
      }),
    );
    addTearDown(service.dispose);

    final demands = await service.buscarTodasDemandas();

    expect(demands, hasLength(101));
    expect(offsets, ['0', '100']);
  });

  test('401 expires the session; 403, 404, and 422 stay explicit', () async {
    var unauthorized = false;
    final expired = DemandService(
      accessToken: 'jwt-expirado-de-mock',
      onUnauthorized: () => unauthorized = true,
      client: MockClient((_) async => http.Response('{}', 401)),
    );
    addTearDown(expired.dispose);
    await expectLater(
      expired.buscarDemandas(),
      throwsA(
        isA<DemandApiException>().having(
          (error) => error.statusCode,
          'statusCode',
          401,
        ),
      ),
    );
    expect(unauthorized, isTrue);

    for (final status in [403, 404, 422]) {
      final service = DemandService(
        accessToken: 'jwt-falso-de-teste',
        client: MockClient((_) async => http.Response('{}', status)),
      );
      addTearDown(service.dispose);
      await expectLater(
        service.buscarDemanda('private-demand-id'),
        throwsA(
          isA<DemandApiException>().having(
            (error) => error.statusCode,
            'statusCode',
            status,
          ),
        ),
      );
    }
  });

  test('client cannot display a demand that the API hides with 404', () async {
    var requestedPath = '';
    final service = DemandService(
      accessToken: 'jwt-cliente-mock',
      client: MockClient((request) async {
        requestedPath = request.url.path;
        expect(request.headers['Authorization'], 'Bearer jwt-cliente-mock');
        return http.Response('{}', 404);
      }),
    );
    addTearDown(service.dispose);

    await expectLater(
      service.buscarDemanda('demanda-de-outro-cliente'),
      throwsA(isA<DemandApiException>()),
    );
    expect(requestedPath, '/demandas/demanda-de-outro-cliente');
  });

  test('sends the backend acceptance and rejection request bodies', () async {
    final requests = <http.Request>[];
    final service = DemandService(
      accessToken: 'jwt-cliente-mock',
      client: MockClient((request) async {
        requests.add(request);
        return http.Response(
          '{}',
          request.url.path.endsWith('/aceite') ? 201 : 200,
        );
      }),
    );
    addTearDown(service.dispose);

    await service.aprovarHomologacao(
      'demand-1',
      versaoEntregavel: 'v1.0',
      declaracaoAceite: 'Aceito o entregável validado.',
    );
    await service.rejeitarHomologacao(
      'demand-1',
      motivo: 'Ajustar o relatório de validação.',
    );

    expect(requests.map((request) => request.url.path), [
      '/demandas/demand-1/aceite',
      '/demandas/demand-1/rejeicao',
    ]);
    expect(requests.map((request) => request.headers['Authorization']), [
      'Bearer jwt-cliente-mock',
      'Bearer jwt-cliente-mock',
    ]);
    expect(jsonDecode(requests[0].body), {
      'versao_entregavel': 'v1.0',
      'declaracao_aceite': 'Aceito o entregável validado.',
    });
    expect(jsonDecode(requests[1].body), {
      'motivo': 'Ajustar o relatório de validação.',
    });
  });

  test(
    'uses existing API routes for technical stages and status progression',
    () async {
      final requests = <http.Request>[];
      final service = DemandService(
        accessToken: 'jwt-tecnico-mock',
        client: MockClient((request) async {
          requests.add(request);
          if (request.url.path.endsWith('/status')) {
            return http.Response(
              jsonEncode({
                'id': 'demand-1',
                'codigo_identificador': 'DEM-0001',
                'titulo': 'Mock demand',
                'descricao': '',
                'status': 'EXECUCAO',
                'percentual_progresso': '50.00',
                'cliente_id': 'client-1',
                'responsavel_id': 'tech-1',
              }),
              200,
            );
          }
          return http.Response(
            jsonEncode({
              'id': 'stage-1',
              'descricao': 'Validate build',
              'concluida': request.url.path.endsWith('/conclusao'),
              'concluida_em': null,
            }),
            request.url.path.endsWith('/etapas') ? 201 : 200,
          );
        }),
      );
      addTearDown(service.dispose);

      await service.adicionarEtapa('demand-1', descricao: 'Validate build');
      await service.concluirEtapa('demand-1', 'stage-1');
      final changed = await service.alterarStatus('demand-1', 'EXECUCAO');

      expect(changed.status, 'EXECUCAO');
      expect(requests.map((request) => request.url.path), [
        '/demandas/demand-1/etapas',
        '/demandas/demand-1/etapas/stage-1/conclusao',
        '/demandas/demand-1/status',
      ]);
      expect(
        requests.map((request) => request.headers['Authorization']),
        everyElement('Bearer jwt-tecnico-mock'),
      );
      expect(jsonDecode(requests.first.body), {'descricao': 'Validate build'});
      expect(jsonDecode(requests.last.body), {'status': 'EXECUCAO'});
    },
  );
}
