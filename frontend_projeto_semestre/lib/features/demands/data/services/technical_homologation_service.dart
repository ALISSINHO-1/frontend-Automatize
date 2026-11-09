import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../../app/app.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/network/auth_interceptor.dart';
import '../models/pedido_model.dart';

class TechnicalHomologationException implements Exception {
  const TechnicalHomologationException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

class TechnicalHomologationService {
  TechnicalHomologationService({http.Client? client})
    : _client = client ?? AuthInterceptorClient(navigatorKey: appNavigatorKey),
      _ownsClient = client == null;

  static const Duration _timeout = Duration(seconds: 15);

  final http.Client _client;
  final bool _ownsClient;

  Map<String, String> get _headers => const {
    'Accept': 'application/json',
    'Content-Type': 'application/json',
  };

  String _demandaPath(String demandaId) {
    return '/demandas/${Uri.encodeComponent(demandaId)}';
  }

  Future<PedidoModel> buscarDemanda(String demandaId) async {
    final resposta = await _executar(
      () => _client.get(
        AppConfig.apiUri(_demandaPath(demandaId)),
        headers: _headers,
      ),
    );

    _verificarStatus(resposta, esperado: 200, operacao: 'consultar demanda');

    return _lerDemanda(resposta);
  }

  Future<PedidoModel> enviarParaHomologacao(String demandaId) async {
    final resposta = await _executar(
      () => _client.post(
        AppConfig.apiUri('${_demandaPath(demandaId)}/status'),
        headers: _headers,
        body: jsonEncode({'status': 'HOMOLOGACAO'}),
      ),
    );

    _verificarStatus(
      resposta,
      esperado: 200,
      operacao: 'enviar demanda para homologação',
    );

    return _lerDemanda(resposta);
  }

  PedidoModel _lerDemanda(http.Response resposta) {
    try {
      final dados = jsonDecode(utf8.decode(resposta.bodyBytes));

      if (dados is! Map<String, dynamic>) {
        throw const FormatException('Objeto de demanda inválido.');
      }

      return PedidoModel.fromJson(dados);
    } on FormatException catch (erro) {
      throw TechnicalHomologationException(
        'Resposta inválida da API: ${erro.message}',
      );
    }
  }

  Future<http.Response> _executar(
    Future<http.Response> Function() requisicao,
  ) async {
    try {
      return await requisicao().timeout(_timeout);
    } on TimeoutException {
      throw const TechnicalHomologationException(
        'O servidor demorou para responder. Tente novamente.',
      );
    } on http.ClientException {
      throw const TechnicalHomologationException(
        'Não foi possível conectar à API.',
      );
    }
  }

  void _verificarStatus(
    http.Response resposta, {
    required int esperado,
    required String operacao,
  }) {
    if (resposta.statusCode == esperado) return;

    final detalhe = _lerDetalhe(resposta);

    final mensagem = switch (resposta.statusCode) {
      401 => 'Sua sessão expirou. Entre novamente.',
      403 => 'Você não tem permissão para realizar esta operação.',
      404 => 'Demanda não encontrada ou fora do seu acesso.',
      409 =>
        detalhe ??
            'A demanda não pode ser enviada para homologação '
                'no estado atual. Verifique as etapas pendentes.',
      422 => detalhe ?? 'A API rejeitou os dados enviados.',
      _ => 'Erro ao $operacao (HTTP ${resposta.statusCode}).',
    };

    throw TechnicalHomologationException(
      mensagem,
      statusCode: resposta.statusCode,
    );
  }

  String? _lerDetalhe(http.Response resposta) {
    try {
      final dados = jsonDecode(utf8.decode(resposta.bodyBytes));

      if (dados is! Map<String, dynamic>) return null;

      final detalhe = dados['detail'];

      if (detalhe is String && detalhe.trim().isNotEmpty) {
        return detalhe;
      }

      if (detalhe is List) {
        final mensagens = detalhe
            .whereType<Map>()
            .map((item) => item['msg'])
            .whereType<String>()
            .toList();

        if (mensagens.isNotEmpty) {
          return mensagens.join('; ');
        }
      }
    } on FormatException {
      // Algumas respostas HTTP não possuem JSON.
    }

    return null;
  }

  void dispose() {
    if (_ownsClient) {
      _client.close();
    }
  }
}
