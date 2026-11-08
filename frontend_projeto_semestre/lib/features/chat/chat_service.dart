import 'dart:convert';

import '../admin/data/models/usuario_atual_model.dart';
import '../../app/app.dart';
import '../../core/config/app_config.dart';
import '../../core/network/api_paths.dart';
import '../../core/network/auth_interceptor.dart';

enum ChatCanal {
  cliente('Cliente e técnico'),
  interno('Técnico e administração');

  const ChatCanal(this.titulo);
  final String titulo;

  static List<ChatCanal> paraUsuario(UsuarioAtualModel usuario) =>
      switch (usuario.perfil) {
        'CLIENTE' => [cliente],
        'TECNICO' => values,
        'ADMIN' => [interno],
        _ => [],
      };
}

class ChatMensagem {
  ChatMensagem.fromJson(Map<String, dynamic> json)
    : autorId = json['autor_id'] as String,
      autorNome = json['autor_nome'] as String,
      texto = json['texto'] as String,
      criadoEm = DateTime.parse(json['criado_em'] as String).toLocal();

  final String autorId;
  final String autorNome;
  final String texto;
  final DateTime criadoEm;
}

class ChatService {
  final _client = AuthInterceptorClient(navigatorKey: appNavigatorKey);
  static const _timeout = Duration(seconds: 15);

  Uri _uri(String demandaId, ChatCanal canal) => AppConfig.apiUri(
    '${ApiPaths.demandas}/${Uri.encodeComponent(demandaId)}/chat/${canal.name}',
  );

  Future<({List<ChatMensagem> mensagens, String? antesDe})> historico(
    String demandaId,
    ChatCanal canal, {
    String? antesDe,
  }) async {
    final uri = _uri(demandaId, canal);
    final resposta = await _client
        .get(
          antesDe == null
              ? uri
              : uri.replace(queryParameters: {'antes_de': antesDe}),
        )
        .timeout(_timeout);
    if (resposta.statusCode != 200) throw ChatException(resposta.statusCode);
    final json =
        jsonDecode(utf8.decode(resposta.bodyBytes)) as Map<String, dynamic>;
    return (
      mensagens: (json['mensagens'] as List)
          .map((item) => ChatMensagem.fromJson(item as Map<String, dynamic>))
          .toList(),
      antesDe: json['antes_de'] as String?,
    );
  }

  Future<void> enviar(String demandaId, ChatCanal canal, String texto) async {
    final resposta = await _client
        .post(
          _uri(demandaId, canal),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'texto': texto}),
        )
        .timeout(_timeout);
    if (resposta.statusCode != 201) throw ChatException(resposta.statusCode);
  }

  void dispose() => _client.close();
}

class ChatException implements Exception {
  const ChatException(this.status);
  final int status;

  bool get acessoEncerrado => const [401, 403, 404, 409].contains(status);

  @override
  String toString() => switch (status) {
    401 => 'Sua sessão expirou.',
    403 || 404 => 'Conversa indisponível para esta conta.',
    409 => 'A demanda aguarda um técnico responsável.',
    _ => 'O chat está indisponível. Tente novamente.',
  };
}
