import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../../app/app.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/network/api_paths.dart';
import '../../../../core/network/auth_interceptor.dart';
import '../../../../core/storage/local_storage_service.dart';

class HomologacaoClienteException implements Exception {
  const HomologacaoClienteException(
    this.mensagem, {
    this.statusCode,
    this.resultadoIncerto = false,
  });

  final String mensagem;
  final int? statusCode;
  final bool resultadoIncerto;

  @override
  String toString() => mensagem;
}

/// SCRUM-113: consulta demanda, aprova e rejeita pela API.
/// O backend valida o perfil, a propriedade e o estado.
class HomologacaoClienteService {
  HomologacaoClienteService({http.Client? client})
    : _client = client ?? AuthInterceptorClient(navigatorKey: appNavigatorKey),
      _ownsClient = client == null;

  final http.Client _client;
  final bool _ownsClient;

  static const _timeout = Duration(seconds: 15);

  String _caminho(String id) {
    if (id.trim().isEmpty) {
      throw const HomologacaoClienteException('Demanda sem identificador.');
    }

    return '${ApiPaths.demandas}/${Uri.encodeComponent(id)}';
  }

  // Consulta o estado atual da demanda.
  Future<Map<String, dynamic>> consultar(String id) async {
    final response = await _requisitar(
      path: _caminho(id),
      method: 'GET',
      esperado: 200,
    );

    try {
      final dynamic json = jsonDecode(utf8.decode(response.bodyBytes));

      if (json is Map<String, dynamic> && json['id']?.toString() == id) {
        return json;
      }
    } on FormatException {
      // O erro será tratado abaixo.
    }

    throw const HomologacaoClienteException(
      'A API retornou dados de demanda inválidos.',
    );
  }

  // Aprovação formal do cliente.
  Future<void> aprovar({
    required String id,
    required String versaoEntregavel,
    required String declaracaoAceite,
  }) async {
    final versao = versaoEntregavel.trim();
    final declaracao = declaracaoAceite.trim();

    if (versao.isEmpty || versao.length > 50 || declaracao.length < 10) {
      throw const HomologacaoClienteException(
        'Informe a versão (até 50 caracteres) e '
        'uma declaração de aceite com pelo menos '
        '10 caracteres.',
      );
    }

    await _requisitar(
      path: '${_caminho(id)}/aceite',
      method: 'POST',
      esperado: 201,
      body: {'versao_entregavel': versao, 'declaracao_aceite': declaracao},
    );
  }

  // Rejeição com motivo obrigatório.
  Future<void> rejeitar({required String id, required String motivo}) async {
    final texto = motivo.trim();

    if (texto.length < 10) {
      throw const HomologacaoClienteException(
        'Explique a inconformidade com pelo menos '
        '10 caracteres.',
      );
    }

    await _requisitar(
      path: '${_caminho(id)}/rejeicao',
      method: 'POST',
      esperado: 200,
      body: {'motivo': texto},
    );
  }

  // Executa as requisições HTTP reais.
  Future<http.Response> _requisitar({
    required String path,
    required String method,
    required int esperado,
    Map<String, dynamic>? body,
  }) async {
    final token = await LocalStorageService.getToken();

    if (token == null || token.trim().isEmpty) {
      throw const HomologacaoClienteException(
        'Faça login para acessar a demanda.',
        statusCode: 401,
      );
    }

    final uri = AppConfig.apiUri(path);

    late final http.Response response;

    try {
      if (method == 'GET') {
        response = await _client
            .get(uri, headers: {'Accept': 'application/json'})
            .timeout(_timeout);
      } else {
        response = await _client
            .post(
              uri,
              headers: {
                'Accept': 'application/json',
                'Content-Type': 'application/json',
              },
              body: jsonEncode(body),
            )
            .timeout(_timeout);
      }
    } on TimeoutException {
      throw HomologacaoClienteException(
        method == 'POST'
            ? 'Sem confirmação do servidor. Consulte '
                  'o estado da demanda antes de tentar novamente.'
            : 'O servidor demorou para responder.',
        resultadoIncerto: method == 'POST',
      );
    } on http.ClientException {
      throw HomologacaoClienteException(
        method == 'POST'
            ? 'Conexão interrompida. Consulte '
                  'o estado da demanda antes de tentar novamente.'
            : 'Não foi possível conectar à API.',
        resultadoIncerto: method == 'POST',
      );
    }

    // Impede que uma resposta de A seja usada por B.
    if (await LocalStorageService.getToken() != token) {
      throw const HomologacaoClienteException(
        'A sessão mudou. Consulte novamente a demanda.',
        statusCode: 401,
      );
    }

    if (response.statusCode != esperado) {
      final mensagem = switch (response.statusCode) {
        401 => 'Sessão expirada. Entre novamente.',
        403 =>
          'Somente o cliente proprietário pode '
              'realizar esta ação.',
        404 => 'Demanda não encontrada ou fora do seu acesso.',
        409 =>
          'Esta demanda não está mais disponível '
              'para essa decisão. Atualize antes de continuar.',
        422 => 'Os dados enviados não foram aceitos pela API.',
        _ =>
          'Operação não realizada '
              '(HTTP ${response.statusCode}).',
      };

      throw HomologacaoClienteException(
        mensagem,
        statusCode: response.statusCode,
      );
    }

    return response;
  }

  void dispose() {
    if (_ownsClient) {
      _client.close();
    }
  }
}
