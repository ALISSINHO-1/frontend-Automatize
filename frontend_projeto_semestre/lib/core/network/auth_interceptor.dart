import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../storage/local_storage_service.dart';
import '../../features/home/presentation/pages/login_screen.dart';

class AuthInterceptorClient extends http.BaseClient {
  final http.Client _inner;
  final GlobalKey<NavigatorState> navigatorKey;

  bool _redirecionando = false;

  AuthInterceptorClient({
    required this.navigatorKey,
    http.Client? inner,
  }) : _inner = inner ?? http.Client();

  @override
  Future<http.StreamedResponse> send(
    http.BaseRequest request,
  ) async {
    // Recupera o token salvo após o login.
    final token = await LocalStorageService.getToken();

    // Adiciona o Bearer Token quando existir.
    if (token != null && token.isNotEmpty) {
      request.headers['Authorization'] = 'Bearer $token';
    }

    final response = await _inner.send(request);

    // O token expirou ou não é válido.
    if (response.statusCode == 401) {
      await LocalStorageService.removeToken();

      if (!_redirecionando) {
        _redirecionando = true;

        WidgetsBinding.instance.addPostFrameCallback((_) {
          final navigator = navigatorKey.currentState;

          if (navigator != null && navigator.mounted) {
            navigator.pushAndRemoveUntil(
              MaterialPageRoute<void>(
                builder: (_) => const LoginScreen(),
              ),
              (route) => false,
            );
          }

          _redirecionando = false;
        });
      }
    }

    return response;
  }

  @override
  void close() {
    _inner.close();
    super.close();
  }
}
