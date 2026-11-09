import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../../../app/routes/app_routes.dart';
import '../../../../core/config/app_config.dart';
import '../../widgets/turnstile_challenge.dart';

/// Solicita link de reset sem revelar a existencia da conta.
class EsqueciSenhaScreen extends StatefulWidget {
  const EsqueciSenhaScreen({super.key, this.client, this.reenviarConfirmacao = false});
  final bool reenviarConfirmacao;
  final http.Client? client;
  @override
  State<EsqueciSenhaScreen> createState() => _EsqueciSenhaScreenState();
}

class _EsqueciSenhaScreenState extends State<EsqueciSenhaScreen> {
  final _email = TextEditingController();
  String? _token;
  String? _erro;
  bool _enviando = false;
  bool _concluido = false;
  int _desafio = 0;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _solicitar() async {
    if (_enviando) return;
    if (!(widget.reenviarConfirmacao
        ? AppConfig.publicSignupEnabled : AppConfig.passwordRecoveryEnabled)
        || AppConfig.turnstileSiteKey.isEmpty) {
      setState(() => _erro = 'A recuperação está temporariamente indisponível.');
      return;
    }
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(_email.text.trim())) {
      setState(() => _erro = 'Informe um e-mail válido.');
      return;
    }
    if (_token == null) {
      setState(() => _erro = 'Conclua a verificação antirobô.');
      return;
    }
    setState(() { _enviando = true; _erro = null; });
    final client = widget.client ?? http.Client();
    try {
      final response = await client.post(
        AppConfig.apiUri(widget.reenviarConfirmacao
            ? '/auth/verificacao/reenviar' : '/auth/senha/solicitar'),
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': _email.text.trim().toLowerCase(),
          'turnstile_token': _token,
        }),
      ).timeout(const Duration(seconds: 15));
      if (!mounted) return;
      if (response.statusCode == 202) {
        setState(() => _concluido = true);
      } else {
        setState(() => _erro = 'Não foi possível processar a solicitação.');
      }
    } on TimeoutException {
      if (mounted) setState(() => _erro = 'Tempo de conexão esgotado.');
    } catch (_) {
      if (mounted) setState(() => _erro = 'Erro ao conectar ao servidor.');
    } finally {
      if (widget.client == null) client.close();
      if (mounted) setState(() {
        _enviando = false;
        _token = null;
        _desafio++;
      });
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFF07172A),
    appBar: AppBar(backgroundColor: const Color(0xFF07172A),
        title: Text(widget.reenviarConfirmacao ? 'Reenviar confirmação' : 'Recuperar senha')),
    body: Center(
      child: SingleChildScrollView(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 530),
          child: Card(
            color: const Color(0xFF102743),
            margin: const EdgeInsets.all(22),
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.mark_email_read_outlined,
                    color: Color(0xFF21B7FF), size: 58),
                const SizedBox(height: 20),
                Text(_concluido ? 'Confira seu e-mail'
                    : (widget.reenviarConfirmacao ? 'Confirmar sua conta' : 'Esqueceu sua senha?'),
                  style: const TextStyle(
                    color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 14),
                Text(_concluido
                    ? 'Se existir uma conta com esse endereço, você receberá um link seguro.'
                    : (widget.reenviarConfirmacao
                       ? 'Informe seu e-mail e conclua o desafio para solicitar uma nova confirmação.'
                       : 'Informe seu e-mail e conclua a verificação para solicitar um link de redefinição.'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Color(0xFF9DB1C8), height: 1.5)),
                if (!_concluido) ...[
                  const SizedBox(height: 18),
                  TextField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: const [AutofillHints.email],
                    decoration: const InputDecoration(labelText: 'E-mail'),
                    style: const TextStyle(color: Colors.white),
                  ),
                  if (AppConfig.turnstileSiteKey.isNotEmpty)
                    TurnstileChallenge(
                      key: ValueKey(_desafio),
                      siteKey: AppConfig.turnstileSiteKey,
                      onToken: (token) {
                        if (mounted) setState(() => _token = token);
                      },
                    ),
                ],
                if (_erro != null) Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(_erro!, style: const TextStyle(color: Colors.redAccent))),
                const SizedBox(height: 22),
                FilledButton(
                  onPressed: _concluido
                    ? () => Navigator.of(context).pushNamedAndRemoveUntil(
                        AppRoutes.login, (_) => false)
                    : (_enviando ? null : _solicitar),
                  child: Text(_concluido ? 'Voltar ao login' : 'Solicitar link'),
                ),
              ]),
            ),
          ),
        ),
      ),
    ),
  );
}
