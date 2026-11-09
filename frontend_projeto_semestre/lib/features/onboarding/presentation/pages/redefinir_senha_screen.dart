import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../../../app/routes/app_routes.dart';
import '../../../../core/config/app_config.dart';

class RedefinirSenhaScreen extends StatefulWidget {
  const RedefinirSenhaScreen({super.key, this.token, this.client});

  final String? token;
  final http.Client? client;

  @override
  State<RedefinirSenhaScreen> createState() => _RedefinirSenhaScreenState();
}

class _RedefinirSenhaScreenState extends State<RedefinirSenhaScreen> {
  final _form = GlobalKey<FormState>();
  final _senha = TextEditingController();
  final _confirma = TextEditingController();
  bool _carregando = false;
  bool _sucesso = false;
  String? _erro;

  @override
  void dispose() {
    _senha.dispose();
    _confirma.dispose();
    super.dispose();
  }

  Future<void> _enviar() async {
    final token = widget.token;
    if (_carregando || token == null || token.length < 20) {
      setState(() => _erro = 'Link de recuperação inválido.');
      return;
    }
    if (!(_form.currentState?.validate() ?? false)) return;
    setState(() {
      _carregando = true;
      _erro = null;
    });
    final client = widget.client ?? http.Client();
    try {
      final response = await client.post(
        AppConfig.apiUri('/auth/senha/redefinir'),
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode({'token': token, 'nova_senha': _senha.text}),
      ).timeout(const Duration(seconds: 15));
      if (!mounted) return;
      if (response.statusCode == 204) {
        _senha.clear();
        _confirma.clear();
        setState(() => _sucesso = true);
      } else if (response.statusCode == 400) {
        setState(() => _erro = 'Este link expirou ou já foi utilizado.');
      } else {
        setState(() => _erro = 'Não foi possível redefinir a senha.');
      }
    } on TimeoutException {
      if (mounted) setState(() => _erro = 'A conexão expirou.');
    } catch (_) {
      if (mounted) setState(() => _erro = 'Erro de conexão com o servidor.');
    } finally {
      if (widget.client == null) client.close();
      if (mounted) setState(() => _carregando = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFF07172A),
    appBar: AppBar(title: const Text('Recuperar acesso'),
        backgroundColor: const Color(0xFF07172A)),
    body: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Card(
          color: const Color(0xFF102743),
          margin: const EdgeInsets.all(22),
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Form(
              key: _form,
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.lock_reset_outlined,
                    color: Color(0xFF21B7FF), size: 56),
                const SizedBox(height: 16),
                Text(_sucesso ? 'Senha alterada com sucesso' : 'Defina uma nova senha',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        color: Colors.white, fontSize: 23, fontWeight: FontWeight.bold)),
                if (!_sucesso) ...[
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _senha,
                    obscureText: true,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(labelText: 'Nova senha'),
                    validator: (v) {
                      final value = v ?? '';
                      if (value.length < 8) return 'Use ao menos 8 caracteres.';
                      if (utf8.encode(value).length > 72) {
                        return 'A senha não pode ultrapassar 72 bytes.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _confirma,
                    obscureText: true,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(labelText: 'Confirme a senha'),
                    validator: (v) => v == _senha.text ? null : 'Senhas diferentes.',
                  ),
                ],
                if (_erro != null) ...[
                  const SizedBox(height: 12),
                  Text(_erro!, style: const TextStyle(color: Color(0xFFFF7785))),
                ],
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _sucesso
                      ? () => Navigator.of(context).pushNamedAndRemoveUntil(
                            AppRoutes.login, (_) => false)
                      : (_carregando ? null : _enviar),
                  child: Text(_sucesso ? 'Ir para login' : 'Redefinir senha'),
                ),
              ]),
            ),
          ),
        ),
      ),
    ),
  );
}
