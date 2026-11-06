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

  const DemandServiceException(this.mensagem, {this.statusCode});

  @override
  String toString() => mensagem;
}

class DemandService {
  DemandService({http.Client? client})
    : _client = client ?? AuthInterceptorClient(navigatorKey: appNavigatorKey),
      _ownsClient = client == null;

  static const _timeout = Duration(seconds: 15);

  final http.Client _client;
  final bool _ownsClient;

  // ============================================
  // LISTAGEM DE DEMANDAS
  // ============================================

  // Consulta todas as demandas cadastradas na API.
  Future<List<PedidoModel>> buscarDemandas() async {
    const tamanhoPagina = 100;
    final demandas = <PedidoModel>[];

    while (true) {
      final pagina = await _buscarPagina(demandas.length, tamanhoPagina);

      demandas.addAll(pagina);

      if (pagina.length < tamanhoPagina) {
        return demandas;
      }
    }
  }

  // Busca uma página de demandas.
  Future<List<PedidoModel>> _buscarPagina(int offset, int limit) async {
    final resposta = await _executar(
      () => _client.get(
        AppConfig.apiUri(
          ApiPaths.demandas,
        ).replace(queryParameters: {'offset': '$offset', 'limit': '$limit'}),
        headers: {'Accept': 'application/json'},
      ),
    );

    _verificarStatus(resposta, esperado: 200, operacao: 'carregar demandas');

    final dynamic dados;

    try {
      dados = jsonDecode(utf8.decode(resposta.bodyBytes));
    } on FormatException {
      throw const DemandServiceException('A API retornou um JSON inválido.');
    }

    if (dados is! List) {
      throw const DemandServiceException(
        'A API não retornou uma lista de demandas.',
      );
    }

    try {
      return dados.map((item) {
        if (item is! Map<String, dynamic>) {
          throw const FormatException('Uma demanda está em formato inválido.');
        }

        return PedidoModel.fromJson(item);
      }).toList();
    } on FormatException catch (erro) {
      throw DemandServiceException(
        'Dados inválidos recebidos da API: ${erro.message}',
      );
    }
  }

  // ============================================
  // CADASTRO DE DEMANDAS
  // ============================================

  // Cadastra uma nova demanda na API.
  Future<void> criarDemanda(String titulo, String descricao) async {
    final resposta = await _executar(
      () => _client.post(
        AppConfig.apiUri(ApiPaths.demandas),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'titulo': titulo, 'descricao': descricao}),
      ),
    );

    _verificarStatus(resposta, esperado: 201, operacao: 'criar demanda');
  }

  // ============================================
  // EDIÇÃO DE DEMANDAS - SCRUM-60
  // ============================================

  // Atualiza título e descrição de uma demanda.
  Future<void> editarDemanda({
    required String id,
    required String titulo,
    required String descricao,
  }) async {
    final idLimpo = id.trim();
    final tituloLimpo = titulo.trim();
    final descricaoLimpa = descricao.trim();

    // Impede envio de dados obrigatórios inválidos.
    if (idLimpo.isEmpty) {
      throw ArgumentError('O identificador da demanda é obrigatório.');
    }

    if (tituloLimpo.isEmpty) {
      throw ArgumentError('O título da demanda é obrigatório.');
    }

    // Endpoint de atualização da FastAPI.
    final url = AppConfig.apiUri(
      '${ApiPaths.demandas}/${Uri.encodeComponent(idLimpo)}',
    );

    // Envia os dados atualizados.
    final resposta = await _executar(
      () => _client.patch(
        url,
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'titulo': tituloLimpo, 'descricao': descricaoLimpa}),
      ),
    );

    // Aceita HTTP 200 ou 204 como sucesso.
    // Os códigos definitivos precisam ser
    // conferidos no OpenAPI da API utilizada.
    if (resposta.statusCode != 200 && resposta.statusCode != 204) {
      _verificarStatus(resposta, esperado: 200, operacao: 'editar demanda');
    }
  }

  // ============================================
  // COMUNICAÇÃO COM A API
  // ============================================

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

  // ============================================
  // TRATAMENTO DE STATUS HTTP
  // ============================================

  void _verificarStatus(
    http.Response resposta, {
    required int esperado,
    required String operacao,
  }) {
    if (resposta.statusCode == esperado) {
      return;
    }

    final detalhe = _detalheFastApi(resposta);

    final mensagem = switch (resposta.statusCode) {
      401 => 'Sua sessão expirou. Faça login novamente.',

      403 => 'Você não tem permissão para realizar esta operação.',

      404 => 'O recurso solicitado não foi encontrado.',

      422 =>
        detalhe == null
            ? 'Os dados enviados não foram aceitos pela API.'
            : 'Dados inválidos: $detalhe',

      _ =>
        'Não foi possível $operacao '
            '(HTTP ${resposta.statusCode}).',
    };

    throw DemandServiceException(mensagem, statusCode: resposta.statusCode);
  }

  // ============================================
  // MENSAGENS DE ERRO DA FASTAPI
  // ============================================

  static String? _detalheFastApi(http.Response resposta) {
    try {
      final dados = jsonDecode(utf8.decode(resposta.bodyBytes));

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

  // ============================================
  // LIBERAÇÃO DE RECURSOS
  // ============================================

  void dispose() {
    if (_ownsClient) {
      _client.close();
    }
  }
}
