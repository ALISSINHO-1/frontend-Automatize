import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../../../app/routes/app_routes.dart';
import '../../../../core/config/app_config.dart';

/// Confirma por POST: scanners de e-mail nao consomem o token automaticamente.
class VerificarEmailScreen extends StatefulWidget {
  const VerificarEmailScreen({super.key, this.token, this.client});

  final String? token;
  final http.Client? client;

  @override
  State<VerificarEmailScreen> createState() => _VerificarEmailScreenState();
}

class _VerificarEmailScreenState extends State<VerificarEmailScreen> {
  bool _carregando = false;
  bool _sucesso = false;
  String? _erro;

  Future<void> _verificar() async {
    final token = widget.token;
    if (_carregando || token == null || token.length < 20) {
      setState(() => _erro = 'Link de verificação inválido.');
      return;
    }
    setState(() {
      _carregando = true;
      _erro = null;
    });
    final client = widget.client ?? http.Client();
    try {
      final response = await client.post(
        AppConfig.apiUri('/auth/verificar-email'),
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode({'token': token}),
      ).timeout(const Duration(seconds: 15));
      if (!mounted) return;
      if (response.statusCode == 204) {
        setState(() => _sucesso = true);
      } else if (response.statusCode == 400) {
        setState(() => _erro = 'Este link expirou ou já foi utilizado.');
      } else {
        setState(() => _erro = 'Não foi possível verificar seu e-mail.');
      }
    } on TimeoutException {
      if (mounted) setState(() => _erro = 'A conexão expirou. Tente novamente.');
    } catch (_) {
      if (mounted) setState(() => _erro = 'Erro de conexão com o servidor.');
    } finally {
      if (widget.client == null) client.close();
      if (mounted) setState(() => _carregando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF07172A),
      appBar: AppBar(title: const Text('Verificar e-mail'),
          backgroundColor: const Color(0xFF07172A)),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Card(
            color: const Color(0xFF102743),
            margin: const EdgeInsets.all(22),
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Icon(_sucesso ? Icons.verified_rounded : Icons.mark_email_unread_outlined,
                    color: const Color(0xFF21B7FF), size: 54),
                const SizedBox(height: 18),
                Text(_sucesso ? 'E-mail confirmado' : 'Confirme seu endereço de e-mail',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        color: Colors.white, fontSize: 23, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Text(_sucesso
                    ? 'Sua identidade foi validada. A equipe ainda precisa liberar seu contrato ou vínculo empresarial.'
                    : 'Toque em confirmar para validar sua conta. Seu acesso continuará limitado até a contratação.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Color(0xFF9DB1C8), height: 1.5)),
                if (_erro != null) ...[
                  const SizedBox(height: 12),
                  Text(_erro!, style: const TextStyle(color: Color(0xFFFF7785))),
                ],
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _sucesso
                      ? () => Navigator.of(context).pushNamedAndRemoveUntil(
                            AppRoutes.login, (_) => false)
                      : (_carregando ? null : _verificar),
                  child: Text(_sucesso ? 'Ir para o login' : 'Confirmar e-mail'),
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}
