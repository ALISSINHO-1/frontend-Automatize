import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend_projeto_semestre/core/network/auth_interceptor.dart';
import 'package:frontend_projeto_semestre/core/storage/local_storage_service.dart';
import 'package:frontend_projeto_semestre/features/admin/data/services/admin_demand_service.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

const _id = '11111111-1111-1111-1111-111111111111';

// Usa o interceptor real do app: ele injeta o Bearer e encerra a sessão em 401.
AdminDemandService _comCliente(http.Client inner) => AdminDemandService(
      client: AuthInterceptorClient(
        navigatorKey: GlobalKey<NavigatorState>(),
        inner: inner,
      ),
    );

AdminDemandService _servico(Future<http.Response> Function(http.Request) handler) =>
    _comCliente(MockClient(handler));

http.Response _json(Object? body, int status) => http.Response.bytes(
      utf8.encode(jsonEncode(body)),
      status,
      headers: {'content-type': 'application/json'},
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => LocalStorageService.saveToken('token'));

  test('criarDemanda envia token, corpo e devolve o id', () async {
    late http.Request enviado;
    final servico = _servico((req) async {
      enviado = req;
      return _json({'id': _id}, 201);
    });

    final id = await servico.criarDemanda(titulo: ' Rede ', descricao: 'Configurar', clienteId: _id);

    expect(id, _id);
    expect(enviado.method, 'POST');
    expect(enviado.url.path, '/demandas');
    expect(enviado.headers['Authorization'], 'Bearer token');
    expect(jsonDecode(enviado.body), {'titulo': 'Rede', 'descricao': 'Configurar', 'cliente_id': _id});
  });

  test('criarDemanda omite cliente_id vazio (backend recusa campos extras)', () async {
    late http.Request enviado;
    final servico = _servico((req) async {
      enviado = req;
      return _json({'id': _id}, 201);
    });

    await servico.criarDemanda(titulo: 'A', descricao: 'B', clienteId: '  ');

    expect((jsonDecode(enviado.body) as Map).containsKey('cliente_id'), isFalse);
  });

  test('editar, excluir e atribuir usam método e rota corretos', () async {
    final chamadas = <String>[];
    final servico = _servico((req) async {
      chamadas.add('${req.method} ${req.url.path}');
      return req.method == 'DELETE' ? http.Response('', 204) : _json({'id': _id}, 200);
    });

    await servico.editarDemanda(_id, titulo: 'T', descricao: 'D');
    await servico.excluirDemanda(_id);
    await servico.atribuirResponsavel(_id, _id);

    expect(chamadas, [
      'PATCH /demandas/$_id',
      'DELETE /demandas/$_id',
      'PUT /demandas/$_id/responsavel',
    ]);
  });

  test('erro de regra mostra o detail do backend', () async {
    final servico = _servico((_) async => _json({'detail': 'Demanda concluida nao pode ser excluida.'}, 409));

    expect(
      () => servico.excluirDemanda(_id),
      throwsA(isA<AdminApiException>()
          .having((e) => e.statusCode, 'status', 409)
          .having((e) => e.message, 'message', 'Demanda concluida nao pode ser excluida.')),
    );
  });

  test('401 encerra a sessão local', () async {
    final servico = _servico((_) async => http.Response('', 401));

    await expectLater(servico.excluirDemanda(_id), throwsA(isA<AdminApiException>()));
    expect(await LocalStorageService.getToken(), isNull);
  });

  test('usuarioAtual lê o perfil de GET /auth/me', () async {
    late http.Request enviado;
    final servico = _servico((req) async {
      enviado = req;
      return _json({'id': _id, 'nome': 'Ana Admin', 'email': 'a@x.dev', 'perfil': 'ADMIN'}, 200);
    });

    final usuario = await servico.usuarioAtual();

    expect(enviado.url.path, '/auth/me');
    expect(enviado.headers['Authorization'], 'Bearer token');
    expect(usuario.isAdmin, isTrue);
    expect(usuario.iniciais, 'AA');
  });

  test('listarAuditoria ordena do mais recente e lê evidências', () async {
    final servico = _servico((_) async => _json([
          {'id': 'a', 'usuario_id': _id, 'acao': 'CRIACAO_DEMANDA', 'detalhes': {}, 'created_at': '2026-10-01T10:00:00Z'},
          {
            'id': 'b',
            'usuario_id': _id,
            'acao': 'ENVIO_EVIDENCIA',
            'detalhes': {'nome_arquivo': 'laudo.pdf', 'tamanho_bytes': 2048},
            'created_at': '2026-10-02T10:00:00Z',
          },
          {'id': 'c', 'usuario_id': null, 'acao': 'ACAO_NOVA', 'detalhes': null, 'created_at': null},
        ], 200));

    final registros = await servico.listarAuditoria(_id);

    expect(registros.first.id, 'b');
    expect(registros.first.isEvidencia, isTrue);
    expect(registros.first.nomeArquivo, 'laudo.pdf');
    expect(registros.first.tamanhoBytes, 2048);
    expect(registros.firstWhere((r) => r.id == 'c').rotulo, 'ACAO NOVA');
  });

  test('enviarEvidencia recusa extensão e tamanho antes de chamar a API', () async {
    var chamou = false;
    final servico = _servico((_) async {
      chamou = true;
      return http.Response('', 201);
    });

    await expectLater(
      servico.enviarEvidencia(_id, nomeArquivo: 'virus.exe', bytes: [1]),
      throwsA(isA<AdminApiException>()),
    );
    await expectLater(
      servico.enviarEvidencia(_id, nomeArquivo: 'grande.pdf', bytes: List.filled(10 * 1024 * 1024 + 1, 0)),
      throwsA(isA<AdminApiException>()),
    );
    expect(chamou, isFalse);
  });

  test('enviarEvidencia faz upload multipart no campo arquivo', () async {
    final client = MockClient.streaming((req, body) async {
      final conteudo = utf8.decode(await body.toBytes(), allowMalformed: true);
      expect(req.url.path, '/demandas/$_id/evidencias');
      expect(req.headers['content-type'], startsWith('multipart/form-data'));
      expect(conteudo, contains('name="arquivo"; filename="foto.PNG"'));
      return http.StreamedResponse(
        Stream.value(utf8.encode(jsonEncode({
          'id': 'x',
          'pedido_id': _id,
          'nome_arquivo': 'foto.PNG',
          'extensao': 'png',
          'tamanho_bytes': 3,
        }))),
        201,
      );
    });
    final servico = _comCliente(client);

    final anexo = await servico.enviarEvidencia(_id, nomeArquivo: 'foto.PNG', bytes: [1, 2, 3]);

    expect(anexo.nomeArquivo, 'foto.PNG');
    expect(anexo.tamanhoBytes, 3);
  });

  test('erro 5xx não expõe detalhes do servidor', () async {
    final servico = _servico((_) async => _json({'detail': 'psycopg2 OperationalError'}, 500));

    await expectLater(
      servico.excluirDemanda(_id),
      throwsA(isA<AdminApiException>().having(
        (e) => e.message,
        'message',
        'Erro no servidor. Tente novamente mais tarde.',
      )),
    );
  });
}
