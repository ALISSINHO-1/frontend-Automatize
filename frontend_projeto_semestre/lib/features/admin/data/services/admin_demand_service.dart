import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../../app/app.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/network/api_paths.dart';
import '../../../../core/network/auth_interceptor.dart';
import '../../../demands/data/models/pedido_model.dart';
import '../models/anexo_model.dart';
import '../models/auditoria_model.dart';
import '../models/usuario_atual_model.dart';
import '../models/usuario_model.dart';

class AdminApiException implements Exception {
  const AdminApiException(this.statusCode, this.message);

  final int statusCode;
  final String message;

  @override
  String toString() => message;
}

/// Chamadas da área administrativa que o `DemandService` não cobre
/// (`/auth/me` e as rotas de escrita de `demandas_acoes.py`).
///
/// Usa o mesmo `AuthInterceptorClient` do resto do app: ele injeta o Bearer
/// da sessão e, em 401, encerra a sessão e volta para o login.
class AdminDemandService {
  AdminDemandService({http.Client? client})
    : _client = client ?? AuthInterceptorClient(navigatorKey: appNavigatorKey),
      _ownsClient = client == null;

  final http.Client _client;
  final bool _ownsClient;

  Future<UsuarioAtualModel> usuarioAtual() async {
    final data = await _json('GET', '/auth/me');
    if (data is! Map<String, dynamic>) {
      throw const FormatException('A API não retornou o usuário autenticado.');
    }
    return UsuarioAtualModel.fromJson(data);
  }

  Future<PedidoModel> buscarDemanda(String id) async {
    final data = await _json('GET', '${ApiPaths.demandas}/$id');
    if (data is! Map<String, dynamic>) {
      throw const FormatException('A API não retornou a demanda.');
    }
    return PedidoModel.fromJson(data);
  }

  /// Retorna o id da demanda criada. Para ADMIN o backend exige o `cliente_id`.
  Future<String> criarDemanda({
    required String titulo,
    required String descricao,
    String? clienteId,
  }) async {
    final data = await _json(
      'POST',
      ApiPaths.demandas,
      body: {
        'titulo': titulo.trim(),
        'descricao': descricao.trim(),
        if (clienteId != null && clienteId.trim().isNotEmpty)
          'cliente_id': clienteId.trim(),
      },
    );
    final id = data is Map<String, dynamic> ? data['id'] : null;
    if (id is! String) {
      throw const FormatException('A API não retornou o id da demanda criada.');
    }
    return id;
  }

  Future<void> editarDemanda(
    String id, {
    required String titulo,
    required String descricao,
  }) async {
    await _json(
      'PATCH',
      '${ApiPaths.demandas}/$id',
      body: {'titulo': titulo.trim(), 'descricao': descricao.trim()},
    );
  }

  Future<void> excluirDemanda(String id) async {
    await _json('DELETE', '${ApiPaths.demandas}/$id');
  }

  /// Na troca de um técnico já atribuído o backend exige [motivo] (SCRUM-97).
  Future<void> atribuirResponsavel(
    String id,
    String responsavelId, {
    String? motivo,
  }) async {
    await _json(
      'PUT',
      '${ApiPaths.demandas}/$id/responsavel',
      body: {
        'responsavel_id': responsavelId.trim(),
        if (motivo != null && motivo.trim().isNotEmpty) 'motivo': motivo.trim(),
      },
    );
  }

  // --- Usuários e perfis (SCRUM-99/100): rotas exclusivas do ADMIN ---

  /// Tamanho máximo de página aceito por `GET /usuarios` (`limit <= 100`).
  static const tamanhoPaginaUsuarios = 100;

  /// Trava contra laço infinito caso a API ignore o `offset` (100 páginas =
  /// 10 mil usuários, muito acima da escala do projeto).
  static const _maxPaginasUsuarios = 100;

  /// Busca todas as páginas de usuários. O backend devolve só uma lista (sem
  /// total), então seguimos pedindo até vir uma página incompleta. A ordem é
  /// estável no backend (`nome, id`), o que evita repetir ou pular registros.
  Future<List<UsuarioModel>> listarUsuarios({
    String? perfil,
    bool? ativo,
  }) async {
    final todos = <UsuarioModel>[];
    for (var pagina = 0; pagina < _maxPaginasUsuarios; pagina++) {
      final lote = await _paginaUsuarios(
        offset: pagina * tamanhoPaginaUsuarios,
        perfil: perfil,
        ativo: ativo,
      );
      todos.addAll(lote);
      if (lote.length < tamanhoPaginaUsuarios) return todos;
    }
    return todos;
  }

  Future<List<UsuarioModel>> _paginaUsuarios({
    required int offset,
    String? perfil,
    bool? ativo,
  }) async {
    final query = Uri(
      queryParameters: {
        'offset': '$offset',
        'limit': '$tamanhoPaginaUsuarios',
        'perfil': ?perfil,
        if (ativo != null) 'ativo': '$ativo',
      },
    ).query;
    final data = await _json('GET', '${ApiPaths.usuarios}?$query');
    if (data is! List) {
      throw const FormatException('A API não retornou a lista de usuários.');
    }
    return data.map((item) {
      if (item is! Map<String, dynamic>) {
        throw const FormatException('A API retornou um usuário inválido.');
      }
      return UsuarioModel.fromJson(item);
    }).toList();
  }

  Future<UsuarioModel> criarUsuario({
    required String nome,
    required String email,
    required String senha,
    required String perfil,
  }) async {
    return _usuario(
      await _json(
        'POST',
        ApiPaths.usuarios,
        body: {
          'nome': nome.trim(),
          'email': email.trim(),
          'senha': senha,
          'perfil': perfil,
        },
      ),
    );
  }

  Future<UsuarioModel> alterarPerfil(String id, String perfil) async {
    return _usuario(
      await _json(
        'PATCH',
        '${ApiPaths.usuarios}/$id/perfil',
        body: {'perfil': perfil},
      ),
    );
  }

  Future<UsuarioModel> alterarAtivo(String id, {required bool ativo}) async {
    return _usuario(
      await _json(
        'PATCH',
        '${ApiPaths.usuarios}/$id/ativo',
        body: {'ativo': ativo},
      ),
    );
  }

  UsuarioModel _usuario(dynamic data) {
    if (data is! Map<String, dynamic>) {
      throw const FormatException('A API não retornou o usuário.');
    }
    return UsuarioModel.fromJson(data);
  }

  Future<List<AuditoriaModel>> listarAuditoria(String id) async {
    final data = await _json('GET', '${ApiPaths.demandas}/$id/historico');
    if (data is! List) {
      throw const FormatException('A API não retornou a auditoria da demanda.');
    }
    final registros = data.map((item) {
      if (item is! Map<String, dynamic>) {
        throw const FormatException(
          'A API retornou um registro de auditoria inválido.',
        );
      }
      return AuditoriaModel.fromJson(item);
    }).toList();

    // Mais recente primeiro: é o que o admin procura ao auditar.
    registros.sort((a, b) {
      final da = a.createdAt, db = b.createdAt;
      if (da == null || db == null) return 0;
      return db.compareTo(da);
    });
    return registros;
  }

  Future<AnexoModel> enviarEvidencia(
    String id, {
    required String nomeArquivo,
    required List<int> bytes,
  }) async {
    final extensao = nomeArquivo.contains('.')
        ? nomeArquivo.split('.').last.toLowerCase()
        : '';
    if (!AnexoModel.extensoesPermitidas.contains(extensao)) {
      throw const AdminApiException(
        422,
        'Formato não permitido. Envie PDF, PNG, JPG, JPEG ou DOCX.',
      );
    }
    if (bytes.length > AnexoModel.tamanhoMaximoBytes) {
      throw const AdminApiException(422, 'O arquivo passa do limite de 10 MB.');
    }

    final request =
        http.MultipartRequest(
            'POST',
            AppConfig.apiUri('${ApiPaths.demandas}/$id/evidencias'),
          )
          ..files.add(
            http.MultipartFile.fromBytes(
              'arquivo',
              bytes,
              filename: nomeArquivo,
            ),
          );

    final data = _decode(await _send(request));
    if (data is! Map<String, dynamic>) {
      throw const FormatException('A API não retornou a evidência enviada.');
    }
    return AnexoModel.fromJson(data);
  }

  Future<dynamic> _json(
    String method,
    String path, {
    Map<String, Object?>? body,
  }) async {
    final request = http.Request(method, AppConfig.apiUri(path))
      ..headers['Accept'] = 'application/json';
    if (body != null) {
      request.headers['Content-Type'] = 'application/json';
      request.body = jsonEncode(body);
    }
    return _decode(await _send(request));
  }

  Future<http.Response> _send(http.BaseRequest request) async {
    late final http.Response response;
    try {
      final streamed = await _client
          .send(request)
          .timeout(const Duration(seconds: 30));
      response = await http.Response.fromStream(streamed);
    } on http.ClientException {
      throw const AdminApiException(0, 'Não foi possível conectar à API.');
    } on TimeoutException {
      throw const AdminApiException(0, 'A API demorou para responder.');
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw AdminApiException(response.statusCode, _mensagemErro(response));
    }
    return response;
  }

  /// Em 403/404/409/422 o backend manda a regra violada em `detail`
  /// (ex.: "transição inválida"); mostrar isso é mais útil que um texto genérico.
  String _mensagemErro(http.Response response) {
    // 5xx: mensagem genérica, sem expor detalhes do servidor (contrato da API).
    if (response.statusCode >= 500) {
      return 'Erro no servidor. Tente novamente mais tarde.';
    }
    try {
      final detail = (_decode(response) as Map<String, dynamic>)['detail'];
      if (detail is String && detail.isNotEmpty) return detail;
    } catch (_) {
      // Corpo vazio ou fora do padrão: cai na mensagem genérica.
    }
    return switch (response.statusCode) {
      401 => 'Sua sessão expirou. Entre novamente.',
      403 => 'Você não tem permissão para esta operação.',
      404 => 'O registro não foi encontrado.',
      409 => 'O estado atual não permite esta operação.',
      422 => 'A API recusou os dados enviados. Confira os campos.',
      _ => 'Falha na API: HTTP ${response.statusCode}.',
    };
  }

  dynamic _decode(http.Response response) {
    if (response.bodyBytes.isEmpty) return null;
    return jsonDecode(utf8.decode(response.bodyBytes));
  }

  void dispose() {
    if (_ownsClient) _client.close();
  }
}
