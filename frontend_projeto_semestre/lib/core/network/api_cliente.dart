import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
export 'auth_interceptor.dart' show AuthInterceptorClient;

class AuthInterceptorClient extends http.BaseClient {
  final http.Client _inner = http.Client();
  final BuildContext? context;

  // Recebe o contexto (necessário para conseguir navegar para o Login)
  AuthInterceptorClient({this.context});

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final response = await _inner.send(request);

    // 3. INTERCEPTAÇÃO DO ERRO 401 (Requisito do SCRUM-59)
    if (response.statusCode == 401) {
      _handleUnauthorized();
    }

    return response;
  }

  void _handleUnauthorized() {
    if (context != null) {
      // Usamos pushAndRemoveUntil para limpar a pilha de ecrãs e impedir
      // que o utilizador volte atrás para um ecrã bloqueado
      Navigator.of(
        context!,
      ).pushNamedAndRemoveUntil('/login', (route) => false);
    }
  }
}
