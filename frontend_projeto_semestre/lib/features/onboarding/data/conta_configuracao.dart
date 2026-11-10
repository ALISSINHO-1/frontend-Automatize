import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/config/app_config.dart';

/// Disponibilidade real de cadastro/recuperacao, consultada na API.
class ContaConfiguracao {
  const ContaConfiguracao({
    required this.cadastroHabilitado,
    required this.recuperacaoHabilitada,
    required this.turnstileSiteKey,
  });

  final bool cadastroHabilitado;
  final bool recuperacaoHabilitada;
  /// Chave publica, nunca o secret do Turnstile.
  final String turnstileSiteKey;

  static Future<ContaConfiguracao> consultar(http.Client client) async {
    final response = await client
        .get(AppConfig.apiUri('/auth/conta/config'))
        .timeout(const Duration(seconds: 8));
    if (response.statusCode != 200) {
      throw StateError('Nao foi possivel consultar a disponibilidade.');
    }
    final data = jsonDecode(response.body);
    if (data is! Map<String, dynamic>) {
      throw const FormatException('Configuracao de conta invalida.');
    }
    final key = data['turnstile_site_key'];
    final siteKey = key is String ? key.trim() : '';
    return ContaConfiguracao(
      cadastroHabilitado:
          data['cadastro_habilitado'] == true && siteKey.isNotEmpty,
      recuperacaoHabilitada:
          data['recuperacao_habilitada'] == true && siteKey.isNotEmpty,
      turnstileSiteKey: siteKey,
    );
  }
}
