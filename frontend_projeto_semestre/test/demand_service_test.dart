import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:frontend_projeto_semestre/features/demands/data/models/pedido_model.dart';
import 'package:frontend_projeto_semestre/features/demands/data/services/demand_service.dart';

void main() {
  const uuid = '16d64439-6e8a-4815-ae8e-8e2ba99f0f60';

  final respostaValida = {
    'id': uuid,
    'codigo_identificador': 'AUT-100',
    'titulo': 'Atualizar sistema',
    'descricao': 'Revisar integração',
    'status': 'PLANEJAMENTO',
    'percentual_progresso': 32.5,
    'cliente_id': 'e8952d21-4805-4219-8ea2-343102749989',
  };

  test('mantém UUID e percentual enviados pela API', () {
    final pedido = PedidoModel.fromJson(respostaValida);

    expect(pedido.id, uuid);
    expect(pedido.percentualProgresso, 32.5);
  });

  test('não inventa percentual quando a API omite o campo', () {
    final semPercentual = {...respostaValida}..remove('percentual_progresso');

    expect(
      () => PedidoModel.fromJson(semPercentual),
      throwsA(isA<FormatException>()),
    );
  });

  test('GET /demandas retorna registros reais do cliente HTTP', () async {
    final cliente = MockClient((requisicao) async {
      expect(requisicao.method, 'GET');
      expect(requisicao.url.path, '/demandas');

      return http.Response(
        jsonEncode([respostaValida]),
        200,
        headers: {'content-type': 'application/json; charset=utf-8'},
      );
    });

    final servico = DemandService(client: cliente);

    try {
      final resultado = await servico.buscarDemandas();

      expect(resultado, hasLength(1));
      expect(resultado.single.id, uuid);
      expect(resultado.single.percentualProgresso, 32.5);
    } finally {
      cliente.close();
    }
  });

  test('POST /demandas envia somente titulo e descricao', () async {
    final cliente = MockClient((requisicao) async {
      expect(requisicao.method, 'POST');
      expect(requisicao.url.path, '/demandas');

      expect(jsonDecode(requisicao.body), {
        'titulo': 'Novo pedido',
        'descricao': 'Detalhes do pedido',
      });

      return http.Response('{}', 201);
    });

    final servico = DemandService(client: cliente);

    await servico.criarDemanda('Novo pedido', 'Detalhes do pedido');

    cliente.close();
  });

  for (final status in [401, 403, 404]) {
    test('HTTP $status é tratado pelo serviço', () async {
      final cliente = MockClient((_) async => http.Response('{}', status));

      final servico = DemandService(client: cliente);

      await expectLater(
        servico.buscarDemandas(),
        throwsA(
          isA<DemandServiceException>().having(
            (erro) => erro.statusCode,
            'statusCode',
            status,
          ),
        ),
      );

      cliente.close();
    });
  }

  test('HTTP 422 exibe mensagem retornada pela FastAPI', () async {
    final cliente = MockClient((_) async {
      return http.Response(
        jsonEncode({
          'detail': [
            {
              'loc': ['body', 'titulo'],
              'msg': 'Field required',
            },
          ],
        }),
        422,
      );
    });

    final servico = DemandService(client: cliente);

    await expectLater(
      servico.criarDemanda('', ''),
      throwsA(
        isA<DemandServiceException>()
            .having((erro) => erro.statusCode, 'statusCode', 422)
            .having(
              (erro) => erro.mensagem,
              'mensagem',
              contains('Field required'),
            ),
      ),
    );

    cliente.close();
  });
}
