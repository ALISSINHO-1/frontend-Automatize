
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../storage/local_storage_service.dart';
import '../../features/home/presentation/pages/login_screen.dart';

class AuthInterceptorClient extends http.BaseClient {
  final http.Client _inner;
  final GlobalKey<NavigatorState> navigatorKey;

  static bool _redirecionamentoAgendado = false;

  AuthInterceptorClient({
    required this.navigatorKey,
    http.Client? inner,
  }) : _inner = inner ?? http.Client();

  @override
  Future<http.StreamedResponse> send(
    http.BaseRequest request,
  ) async {
    final isLogin = request.url.path.endsWith('/auth/login');

    String? token;

    // A rota de login é pública e não recebe Bearer Token.
    if (isLogin) {
      request.headers.remove('Authorization');
    } else {
      token = await LocalStorageService.getToken();

      if (token != null && token.isNotEmpty) {
        request.headers['Authorization'] = 'Bearer $token';
      }
    }

    final response = await _inner.send(request);

    // Uma resposta 401 em rota protegida indica sessão inválida.
    if (!isLogin && response.statusCode == 401) {
      final precisaRedirecionar =
          LocalStorageService.invalidarSeAtual(token);

      if (precisaRedirecionar) {
        _redirecionarParaLogin();
      }
    }

    return response;
  }

  void _redirecionarParaLogin() {
    // Evita agendar redirecionamentos simultâneos.
    if (_redirecionamentoAgendado) {
      return;
    }

    _redirecionamentoAgendado = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        final navigator = navigatorKey.currentState;

        if (navigator == null || !navigator.mounted) {
          return;
        }

        // Remove as telas anteriores do histórico de navegação.
        navigator.pushAndRemoveUntil(
          MaterialPageRoute<void>(
            settings: const RouteSettings(name: '/login'),
            builder: (_) => const LoginScreen(),
          ),
          (route) => false,
        );
      } finally {
        _redirecionamentoAgendado = false;
      }
    });

    WidgetsBinding.instance.scheduleFrame();
  }

  @override
  void close() {
    _inner.close();
    super.close();
  }
}
