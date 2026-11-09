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

  test('atribuirResponsavel só envia motivo quando informado', () async {
    final corpos = <Map<String, dynamic>>[];
    final servico = _servico((req) async {
      corpos.add(jsonDecode(req.body) as Map<String, dynamic>);
      return _json({}, 200);
    });

    await servico.atribuirResponsavel(_id, _id);
    await servico.atribuirResponsavel(_id, _id, motivo: '  Tecnico de ferias  ');

    expect(corpos, [
      {'responsavel_id': _id},
      {'responsavel_id': _id, 'motivo': 'Tecnico de ferias'},
    ]);
  });

  test('listarUsuarios filtra por perfil e status via query', () async {
    late http.Request enviado;
    final servico = _servico((req) async {
      enviado = req;
      return _json([
        {'id': _id, 'nome': 'Tiago', 'email': 't@x.dev', 'perfil': 'tecnico', 'ativo': true},
        {'id': 'x', 'nome': 'Ivo', 'perfil': 'CLIENTE', 'ativo': null},
      ], 200);
    });

    final usuarios = await servico.listarUsuarios(perfil: 'TECNICO', ativo: true);

    expect(enviado.url.path, '/usuarios');
    expect(enviado.url.queryParameters,
        {'offset': '0', 'limit': '100', 'perfil': 'TECNICO', 'ativo': 'true'});
    expect(usuarios.first.perfil, 'TECNICO');
    // `ativo` nulo no banco não conta como ativo, igual ao backend.
    expect(usuarios.last.ativo, isFalse);
  });

  test('listarUsuarios percorre todas as páginas além dos 100 primeiros', () async {
    final offsets = <String?>[];
    final servico = _servico((req) async {
      final offset = int.parse(req.url.queryParameters['offset']!);
      offsets.add('$offset');
      // 250 usuários no total: páginas de 100, 100 e 50.
      final restantes = (250 - offset).clamp(0, 100);
      return _json([
        for (var i = 0; i < restantes; i++)
          {'id': 'u${offset + i}', 'nome': 'U${offset + i}', 'perfil': 'CLIENTE', 'ativo': true},
      ], 200);
    });

    final usuarios = await servico.listarUsuarios();

    expect(offsets, ['0', '100', '200']);
    expect(usuarios, hasLength(250));
    expect(usuarios.last.id, 'u249');
  });

  test('listarUsuarios pede mais uma página quando a última vem cheia', () async {
    final offsets = <String>[];
    final servico = _servico((req) async {
      final offset = req.url.queryParameters['offset']!;
      offsets.add(offset);
      final cheia = offset == '0';
      return _json([
        if (cheia)
          for (var i = 0; i < 100; i++)
            {'id': 'u$i', 'nome': 'U$i', 'perfil': 'CLIENTE', 'ativo': true},
      ], 200);
    });

    expect(await servico.listarUsuarios(), hasLength(100));
    expect(offsets, ['0', '100']);
  });

  test('gestão de usuários usa as rotas e corpos do backend', () async {
    final chamadas = <String>[];
    final servico = _servico((req) async {
      chamadas.add('${req.method} ${req.url.path} ${req.body}');
      return _json({'id': _id, 'nome': 'Rita', 'email': 'r@x.dev', 'perfil': 'TECNICO', 'ativo': true}, 200);
    });

    await servico.criarUsuario(nome: ' Rita ', email: ' r@x.dev ', senha: 'senha-forte', perfil: 'TECNICO');
    await servico.alterarPerfil(_id, 'ADMIN');
    await servico.alterarAtivo(_id, ativo: false);

    expect(chamadas, [
      'POST /usuarios {"nome":"Rita","email":"r@x.dev","senha":"senha-forte","perfil":"TECNICO"}',
      'PATCH /usuarios/$_id/perfil {"perfil":"ADMIN"}',
      'PATCH /usuarios/$_id/ativo {"ativo":false}',
    ]);
  });

  test('regra violada no backend aparece com o detail (ex.: último ADMIN)', () async {
    final servico = _servico(
      (_) async => _json({'detail': 'Nao e possivel inativar o ultimo ADMIN ativo.'}, 409),
    );

    await expectLater(
      servico.alterarAtivo(_id, ativo: false),
      throwsA(isA<AdminApiException>()
          .having((e) => e.statusCode, 'status', 409)
          .having((e) => e.message, 'mensagem', contains('ultimo ADMIN'))),
    );
  });
}
