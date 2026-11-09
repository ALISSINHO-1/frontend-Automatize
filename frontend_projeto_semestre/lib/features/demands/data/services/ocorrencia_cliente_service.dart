
import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../../app/app.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/network/api_paths.dart';
import '../../../../core/network/auth_interceptor.dart';
import '../../../../core/storage/local_storage_service.dart';

class OcorrenciaClienteException implements Exception {
  const OcorrenciaClienteException(
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

class OcorrenciaClienteService {
  OcorrenciaClienteService({http.Client? client})
      : _client = client ??
            AuthInterceptorClient(navigatorKey: appNavigatorKey),
        _ownsClient = client == null;

  final http.Client _client;
  final bool _ownsClient;

  static const Duration _timeout = Duration(seconds: 15);

  String _caminho(String demandaId) {
    final id = demandaId.trim();

    if (id.isEmpty) {
      throw const OcorrenciaClienteException(
        'Identificador da demanda ausente.',
      );
    }

    return '${ApiPaths.demandas}/'
        '${Uri.encodeComponent(id)}/ocorrencias';
  }

  /// GET /demandas/{id}/ocorrencias
  Future<List<Map<String, dynamic>>> listar(
    String demandaId,
  ) async {
    final response = await _requisitar(
      demandaId: demandaId,
      metodo: 'GET',
      esperado: 200,
    );

    final dynamic conteudo;

    try {
      conteudo = jsonDecode(
        utf8.decode(response.bodyBytes),
      );
    } on FormatException {
      throw const OcorrenciaClienteException(
        'A API retornou um JSON inválido.',
      );
    }

    if (conteudo is! List) {
      throw const OcorrenciaClienteException(
        'A API não retornou uma lista de ocorrências.',
      );
    }

    return conteudo
        .map((item) => _validarOcorrencia(item, demandaId))
        .toList();
  }

  /// POST /demandas/{id}/ocorrencias
  Future<Map<String, dynamic>> criar({
    required String demandaId,
    required String tipo,
    required String descricao,
  }) async {
    final tipoFinal = tipo.trim();
    final descricaoFinal = descricao.trim();

    if (tipoFinal != 'ERRO' &&
        tipoFinal != 'SOLICITACAO_CORRECAO') {
      throw const OcorrenciaClienteException(
        'Selecione um tipo de ocorrência válido.',
      );
    }

    if (descricaoFinal.length < 10 ||
        descricaoFinal.length > 2000) {
      throw const OcorrenciaClienteException(
        'A descrição deve ter entre 10 e '
        '2.000 caracteres.',
      );
    }

    final response = await _requisitar(
      demandaId: demandaId,
      metodo: 'POST',
      esperado: 201,
      body: {
        'tipo': tipoFinal,
        'descricao': descricaoFinal,
      },
    );

    try {
      final conteudo = jsonDecode(
        utf8.decode(response.bodyBytes),
      );

      return _validarOcorrencia(conteudo, demandaId);
    } on FormatException {
      throw const OcorrenciaClienteException(
        'A API confirmou o cadastro, mas '
        'retornou uma resposta inválida. '
        'Atualize a lista antes de tentar novamente.',
        resultadoIncerto: true,
      );
    }
  }

  Map<String, dynamic> _validarOcorrencia(
    dynamic conteudo,
    String demandaId,
  ) {
    if (conteudo is! Map<String, dynamic>) {
      throw const OcorrenciaClienteException(
        'A ocorrência retornada está em formato inválido.',
      );
    }

    if (conteudo['id'] is! String ||
        conteudo['autor_id'] is! String ||
        conteudo['pedido_id']?.toString() !=
            demandaId.trim()) {
      throw const OcorrenciaClienteException(
        'A API retornou uma ocorrência incompatível '
        'com a demanda selecionada.',
      );
    }

    return conteudo;
  }

  Future<http.Response> _requisitar({
    required String demandaId,
    required String metodo,
    required int esperado,
    Map<String, dynamic>? body,
  }) async {
    final token = await LocalStorageService.getToken();

    if (token == null || token.trim().isEmpty) {
      throw const OcorrenciaClienteException(
        'Faça login para acessar as ocorrências.',
        statusCode: 401,
      );
    }

    final uri = AppConfig.apiUri(
      _caminho(demandaId),
    );

    late final http.Response response;

    try {
      if (metodo == 'GET') {
        response = await _client
            .get(
              uri,
              headers: {
                'Accept': 'application/json',
              },
            )
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
      throw OcorrenciaClienteException(
        metodo == 'POST'
            ? 'O servidor demorou para responder. '
                'Verifique a lista antes de tentar novamente.'
            : 'O servidor demorou para responder.',
        resultadoIncerto: metodo == 'POST',
      );
    } on http.ClientException {
      throw OcorrenciaClienteException(
        metodo == 'POST'
            ? 'A conexão falhou durante o envio. '
                'Verifique a lista antes de tentar novamente.'
            : 'Não foi possível conectar à API.',
        resultadoIncerto: metodo == 'POST',
      );
    }

    // Respostas da sessão A não podem ser
    // reutilizadas pela sessão B.
    if (await LocalStorageService.getToken() != token) {
      throw const OcorrenciaClienteException(
        'A sessão mudou. Consulte novamente '
        'as ocorrências.',
        statusCode: 401,
      );
    }

    if (response.statusCode != esperado) {
      final mensagem = switch (response.statusCode) {
        401 => 'Sessão expirada. Faça login novamente.',
        403 => 'Você não tem permissão para '
            'acessar esta demanda.',
        404 => 'Demanda não encontrada ou '
            'fora do seu acesso.',
        409 => 'A demanda não permite esta operação '
            'no estado atual.',
        422 => 'Os dados enviados não foram aceitos '
            'pela API.',
        _ => 'Operação não realizada '
            '(HTTP ${response.statusCode}).',
      };

      throw OcorrenciaClienteException(
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
