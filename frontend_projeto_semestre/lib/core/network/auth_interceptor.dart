import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../storage/local_storage_service.dart';
import '../../features/home/presentation/pages/login_screen.dart';
import '../../features/home/presentation/pages/demanda_store.dart';
import '../../features/admin/data/services/usuario_atual_store.dart';

class AuthInterceptorClient extends http.BaseClient {
  final http.Client _inner;
  final GlobalKey<NavigatorState> navigatorKey;

  static bool _redirecionamentoAgendado = false;

  AuthInterceptorClient({required this.navigatorKey, http.Client? inner})
    : _inner = inner ?? http.Client();

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final isLogin = request.url.path.endsWith('/auth/login');

    String? token;

    if (isLogin) {
      // O login não pode reutilizar um Bearer antigo.
      request.headers.remove('Authorization');
    } else {
      token = await LocalStorageService.getToken();

      if (token != null && token.isNotEmpty) {
        request.headers['Authorization'] = 'Bearer $token';
      }
    }

    final response = await _inner.send(request);

    // SCRUM-116:
    // Trata somente respostas 401 de requisições
    // autenticadas com um token realmente utilizado.
    if (!isLogin &&
        response.statusCode == 401 &&
        token != null &&
        token.isNotEmpty) {
      // Invalida somente se o token ainda pertence
      // à sessão atual.
      final precisaRedirecionar = LocalStorageService.invalidarSeAtual(token);

      if (precisaRedirecionar) {
        // Limpa o perfil e as demandas da sessão expirada.
        UsuarioAtualStore.instance.limparSessao();
        DemandaStore.instance.limpar();

        // Redireciona uma única vez ao login.
        _redirecionarParaLogin();
      }
    }

    return response;
  }

  void _redirecionarParaLogin() {
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

        // Remove as telas anteriores do histórico.
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
