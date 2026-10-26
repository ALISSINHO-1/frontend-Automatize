import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../../core/config/app_config.dart';
import '../../../../core/network/api_paths.dart';
import '../models/historico_estado_model.dart';
import '../models/pedido_model.dart';

class DemandApiException implements Exception {
  const DemandApiException(this.statusCode, this.message);

  final int statusCode;
  final String message;

  @override
  String toString() => message;
}

class DemandService {
  DemandService({
    required this.accessToken,
    http.Client? client,
    this.onUnauthorized,
  }) : _client = client ?? http.Client();

  final String accessToken;
  final http.Client _client;
  final void Function()? onUnauthorized;

  Future<List<PedidoModel>> buscarDemandas({
    int offset = 0,
    int limit = 100,
  }) async {
    final response = await _request(
      'GET',
      ApiPaths.demandas,
      queryParameters: {'offset': '$offset', 'limit': '$limit'},
    );
    final data = _decode(response);
    if (data is! List) {
      throw const FormatException('A API não retornou uma lista de demandas.');
    }
    return data
        .map((item) {
          if (item is! Map<String, dynamic>) {
            throw const FormatException('A API retornou uma demanda inválida.');
          }
          return PedidoModel.fromJson(item);
        })
        .toList(growable: false);
  }

  Future<PedidoModel> buscarDemanda(String id) async {
    final response = await _request('GET', '${ApiPaths.demandas}/$id');
    final data = _decode(response);
    if (data is! Map<String, dynamic>) {
      throw const FormatException('A API retornou uma demanda inválida.');
    }
    return PedidoModel.fromJson(data);
  }

  Future<List<PedidoModel>> buscarTodasDemandas() async {
    const pageSize = 100;
    final demands = <PedidoModel>[];
    var offset = 0;
    while (true) {
      final page = await buscarDemandas(offset: offset, limit: pageSize);
      demands.addAll(page);
      if (page.length < pageSize) return demands;
      offset += pageSize;
    }
  }

  Future<List<HistoricoEstadoModel>> buscarHistorico(String id) async {
    final response = await _request(
      'GET',
      '${ApiPaths.demandas}/$id/historico',
    );
    final data = _decode(response);
    if (data is! List) {
      throw const FormatException('A API não retornou uma lista de histórico.');
    }
    return data
        .map((item) {
          if (item is! Map<String, dynamic>) {
            throw const FormatException('A API retornou um evento inválido.');
          }
          return HistoricoEstadoModel.fromJson(item);
        })
        .toList(growable: false);
  }

  Future<List<EtapaOperacionalModel>> buscarEtapas(String id) async {
    final response = await _request('GET', '${ApiPaths.demandas}/$id/etapas');
    final data = _decode(response);
    if (data is! List) {
      throw const FormatException('A API não retornou uma lista de etapas.');
    }
    return data
        .map((item) {
          if (item is! Map<String, dynamic>) {
            throw const FormatException('A API retornou uma etapa inválida.');
          }
          return EtapaOperacionalModel.fromJson(item);
        })
        .toList(growable: false);
  }

  Future<void> aprovarHomologacao(
    String id, {
    required String versaoEntregavel,
    required String declaracaoAceite,
  }) async {
    await _request(
      'POST',
      '${ApiPaths.demandas}/$id/aceite',
      body: {
        'versao_entregavel': versaoEntregavel,
        'declaracao_aceite': declaracaoAceite,
      },
    );
  }

  Future<void> rejeitarHomologacao(String id, {required String motivo}) async {
    await _request(
      'POST',
      '${ApiPaths.demandas}/$id/rejeicao',
      body: {'motivo': motivo},
    );
  }

  Future<PedidoModel> alterarStatus(String id, String novoStatus) async {
    final response = await _request(
      'POST',
      '${ApiPaths.demandas}/$id/status',
      body: {'status': novoStatus},
    );
    final data = _decode(response);
    if (data is! Map<String, dynamic>) {
      throw const FormatException('A API não retornou a demanda atualizada.');
    }
    return PedidoModel.fromJson(data);
  }

  Future<EtapaOperacionalModel> adicionarEtapa(
    String id, {
    required String descricao,
  }) async {
    final response = await _request(
      'POST',
      '${ApiPaths.demandas}/$id/etapas',
      body: {'descricao': descricao},
    );
    final data = _decode(response);
    if (data is! Map<String, dynamic>) {
      throw const FormatException('A API não retornou a etapa criada.');
    }
    return EtapaOperacionalModel.fromJson(data);
  }

  Future<EtapaOperacionalModel> concluirEtapa(String id, String etapaId) async {
    final response = await _request(
      'POST',
      '${ApiPaths.demandas}/$id/etapas/$etapaId/conclusao',
    );
    final data = _decode(response);
    if (data is! Map<String, dynamic>) {
      throw const FormatException('A API não retornou a etapa atualizada.');
    }
    return EtapaOperacionalModel.fromJson(data);
  }

  Future<http.Response> _request(
    String method,
    String path, {
    Map<String, String>? queryParameters,
    Map<String, Object?>? body,
  }) async {
    if (accessToken.isEmpty) {
      throw const DemandApiException(
        401,
        'Sua sessão expirou. Entre novamente.',
      );
    }
    final uri = AppConfig.apiUri(
      path,
    ).replace(queryParameters: queryParameters);
    final headers = <String, String>{
      'Authorization': 'Bearer $accessToken',
      if (body != null) 'Content-Type': 'application/json',
    };
    late final http.Response response;
    try {
      final request = http.Request(method, uri)..headers.addAll(headers);
      if (body != null) request.body = jsonEncode(body);
      final streamed = await _client
          .send(request)
          .timeout(const Duration(seconds: 20));
      response = await http.Response.fromStream(streamed);
    } on http.ClientException {
      throw const DemandApiException(0, 'Não foi possível conectar à API.');
    } on TimeoutException {
      throw const DemandApiException(0, 'A API demorou para responder.');
    }

    if (response.statusCode == 401) {
      onUnauthorized?.call();
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message = switch (response.statusCode) {
        401 => 'Sua sessão expirou. Entre novamente.',
        403 => 'Você não tem permissão para esta operação.',
        404 =>
          'A demanda não foi encontrada ou não está disponível para esta conta.',
        422 =>
          'A API recusou os dados enviados. Confira os campos e tente novamente.',
        _ => 'Falha na API: HTTP ${response.statusCode}.',
      };
      throw DemandApiException(response.statusCode, message);
    }
    return response;
  }

  dynamic _decode(http.Response response) {
    if (response.bodyBytes.isEmpty) return null;
    return jsonDecode(utf8.decode(response.bodyBytes));
  }

  void dispose() => _client.close();
}

class EtapaOperacionalModel {
  const EtapaOperacionalModel({
    required this.id,
    required this.descricao,
    required this.concluida,
    this.concluidaEm,
  });

  final String id;
  final String descricao;
  final bool concluida;
  final DateTime? concluidaEm;

  factory EtapaOperacionalModel.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final descricao = json['descricao'];
    final concluida = json['concluida'];
    if (id is! String || descricao is! String || concluida is! bool) {
      throw const FormatException('A API retornou uma etapa inválida.');
    }
    return EtapaOperacionalModel(
      id: id,
      descricao: descricao,
      concluida: concluida,
      concluidaEm: DateTime.tryParse(json['concluida_em']?.toString() ?? ''),
    );
  }
}
