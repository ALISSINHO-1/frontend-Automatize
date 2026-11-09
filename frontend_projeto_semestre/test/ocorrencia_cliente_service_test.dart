
import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:frontend_projeto_semestre/core/storage/local_storage_service.dart';
import 'package:frontend_projeto_semestre/features/demands/data/services/ocorrencia_cliente_service.dart';

void main() {
  const id = '550e8400-e29b-41d4-a716-446655440000';

  setUp(() => LocalStorageService.saveToken('cliente-A'));
  tearDown(LocalStorageService.removeToken);

  Map<String, dynamic> ocorrencia() => {
        'id': '11111111-1111-4111-8111-111111111111',
        'pedido_id': id,
        'autor_id': '22222222-2222-4222-8222-222222222222',
        'tipo': 'ERRO',
        'descricao': 'Erro encontrado durante o teste',
        'status_anterior': null,
        'status_novo': null,
        'created_at': '2026-11-09T12:00:00Z',
        'resolvida': false,
        'resolvida_em': null,
        'resolvida_por_id': null,
        'descricao_resolucao': null,
      };

  test('GET lista ocorrências da demanda', () async {
    final client = MockClient((request) async {
      expect(request.method, 'GET');
      expect(
        request.url.path,
        '/demandas/$id/ocorrencias',
      );

      return http.Response(
        jsonEncode([ocorrencia()]),
        200,
      );
    });

    addTearDown(client.close);

    final service =
        OcorrenciaClienteService(client: client);

    final lista = await service.listar(id);

    expect(lista, hasLength(1));
    expect(lista.single['pedido_id'], id);
    expect(lista.single['resolvida'], false);
  });

  test('POST envia tipo e descrição exigidos', () async {
    final client = MockClient((request) async {
      expect(request.method, 'POST');

      expect(
        request.url.path,
        '/demandas/$id/ocorrencias',
      );

      expect(jsonDecode(request.body), {
        'tipo': 'ERRO',
        'descricao': 'Problema identificado no sistema.',
      });

      return http.Response(
        jsonEncode(ocorrencia()),
        201,
      );
    });

    addTearDown(client.close);

    final service =
        OcorrenciaClienteService(client: client);

    final criada = await service.criar(
      demandaId: id,
      tipo: 'ERRO',
      descricao: ' Problema identificado no sistema. ',
    );

    expect(criada['pedido_id'], id);
  });

  test('descrição curta não envia POST', () async {
    var chamadas = 0;

    final client = MockClient((_) async {
      chamadas++;
      return http.Response('{}', 201);
    });

    addTearDown(client.close);

    final service =
        OcorrenciaClienteService(client: client);

    await expectLater(
      service.criar(
        demandaId: id,
        tipo: 'ERRO',
        descricao: 'curta',
      ),
      throwsA(isA<OcorrenciaClienteException>()),
    );

    expect(chamadas, 0);
  });

  for (final codigo in [401, 403, 404, 409, 422]) {
    test('HTTP $codigo não é sucesso', () async {
      final client = MockClient(
        (_) async => http.Response('{}', codigo),
      );

      addTearDown(client.close);

      final service =
          OcorrenciaClienteService(client: client);

      await expectLater(
        service.listar(id),
        throwsA(
          isA<OcorrenciaClienteException>().having(
            (erro) => erro.statusCode,
            'statusCode',
            codigo,
          ),
        ),
      );
    });
  }

  test('resposta antiga não expõe dados a outro cliente', () async {
    final chegou = Completer<void>();
    final liberar = Completer<http.Response>();

    final client = MockClient((_) async {
      chegou.complete();
      return liberar.future;
    });

    addTearDown(client.close);

    final service =
        OcorrenciaClienteService(client: client);

    final futuro = service.listar(id);

    await chegou.future;

    await LocalStorageService.saveToken('cliente-B');

    liberar.complete(
      http.Response(
        jsonEncode([ocorrencia()]),
        200,
      ),
    );

    await expectLater(
      futuro,
      throwsA(
        isA<OcorrenciaClienteException>().having(
          (erro) => erro.statusCode,
          'statusCode',
          401,
        ),
      ),
    );

    expect(
      await LocalStorageService.getToken(),
      'cliente-B',
    );
  });
}
