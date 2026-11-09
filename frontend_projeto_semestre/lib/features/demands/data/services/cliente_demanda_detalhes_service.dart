
import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../../app/app.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/network/api_paths.dart';
import '../../../../core/network/auth_interceptor.dart';
import '../../../../core/storage/local_storage_service.dart';

class ClienteDetalhesException implements Exception {
  const ClienteDetalhesException(
    this.mensagem, {
    this.statusCode,
  });

  final String mensagem;
  final int? statusCode;

  @override
  String toString() => mensagem;
}

class ClienteDemandaDetalhes {
  const ClienteDemandaDetalhes({
    required this.demanda,
    required this.historico,
    required this.etapas,
  });

  final Map<String, dynamic> demanda;
  final List<Map<String, dynamic>> historico;
  final List<Map<String, dynamic>> etapas;
}

/// Consultas exclusivamente de leitura.
/// As regras de autorização são responsabilidade da API.
class ClienteDemandaDetalhesService {
  ClienteDemandaDetalhesService({http.Client? client})
      : _client = client ??
            AuthInterceptorClient(navigatorKey: appNavigatorKey),
        _ownsClient = client == null;

  final http.Client _client;
  final bool _ownsClient;

  static const _timeout = Duration(seconds: 15);

  Future<ClienteDemandaDetalhes> carregar(
    String demandaId,
  ) async {
    if (demandaId.trim().isEmpty) {
      throw const ClienteDetalhesException(
        'Identificador da demanda ausente.',
      );
    }

    final tokenInicial = await LocalStorageService.getToken();

    if (tokenInicial == null || tokenInicial.trim().isEmpty) {
      throw const ClienteDetalhesException(
        'Faça login para consultar esta demanda.',
        statusCode: 401,
      );
    }

    final caminho =
        '${ApiPaths.demandas}/${Uri.encodeComponent(demandaId)}';

    // Consulta primeiro a demanda.
    // Se houver 403 ou 404, não consulta informações adicionais.
    final demanda = await _obterObjeto(
      caminho,
      tokenInicial,
    );

    if (demanda['id']?.toString() != demandaId) {
      throw const ClienteDetalhesException(
        'Resposta de demanda incompatível.',
      );
    }

    final colecoes = await Future.wait([
      _obterLista('$caminho/historico', tokenInicial),
      _obterLista('$caminho/etapas', tokenInicial),
    ]);

    await _conferirSessao(tokenInicial);

    return ClienteDemandaDetalhes(
      demanda: demanda,
      historico: colecoes[0],
      etapas: colecoes[1],
    );
  }

  Future<Map<String, dynamic>> _obterObjeto(
    String path,
    String token,
  ) async {
    final decoded = await _consultar(path, token);

    if (decoded is! Map<String, dynamic>) {
      throw const ClienteDetalhesException(
        'A API não retornou os detalhes esperados.',
      );
    }

    return decoded;
  }

  Future<List<Map<String, dynamic>>> _obterLista(
    String path,
    String token,
  ) async {
    final decoded = await _consultar(path, token);

    if (decoded is! List) {
      throw const ClienteDetalhesException(
        'A API não retornou uma lista válida.',
      );
    }

    try {
      return decoded
          .map(
            (item) => Map<String, dynamic>.from(item as Map),
          )
          .toList();
    } on TypeError {
      throw const ClienteDetalhesException(
        'A API retornou itens inválidos.',
      );
    }
  }

  Future<dynamic> _consultar(
    String path,
    String token,
  ) async {
    await _conferirSessao(token);

    late final http.Response response;

    try {
      response = await _client
          .get(
            AppConfig.apiUri(path),
            headers: {'Accept': 'application/json'},
          )
          .timeout(_timeout);
    } on TimeoutException {
      throw const ClienteDetalhesException(
        'O servidor demorou para responder. Tente novamente.',
      );
    } on http.ClientException {
      throw const ClienteDetalhesException(
        'Não foi possível conectar à API.',
      );
    }

    // Uma resposta antiga não deve carregar dados de outra sessão.
    await _conferirSessao(token);

    switch (response.statusCode) {
      case 200:
        break;

      case 401:
        throw const ClienteDetalhesException(
          'Sessão expirada. Entre novamente.',
          statusCode: 401,
        );

      case 403:
        throw const ClienteDetalhesException(
          'Você não tem permissão para visualizar esta demanda.',
          statusCode: 403,
        );

      case 404:
        throw const ClienteDetalhesException(
          'Demanda não encontrada ou fora do seu acesso.',
          statusCode: 404,
        );

      default:
        throw ClienteDetalhesException(
          'Não foi possível consultar a demanda '
          '(HTTP ${response.statusCode}).',
          statusCode: response.statusCode,
        );
    }

    try {
      return jsonDecode(utf8.decode(response.bodyBytes));
    } on FormatException {
      throw const ClienteDetalhesException(
        'A API retornou um JSON inválido.',
      );
    }
  }

  Future<void> _conferirSessao(String token) async {
    if (await LocalStorageService.getToken() != token) {
      throw const ClienteDetalhesException(
        'A sessão mudou. Abra novamente a demanda.',
        statusCode: 401,
      );
    }
  }

  void dispose() {
    if (_ownsClient) {
      _client.close();
    }
  }
}
