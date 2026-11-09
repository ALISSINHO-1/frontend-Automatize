
import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:frontend_projeto_semestre/core/storage/local_storage_service.dart';
import 'package:frontend_projeto_semestre/features/demands/data/services/homologacao_cliente_service.dart';

void main() {
  const id = '550e8400-e29b-41d4-a716-446655440000';

  setUp(() => LocalStorageService.saveToken('token-cliente-A'));
  tearDown(LocalStorageService.removeToken);

  test('aceite envia apenas versao e declaracao e exige HTTP 201', () async {
    var chamadas = 0;

    final client = MockClient((request) async {
      chamadas++;

      expect(request.method, 'POST');
      expect(request.url.path, '/demandas/$id/aceite');

      expect(jsonDecode(request.body), {
        'versao_entregavel': 'v1.2',
        'declaracao_aceite': 'Aprovo a entrega v1.2.',
      });

      return http.Response('{}', 201);
    });

    addTearDown(client.close);

    final service = HomologacaoClienteService(client: client);

    await service.aprovar(
      id: id,
      versaoEntregavel: ' v1.2 ',
      declaracaoAceite: ' Aprovo a entrega v1.2. ',
    );

    expect(chamadas, 1);
  });

  test('rejeicao envia o motivo e exige HTTP 200', () async {
    final client = MockClient((request) async {
      expect(request.method, 'POST');
      expect(request.url.path, '/demandas/$id/rejeicao');

      expect(jsonDecode(request.body), {
        'motivo': 'O sistema nao passou na validacao final.',
      });

      return http.Response('{}', 200);
    });

    addTearDown(client.close);

    await HomologacaoClienteService(client: client).rejeitar(
      id: id,
      motivo: ' O sistema nao passou na validacao final. ',
    );
  });

  test('motivo vazio nao envia nenhuma requisicao', () async {
    var chamadas = 0;

    final client = MockClient((_) async {
      chamadas++;
      return http.Response('{}', 200);
    });

    addTearDown(client.close);

    await expectLater(
      HomologacaoClienteService(client: client).rejeitar(
        id: id,
        motivo: '   ',
      ),
      throwsA(isA<HomologacaoClienteException>()),
    );

    expect(chamadas, 0);
  });

  for (final codigo in [403, 404, 409, 422]) {
    test('HTTP $codigo nao e tratado como sucesso', () async {
      final client = MockClient(
        (_) async => http.Response('{}', codigo),
      );

      addTearDown(client.close);

      await expectLater(
        HomologacaoClienteService(client: client).rejeitar(
          id: id,
          motivo: 'Entrega com problemas de funcionamento.',
        ),
        throwsA(
          isA<HomologacaoClienteException>().having(
            (e) => e.statusCode,
            'statusCode',
            codigo,
          ),
        ),
      );
    });
  }

  test('resposta antiga nao deve ser aceita apos troca de cliente', () async {
    final chegou = Completer<void>();
    final liberar = Completer<http.Response>();

    final client = MockClient((request) async {
      chegou.complete();
      return liberar.future;
    });

    addTearDown(client.close);

    final futuro = HomologacaoClienteService(client: client).rejeitar(
      id: id,
      motivo: 'O entregavel contem erros de validacao.',
    );

    await chegou.future;

    await LocalStorageService.saveToken('token-cliente-B');

    liberar.complete(http.Response('{}', 200));

    await expectLater(
      futuro,
      throwsA(
        isA<HomologacaoClienteException>().having(
          (e) => e.statusCode,
          'statusCode',
          401,
        ),
      ),
    );

    expect(
      await LocalStorageService.getToken(),
      'token-cliente-B',
    );
  });

  test('GET consulta o estado atual, sem realizar alteracoes', () async {
    final client = MockClient((request) async {
      expect(request.method, 'GET');
      expect(request.url.path, '/demandas/$id');

      return http.Response(
        jsonEncode({
          'id': id,
          'titulo': 'Demanda de teste',
          'status': 'HOMOLOGACAO',
        }),
        200,
      );
    });

    addTearDown(client.close);

    final dados = await HomologacaoClienteService(
      client: client,
    ).consultar(id);

    expect(dados['status'], 'HOMOLOGACAO');
  });
}
