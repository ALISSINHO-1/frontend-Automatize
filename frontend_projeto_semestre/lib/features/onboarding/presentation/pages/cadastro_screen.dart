import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../../../app/routes/app_routes.dart';
import '../../../../core/config/app_config.dart';
import '../../data/conta_configuracao.dart';
import '../../widgets/turnstile_challenge.dart';
import 'termos_uso_screen.dart';

/// Cadastro autônomo: identidade própria, com projetos liberados por vínculo.
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
  bool _configCarregando = true;
  bool _cadastroHabilitado = false;
  String _siteKey = '';
  String? _erroConfiguracao;
  String? _erro;
  String? _turnstileToken;
  String? _captchaErro;
  int _desafioVersao = 0;

  @override
  void initState() {
    super.initState();
    _consultarConfiguracao();
  }

  Future<void> _consultarConfiguracao() async {
    setState(() {
      _configCarregando = true;
      _erroConfiguracao = null;
    });
    final client = widget.client ?? http.Client();
    try {
      final config = await ContaConfiguracao.consultar(client);
      if (!mounted) return;
      setState(() {
        _cadastroHabilitado = config.cadastroHabilitado;
        _siteKey = config.turnstileSiteKey;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _cadastroHabilitado = false;
        _siteKey = '';
        _erroConfiguracao = 'Não foi possível consultar a disponibilidade do cadastro.';
      });
    } finally {
      if (widget.client == null) client.close();
      if (mounted) setState(() => _configCarregando = false);
    }
  }

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
    if (!_cadastroHabilitado || _siteKey.isEmpty) {
      setState(() => _erro = 'Não foi possível iniciar o cadastro. Tente novamente.');
      return;
    }
    if (!_termosAceitos) {
      setState(() => _erro = 'Aceite os Termos de Uso para continuar.');
      return;
    }
    if (_turnstileToken == null || _turnstileToken!.isEmpty) {
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
          _captchaErro = null;
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
              child: _concluido
                  ? _sucesso()
                  : _configCarregando
                      ? const Padding(
                          padding: EdgeInsets.all(32),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircularProgressIndicator(),
                              SizedBox(height: 16),
                              Text('Preparando criação de conta',
                                  style: TextStyle(color: _texto)),
                            ],
                          ),
                        )
                      : _cadastroHabilitado
                          ? _formulario()
                          : _cadastroIndisponivel(),
            ),
          ),
        ),
      ),
    );
  }

  /// Não apresentar um formulário que o build já sabe estar desativado.
  Widget _cadastroIndisponivel() => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(
            Icons.person_off_outlined,
            size: 48,
            color: _suave,
          ),
          const SizedBox(height: 18),
          const Text(
            'Não foi possível abrir o cadastro',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _texto,
              fontSize: 23,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'O cadastro está temporariamente indisponível. '
            'Você pode tentar novamente sem precisar solicitar autorização a ninguém.',
            textAlign: TextAlign.center,
            style: TextStyle(color: _suave, height: 1.6),
          ),
          if (_erroConfiguracao != null) ...[
            const SizedBox(height: 14),
            Text(_erroConfiguracao!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFFFF7785))),
          ],
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _consultarConfiguracao,
            child: const Text('Tentar novamente'),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => Navigator.of(context).pushNamedAndRemoveUntil(
              AppRoutes.login, (route) => false,
            ),
            child: const Text('Ir para o login'),
          ),
        ],
      );

  Widget _sucesso() => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.mark_email_unread_outlined,
            size: 58,
            color: Color(0xFF21B7FF),
          ),
          const SizedBox(height: 18),
          const Text(
            'Confira sua caixa de entrada',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _texto,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Se este e-mail ainda não está cadastrado, enviamos um link '
            'para confirmar sua conta. O link expira em 30 minutos. '
            'Confira também a pasta de spam.',
            textAlign: TextAlign.center,
            style: TextStyle(color: _suave, height: 1.6),
          ),
          const SizedBox(height: 12),
          const Text(
            'Sua conta é pessoal e não precisa de autorização para ser criada. '
            'Para acessar demandas de uma empresa, é necessário ter um vínculo com ela.',
            textAlign: TextAlign.center,
            style: TextStyle(color: _suave, height: 1.6),
          ),
          const SizedBox(height: 24),
          TextButton.icon(
              onPressed: () => Navigator.of(context)
                  .pushNamed(AppRoutes.reenviarConfirmacao),
              icon: const Icon(Icons.mark_email_unread_outlined),
              label: const Text('Reenviar e-mail de confirmação'),
            ),
          const SizedBox(height: 10),
          FilledButton(
            onPressed: () => Navigator.of(context).pushNamedAndRemoveUntil(
              AppRoutes.login, (route) => false,
            ),
            child: const Text('Voltar ao login'),
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
              'Crie sua conta e confirme o e-mail. Você pode se cadastrar livremente; '
              'o acesso a projetos de empresas depende das permissões concedidas.',
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
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: () => Navigator.of(context).pushNamed(AppRoutes.politicaPrivacidade),
                child: const Text('Ler a Política de Privacidade'),
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
            const SizedBox(height: 18),
            const Text('Verificação de segurança',
                style: TextStyle(color: _texto, fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            const Text('O Cloudflare validará seu acesso antes de criar a conta.',
                style: TextStyle(color: _suave, fontSize: 12)),
            TurnstileChallenge(
              key: ValueKey(_desafioVersao),
              siteKey: _siteKey,
              onToken: (token) {
                if (mounted) setState(() {
                  _turnstileToken = token;
                  if (token != null) _captchaErro = null;
                });
              },
              onError: (message) {
                if (mounted) setState(() {
                  _turnstileToken = null;
                  _captchaErro = message;
                });
              },
            ),
            if (_captchaErro != null) ...[
              const SizedBox(height: 4),
              Text(_captchaErro!,
                  style: const TextStyle(color: Color(0xFFFF7785))),
            ],
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: _enviando ? null : () {
                  setState(() {
                    _captchaErro = null;
                    _turnstileToken = null;
                    _desafioVersao++;
                  });
                },
                icon: const Icon(Icons.refresh_rounded, size: 17),
                label: const Text('Recarregar verificação'),
              ),
            ),
            const Text(
              'Se não aparecer, verifique se o navegador está bloqueando '
              'o Cloudflare Turnstile (por exemplo, Brave Shields).',
              style: TextStyle(color: _suave, fontSize: 12, height: 1.4),
            ),
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
                  : const Text('Criar minha conta'),
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
