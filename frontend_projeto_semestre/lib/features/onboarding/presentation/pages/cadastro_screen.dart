import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../../../app/routes/app_routes.dart';
import '../../../../core/config/app_config.dart';
import '../../widgets/turnstile_challenge.dart';
import 'termos_uso_screen.dart';

/// Cadastro de interesse: conta fica pendente, sem acesso a servicos.
class CadastroScreen extends StatefulWidget {
  const CadastroScreen({super.key, this.client});

  final http.Client? client;

  @override
  State<CadastroScreen> createState() => _CadastroScreenState();
}

class _CadastroScreenState extends State<CadastroScreen> {
  static const _fundo = Color(0xFF07172A);
  static const _painel = Color(0xFF102743);
  static const _borda = Color(0xFF294866);
  static const _texto = Color(0xFFF4F7FB);
  static const _suave = Color(0xFF9DB1C8);
  static const _azul = Color(0xFF168BFF);

  final _form = GlobalKey<FormState>();
  final _nome = TextEditingController();
  final _email = TextEditingController();
  final _senha = TextEditingController();
  final _confirmacao = TextEditingController();
  bool _termosAceitos = false;
  bool _enviando = false;
  bool _concluido = false;
  String? _erro;
  String? _turnstileToken;
  int _desafioVersao = 0;

  @override
  void dispose() {
    _nome.dispose();
    _email.dispose();
    _senha.dispose();
    _confirmacao.dispose();
    super.dispose();
  }

  Future<void> _enviar() async {
    if (_enviando || !(_form.currentState?.validate() ?? false)) return;
    if (!AppConfig.publicSignupEnabled) {
      setState(() => _erro = 'Cadastro indisponível no momento.');
      return;
    }
    if (!_termosAceitos) {
      setState(() => _erro = 'Aceite os Termos de Uso para continuar.');
      return;
    }
    if (AppConfig.turnstileSiteKey.isEmpty ||
        _turnstileToken == null || _turnstileToken!.isEmpty) {
      setState(() => _erro = 'Conclua a verificação antirobô para continuar.');
      return;
    }
    setState(() {
      _enviando = true;
      _erro = null;
    });
    final client = widget.client ?? http.Client();
    try {
      final resposta = await client
          .post(
            AppConfig.apiUri('/auth/cadastro'),
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode({
              'nome': _nome.text.trim(),
              'email': _email.text.trim().toLowerCase(),
              'senha': _senha.text,
              'turnstile_token': _turnstileToken,
              'termos_aceitos': _termosAceitos,
              'termos_versao': termosUsoVersao,
            }),
          )
          .timeout(const Duration(seconds: 15));
      if (!mounted) return;
      if (resposta.statusCode == 202) {
        _senha.clear();
        _confirmacao.clear();
        setState(() => _concluido = true);
      } else if (resposta.statusCode == 503) {
        setState(() => _erro = 'Novos cadastros estão temporariamente indisponíveis.');
      } else if (resposta.statusCode == 409) {
        setState(() {
          _termosAceitos = false;
          _erro = 'Atualize a página para ler a versão vigente dos Termos de Uso.';
        });
      } else if (resposta.statusCode == 422) {
        setState(() => _erro = 'Revise seus dados e a senha informada.');
      } else {
        setState(() => _erro = 'Não foi possível receber o cadastro. Tente novamente.');
      }
    } on TimeoutException {
      if (mounted) setState(() => _erro = 'O servidor demorou para responder.');
    } catch (_) {
      if (mounted) setState(() => _erro = 'Falha de conexão. Tente novamente.');
    } finally {
      if (widget.client == null) client.close();
      if (mounted) {
        setState(() {
          _enviando = false;
          // Turnstile valida tokens apenas uma vez. Recriar apos tentativa.
          _turnstileToken = null;
          _desafioVersao++;
        });
      }
    }
  }

  InputDecoration _campo(String rotulo, IconData icone) => InputDecoration(
        labelText: rotulo,
        labelStyle: const TextStyle(color: _suave),
        prefixIcon: Icon(icone, color: _suave),
        filled: true,
        fillColor: _fundo,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _borda),
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _azul, width: 1.5),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _fundo,
      appBar: AppBar(
        title: const Text('Criar conta no Automatize'),
        backgroundColor: _fundo,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 550),
            child: Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: _painel,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: _borda),
              ),
              child: _concluido ? _sucesso() : _formulario(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _sucesso() => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.mark_email_read_outlined, size: 58, color: Color(0xFF2FD3A1)),
          const SizedBox(height: 18),
          const Text('Solicitação recebida',
              style: TextStyle(color: _texto, fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          const Text(
            'Se o e-mail ainda não estiver cadastrado, sua conta ficará pendente de validação e contratação. '
            'Você não receberá acesso às demandas de outras pessoas ou empresas.',
            textAlign: TextAlign.center,
            style: TextStyle(color: _suave, height: 1.6),
          ),
          const SizedBox(height: 25),
          FilledButton(
            onPressed: () => Navigator.of(context).pushNamedAndRemoveUntil(
              AppRoutes.login, (route) => false,
            ),
            child: const Text('Ir para o login'),
          ),
        ],
      );

  Widget _formulario() => Form(
        key: _form,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Seu espaço começa aqui',
                style: TextStyle(color: _texto, fontSize: 26, fontWeight: FontWeight.w800)),
            const SizedBox(height: 9),
            const Text(
              'Crie sua identidade. O acesso a projetos DEV ou à plataforma de uma empresa '
              'só será liberado após a confirmação do vínculo.',
              style: TextStyle(color: _suave, height: 1.5),
            ),
            const SizedBox(height: 26),
            TextFormField(
              controller: _nome,
              autofillHints: const [AutofillHints.name],
              textInputAction: TextInputAction.next,
              style: const TextStyle(color: _texto),
              decoration: _campo('Nome completo', Icons.person_outline),
              validator: (v) => (v?.trim().length ?? 0) < 3 ? 'Informe seu nome.' : null,
            ),
            const SizedBox(height: 15),
            TextFormField(
              controller: _email,
              autofillHints: const [AutofillHints.email],
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              style: const TextStyle(color: _texto),
              decoration: _campo('E-mail', Icons.mail_outline),
              validator: (v) =>
                  RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v?.trim() ?? '')
                      ? null : 'Informe um e-mail válido.',
            ),
            const SizedBox(height: 15),
            TextFormField(
              controller: _senha,
              obscureText: true,
              autofillHints: const [AutofillHints.newPassword],
              textInputAction: TextInputAction.next,
              style: const TextStyle(color: _texto),
              decoration: _campo('Senha', Icons.lock_outline),
              validator: (v) {
                final senha = v ?? '';
                if (senha.length < 8) return 'Use pelo menos 8 caracteres.';
                if (utf8.encode(senha).length > 72) return 'A senha deve ter no máximo 72 bytes.';
                return null;
              },
            ),
            const SizedBox(height: 15),
            TextFormField(
              controller: _confirmacao,
              obscureText: true,
              autofillHints: const [AutofillHints.newPassword],
              textInputAction: TextInputAction.done,
              style: const TextStyle(color: _texto),
              decoration: _campo('Confirmar senha', Icons.verified_user_outlined),
              validator: (v) => v == _senha.text ? null : 'As senhas não coincidem.',
              onFieldSubmitted: (_) => _enviar(),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: () => Navigator.of(context).pushNamed(AppRoutes.termosUso),
                child: const Text('Ler os Termos de Uso'),
              ),
            ),
            Material(
              type: MaterialType.transparency,
              child: CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                title: const Text('Li e aceito os Termos de Uso.'),
                value: _termosAceitos,
                onChanged: _enviando
                    ? null
                    : (value) => setState(() => _termosAceitos = value ?? false),
              ),
            ),
            if (AppConfig.publicSignupEnabled) ...[
              const SizedBox(height: 18),
              if (AppConfig.turnstileSiteKey.isNotEmpty)
                TurnstileChallenge(
                  key: ValueKey(_desafioVersao),
                  siteKey: AppConfig.turnstileSiteKey,
                  onToken: (token) {
                    if (mounted) setState(() => _turnstileToken = token);
                  },
                )
              else
                const Text('Verificação antirobô não configurada.',
                    style: TextStyle(color: Color(0xFFFF7785))),
            ],
            if (_erro != null) ...[
              const SizedBox(height: 15),
              Text(_erro!, style: const TextStyle(color: Color(0xFFFF7785))),
            ],
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _enviando ? null : _enviar,
              style: FilledButton.styleFrom(
                backgroundColor: _azul,
                minimumSize: const Size.fromHeight(50),
              ),
              child: _enviando
                  ? const SizedBox(width: 18, height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Solicitar minha conta'),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.of(context).pushNamed(AppRoutes.login),
              child: const Text('Já tenho uma conta'),
            ),
          ],
        ),
      );
}
