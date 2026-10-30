import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:frontend_projeto_semestre/features/demands/data/models/pedido_model.dart';
import 'package:frontend_projeto_semestre/features/demands/data/services/demand_service.dart';

void main() {
  const uuid = '16d64439-6e8a-4815-ae8e-8e2ba99f0f60';
  const outroUuid = 'b6f28d13-7f4e-4a21-b05e-d0c4e7f08c92';

  // A FastAPI serializa Decimal como String e também pode retornar null.
  final respostaValida = <String, dynamic>{
    'id': uuid,
    'codigo_identificador': 'AUT-100',
    'titulo': 'Atualizar sistema',
    'descricao': 'Revisar integração',
    'status': 'PLANEJAMENTO',
    'percentual_progresso': '37.50',
    'cliente_id': 'e8952d21-4805-4219-8ea2-343102749989',
  };

  group('PedidoModel — contrato da FastAPI', () {
    test('preserva UUID e converte percentual decimal em String', () {
      final pedido = PedidoModel.fromJson(respostaValida);

      expect(pedido.id, uuid);
      expect(pedido.percentualProgresso, 37.5);
      expect(pedido.progressoInformado, isTrue);
    });

    test('aceita percentual null sem quebrar a conversão', () {
      final respostaSemProgresso = {
        ...respostaValida,
        'percentual_progresso': null,
      };

      final pedido = PedidoModel.fromJson(respostaSemProgresso);

      expect(pedido.id, uuid);
      expect(pedido.progressoInformado, isFalse);
      // Zero é apenas o fallback da interface, não um progresso confirmado.
      expect(pedido.percentualProgresso, 0.0);
    });

    test('mantém compatibilidade com percentual numérico', () {
      final pedido = PedidoModel.fromJson({
        ...respostaValida,
        'percentual_progresso': 32.5,
      });

      expect(pedido.percentualProgresso, 32.5);
      expect(pedido.progressoInformado, isTrue);
    });

    test('não inventa percentual quando a API omite o campo', () {
      final semPercentual = {...respostaValida}..remove('percentual_progresso');

      expect(
        () => PedidoModel.fromJson(semPercentual),
        throwsA(isA<FormatException>()),
      );
    });

    test('rejeita percentuais inválidos e fora do intervalo de 0 a 100', () {
      for (final valor in ['NaN', 'Infinity', 'invalido', -1, 101]) {
        expect(
          () => PedidoModel.fromJson({
            ...respostaValida,
            'percentual_progresso': valor,
          }),
          throwsA(isA<FormatException>()),
          reason: 'Valor inválido não foi rejeitado: $valor',
        );
      }
    });
  });

  group('DemandService — integração HTTP simulada', () {
    test('GET /demandas converte percentuais String e null', () async {
      final cliente = MockClient((requisicao) async {
        expect(requisicao.method, 'GET');
        expect(requisicao.url.path, '/demandas');

        return http.Response(
          jsonEncode([
            respostaValida,
            {...respostaValida, 'id': outroUuid, 'percentual_progresso': null},
          ]),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      });

      final servico = DemandService(client: cliente);

      try {
        final resultado = await servico.buscarDemandas();

        expect(resultado, hasLength(2));
        expect(resultado.first.id, uuid);
        expect(resultado.first.percentualProgresso, 37.5);
        expect(resultado.first.progressoInformado, isTrue);
        expect(resultado.last.id, outroUuid);
        expect(resultado.last.progressoInformado, isFalse);
      } finally {
        cliente.close();
      }
    });

    test('busca todas as páginas autorizadas pela API', () async {
      final offsets = <String?>[];

      final cliente = MockClient((requisicao) async {
        expect(requisicao.method, 'GET');
        expect(requisicao.url.path, '/demandas');
        expect(requisicao.url.queryParameters['limit'], '100');

        final offsetTexto = requisicao.url.queryParameters['offset'];
        offsets.add(offsetTexto);
        final offset = int.parse(offsetTexto!);

        return http.Response(
          jsonEncode(
            List.generate(
              offset == 0 ? 100 : 1,
              (index) => {...respostaValida, 'id': 'demanda-${offset + index}'},
            ),
          ),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      });

      final servico = DemandService(client: cliente);

      try {
        final resultado = await servico.buscarDemandas();

        expect(resultado, hasLength(101));
        expect(offsets, ['0', '100']);
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

      try {
        await servico.criarDemanda('Novo pedido', 'Detalhes do pedido');
      } finally {
        cliente.close();
      }
    });

    for (final status in [401, 403, 404]) {
      test('HTTP $status é tratado pelo serviço', () async {
        final cliente = MockClient((_) async => http.Response('{}', status));
        final servico = DemandService(client: cliente);

        try {
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
        } finally {
          cliente.close();
        }
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
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      });

      final servico = DemandService(client: cliente);

      try {
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
      } finally {
        cliente.close();
      }
    });
  });
}
