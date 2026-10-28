
import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../../app/app.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/network/api_paths.dart';
import '../../../../core/network/auth_interceptor.dart';
import '../models/pedido_model.dart';

class DemandServiceException implements Exception {
  final String mensagem;
  final int? statusCode;

  const DemandServiceException(
    this.mensagem, {
    this.statusCode,
  });

  @override
  String toString() => mensagem;
}

class DemandService {
  DemandService({http.Client? client})
      : _client = client ??
            AuthInterceptorClient(
              navigatorKey: appNavigatorKey,
            ),
        _ownsClient = client == null;

  static const _timeout = Duration(seconds: 15);

  final http.Client _client;
  final bool _ownsClient;

  // Consulta as demandas cadastradas na API.
  Future<List<PedidoModel>> buscarDemandas() async {
    final resposta = await _executar(
      () => _client.get(
        AppConfig.apiUri(ApiPaths.demandas),
        headers: {'Accept': 'application/json'},
      ),
    );

    _verificarStatus(
      resposta,
      esperado: 200,
      operacao: 'carregar demandas',
    );

    final dynamic dados;

    try {
      dados = jsonDecode(utf8.decode(resposta.bodyBytes));
    } on FormatException {
      throw const DemandServiceException(
        'A API retornou um JSON inválido.',
      );
    }

    if (dados is! List) {
      throw const DemandServiceException(
        'A API não retornou uma lista de demandas.',
      );
    }

    try {
      return dados.map((item) {
        if (item is! Map<String, dynamic>) {
          throw const FormatException(
            'Uma demanda está em formato inválido.',
          );
        }

        return PedidoModel.fromJson(item);
      }).toList();
    } on FormatException catch (erro) {
      throw DemandServiceException(
        'Dados inválidos recebidos da API: ${erro.message}',
      );
    }
  }

  // Cadastra uma nova demanda na API.
  Future<void> criarDemanda(
    String titulo,
    String descricao,
  ) async {
    final resposta = await _executar(
      () => _client.post(
        AppConfig.apiUri(ApiPaths.demandas),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'titulo': titulo,
          'descricao': descricao,
        }),
      ),
    );

    _verificarStatus(
      resposta,
      esperado: 201,
      operacao: 'criar demanda',
    );
  }

  // Trata falhas de comunicação e timeout.
  Future<http.Response> _executar(
    Future<http.Response> Function() requisicao,
  ) async {
    try {
      return await requisicao().timeout(_timeout);
    } on TimeoutException {
      throw const DemandServiceException(
        'O servidor demorou para responder. Tente novamente.',
      );
    } on http.ClientException {
      throw const DemandServiceException(
        'Não foi possível conectar à API. Verifique sua conexão.',
      );
    }
  }

  // Valida os códigos HTTP retornados pela API.
  void _verificarStatus(
    http.Response resposta, {
    required int esperado,
    required String operacao,
  }) {
    if (resposta.statusCode == esperado) return;

    final detalhe = _detalheFastApi(resposta);

    final mensagem = switch (resposta.statusCode) {
      401 => 'Sua sessão expirou. Faça login novamente.',
      403 => 'Você não tem permissão para realizar esta operação.',
      404 => 'O recurso solicitado não foi encontrado.',
      422 => detalhe == null
          ? 'Os dados enviados não foram aceitos pela API.'
          : 'Dados inválidos: $detalhe',
      _ => 'Não foi possível $operacao '
          '(HTTP ${resposta.statusCode}).',
    };

    throw DemandServiceException(
      mensagem,
      statusCode: resposta.statusCode,
    );
  }

  // Extrai mensagens de validação da FastAPI.
  static String? _detalheFastApi(http.Response resposta) {
    try {
      final dados = jsonDecode(
        utf8.decode(resposta.bodyBytes),
      );

      if (dados is! Map<String, dynamic>) {
        return null;
      }

      final detalhe = dados['detail'];

      if (detalhe is String && detalhe.trim().isNotEmpty) {
        return detalhe;
      }

      if (detalhe is List) {
        final mensagens = detalhe
            .whereType<Map>()
            .map((erro) => erro['msg'])
            .whereType<String>()
            .toList();

        if (mensagens.isNotEmpty) {
          return mensagens.join('; ');
        }
      }
    } on FormatException {
      // Alguns erros da API podem não retornar JSON.
    }

    return null;
  }

  void dispose() {
    if (_ownsClient) {
      _client.close();
    }
  }
}
