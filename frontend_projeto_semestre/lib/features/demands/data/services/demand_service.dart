import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../../core/config/app_config.dart';
import '../../../../core/network/api_paths.dart';
import '../models/pedido_model.dart';

class DemandService {
  const DemandService();

  
  Future<List<PedidoModel>> buscarDemandas() async {
    final resposta = await http.get(
      AppConfig.apiUri(ApiPaths.demandas),
    );

    if (resposta.statusCode != 200) {
      throw Exception(
        'Erro ao carregar demandas (HTTP ${resposta.statusCode}).',
      );
    }

    final dados = jsonDecode(utf8.decode(resposta.bodyBytes));

    if (dados is! List) {
      throw const FormatException(
        'A API não retornou uma lista de demandas.',
      );
    }

    return dados.map((item) {
      if (item is! Map<String, dynamic>) {
        throw const FormatException(
          'Uma demanda veio em formato inválido.',
        );
      }

      return PedidoModel.fromJson(item);
    }).toList();
  }

  Future<void> criarDemanda(String titulo, String descricao) async {
    // Integração da segunda opção utilizando o AppConfig
    final url = Uri.parse('${AppConfig.apiBaseUrl}/demandas');
    
    final resposta = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'titulo': titulo,
        'descricao': descricao,
      }),
    );

    if (resposta.statusCode != 200 && resposta.statusCode != 201) {
      throw Exception('Falha ao criar demanda: ${resposta.body}');
    }
  }
}
