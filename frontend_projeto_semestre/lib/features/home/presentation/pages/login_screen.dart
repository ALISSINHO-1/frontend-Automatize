import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../../../app/routes/app_routes.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/storage/local_storage_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, this.client});

  // Cliente opcional para testes sem acessar a API real.
  final http.Client? client;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _senhaController = TextEditingController();

  bool _ocultarSenha = true;
  bool _carregando = false;

  // Cores da interface.
  static const _fundo = Color(0xFF07172A);
  static const _painel = Color(0xFF102743);
  static const _azul = Color(0xFF168BFF);
  static const _ciano = Color(0xFF21B7FF);
  static const _texto = Color(0xFFF4F7FB);
  static const _textoSecundario = Color(0xFF9DB1C8);
  static const _borda = Color(0xFF294866);
  static const _erro = Color(0xFFFF5364);

  @override
  void dispose() {
    _emailController.dispose();
    _senhaController.dispose();
    super.dispose();
  }

  // Autenticação

  void _mostrarErro(String mensagem) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensagem),
        backgroundColor: _erro,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _entrar() async {
    if (_carregando || !(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    setState(() => _carregando = true);

    final client = widget.client ?? http.Client();

    try {
      // Evita reutilizar uma sessão anterior.
      await LocalStorageService.removeToken();

      final resposta = await client
          .post(
            AppConfig.apiUri('/auth/login'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'email': _emailController.text.trim(),
              'senha': _senhaController.text,
            }),
          )
          .timeout(const Duration(seconds: 15));

      await _tratarResposta(resposta);
    } on TimeoutException {
      _mostrarErro('A conexão demorou demais. Tente novamente.');
    } on http.ClientException {
      _mostrarErro('Não foi possível conectar à API. Verifique o servidor.');
    } on FormatException {
      _mostrarErro('O servidor retornou uma resposta inválida.');
    } catch (_) {
      _mostrarErro('Não foi possível concluir o login. Tente novamente.');
    } finally {
      if (widget.client == null) {
        client.close();
      }

      if (mounted) {
        setState(() => _carregando = false);
      }
    }
  }

  Future<void> _tratarResposta(http.Response resposta) async {
    if (resposta.statusCode == 200) {
      final dados = jsonDecode(utf8.decode(resposta.bodyBytes));

      // Contrato da FastAPI: apenas access_token.
      final token = dados is Map<String, dynamic>
          ? dados['access_token']
          : null;

      if (token is! String || token.trim().isEmpty) {
        _mostrarErro('Resposta do servidor inválida: token não encontrado.');
        return;
      }

      // Armazena o JWT em memória.
      await LocalStorageService.saveToken(token);

      if (!mounted) return;

      // Remove as telas anteriores do histórico.
      Navigator.of(
        context,
      ).pushNamedAndRemoveUntil(AppRoutes.home, (route) => false);

      return;
    }

    if (resposta.statusCode == 400 || resposta.statusCode == 401) {
      _mostrarErro('E-mail ou senha incorretos.');
    } else if (resposta.statusCode == 403) {
      _mostrarErro('Seu usuário não tem permissão de acesso.');
    } else if (resposta.statusCode == 422) {
      _mostrarErro('Dados de login rejeitados. Verifique e-mail e senha.');
    } else {
      _mostrarErro('Erro no servidor (código ${resposta.statusCode}).');
    }
  }

  // Estrutura da página

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _fundo,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF07172A), Color(0xFF0B2039), Color(0xFF102943)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final larguraGrande = constraints.maxWidth >= 850;

              return Center(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(larguraGrande ? 32 : 18),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1080),
                    child: Container(
                      clipBehavior: Clip.antiAlias,
                      decoration: BoxDecoration(
                        color: _painel,
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(color: _borda),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.24),
                            blurRadius: 45,
                            offset: const Offset(0, 20),
                          ),
                        ],
                      ),
                      child: larguraGrande
                          ? Row(
                              children: [
                                Expanded(
                                  flex: 11,
                                  child: _painelApresentacao(),
                                ),
                                Expanded(flex: 9, child: _formulario()),
                              ],
                            )
                          : Column(
                              children: [
                                _painelApresentacao(compacto: true),
                                _formulario(),
                              ],
                            ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  // Painel de apresentação

  Widget _painelApresentacao({bool compacto = false}) {
    return Container(
      constraints: BoxConstraints(minHeight: compacto ? 0 : 570),
      padding: EdgeInsets.all(compacto ? 25 : 42),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF123D68), Color(0xFF0D2948), Color(0xFF102743)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _marca(),

          SizedBox(height: compacto ? 28 : 65),

          _selo(),

          const SizedBox(height: 23),

          Text(
            'Seu trabalho,\nmais organizado.',
            style: TextStyle(
              color: _texto,
              fontSize: compacto ? 30 : 39,
              height: 1.15,
              fontWeight: FontWeight.w900,
              letterSpacing: -1.1,
            ),
          ),

          const SizedBox(height: 17),

          const Text(
            'Acompanhe suas demandas, consulte o andamento '
            'das atividades e mantenha tudo em um só lugar.',
            style: TextStyle(
              color: _textoSecundario,
              fontSize: 14,
              height: 1.7,
            ),
          ),

          const SizedBox(height: 28),

          _beneficio(
            Icons.track_changes_rounded,
            'Acompanhamento de progresso',
          ),

          const SizedBox(height: 15),

          _beneficio(
            Icons.fact_check_outlined,
            'Status das demandas sempre visíveis',
          ),

          const SizedBox(height: 15),

          _beneficio(
            Icons.dashboard_customize_outlined,
            'Informações organizadas em um só lugar',
          ),

          if (!compacto) ...[
            const SizedBox(height: 36),
            const Divider(color: _borda),
            const SizedBox(height: 14),
            const Text(
              'AUTOMATIZE  ·  PORTAL DO CLIENTE',
              style: TextStyle(
                color: _textoSecundario,
                fontSize: 10,
                letterSpacing: 1,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // Marca do Automatize

  Widget _marca() {
    return Row(
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [_ciano, _azul]),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: _azul.withValues(alpha: 0.25),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: const Icon(
            Icons.auto_awesome_rounded,
            color: Colors.white,
            size: 25,
          ),
        ),

        const SizedBox(width: 12),

        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'AUTOMATIZE',
              style: TextStyle(
                color: _texto,
                fontSize: 18,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.4,
              ),
            ),
            SizedBox(height: 3),
            Text(
              'Gestão de demandas',
              style: TextStyle(color: _textoSecundario, fontSize: 11),
            ),
          ],
        ),
      ],
    );
  }

  // Selo informativo

  Widget _selo() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: _ciano.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: _ciano.withValues(alpha: 0.25)),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.bolt_rounded, color: _ciano, size: 15),
          SizedBox(width: 7),
          Text(
            'ORGANIZAÇÃO E PRODUTIVIDADE',
            style: TextStyle(
              color: _ciano,
              fontSize: 9,
              fontWeight: FontWeight.w800,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }

  // Item de benefício

  Widget _beneficio(IconData icone, String texto) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: _ciano.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icone, color: _ciano, size: 17),
        ),

        const SizedBox(width: 12),

        Expanded(
          child: Text(
            texto,
            style: const TextStyle(
              color: _texto,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  // Formulário de acesso

  Widget _formulario() {
    return Padding(
      padding: const EdgeInsets.all(30),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _cabecalhoFormulario(),

            const SizedBox(height: 30),

            _campoEmail(),

            const SizedBox(height: 21),

            _campoSenha(),

            const SizedBox(height: 28),

            _botaoEntrar(),

            const SizedBox(height: 24),

            _avisoAcesso(),
          ],
        ),
      ),
    );
  }

  // Cabeçalho do formulário

  Widget _cabecalhoFormulario() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _azul.withValues(alpha: 0.13),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(
            Icons.lock_person_outlined,
            color: _ciano,
            size: 25,
          ),
        ),

        const SizedBox(height: 25),

        const Text(
          'Bem-vindo de volta!',
          style: TextStyle(
            color: _texto,
            fontSize: 26,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.6,
          ),
        ),

        const SizedBox(height: 9),

        const Text(
          'Entre com seus dados para acessar a plataforma.',
          style: TextStyle(color: _textoSecundario, fontSize: 12, height: 1.6),
        ),
      ],
    );
  }

  // Campo de e-mail

  Widget _campoEmail() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'E-mail',
          style: TextStyle(
            color: _texto,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),

        const SizedBox(height: 9),

        TextFormField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          style: const TextStyle(color: _texto, fontSize: 13),
          decoration: _decoracao(
            hint: 'voce@exemplo.com',
            icone: Icons.mail_outline_rounded,
          ),
          validator: (valor) {
            final email = valor?.trim() ?? '';

            if (email.isEmpty) {
              return 'Informe seu e-mail.';
            }

            if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
              return 'Digite um e-mail válido.';
            }

            return null;
          },
        ),
      ],
    );
  }

  // Campo de senha

  Widget _campoSenha() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Senha',
          style: TextStyle(
            color: _texto,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),

        const SizedBox(height: 9),

        TextFormField(
          controller: _senhaController,
          obscureText: _ocultarSenha,
          textInputAction: TextInputAction.done,
          onFieldSubmitted: (_) => _entrar(),
          style: const TextStyle(color: _texto, fontSize: 13),
          decoration: _decoracao(
            hint: 'Digite sua senha',
            icone: Icons.lock_outline_rounded,
            sufixo: IconButton(
              tooltip: _ocultarSenha ? 'Mostrar senha' : 'Ocultar senha',
              onPressed: () {
                setState(() {
                  _ocultarSenha = !_ocultarSenha;
                });
              },
              icon: Icon(
                _ocultarSenha
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: _textoSecundario,
                size: 19,
              ),
            ),
          ),
          validator: (valor) {
            if (valor == null || valor.isEmpty) {
              return 'Informe sua senha.';
            }

            return null;
          },
        ),
      ],
    );
  }

  // Botão de login

  Widget _botaoEntrar() {
    return SizedBox(
      height: 50,
      child: FilledButton(
        onPressed: _carregando ? null : _entrar,
        style: FilledButton.styleFrom(
          backgroundColor: _azul,
          disabledBackgroundColor: _azul.withValues(alpha: 0.5),
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(13),
          ),
        ),
        child: _carregando
            ? const SizedBox(
                width: 21,
                height: 21,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Entrar na plataforma',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
                  ),
                  SizedBox(width: 9),
                  Icon(Icons.arrow_forward_rounded, size: 18),
                ],
              ),
      ),
    );
  }

  // Aviso de acesso

  Widget _avisoAcesso() {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.shield_outlined, color: _textoSecundario, size: 16),
        SizedBox(width: 7),
        Flexible(
          child: Text(
            'Acesso destinado aos usuários da plataforma',
            textAlign: TextAlign.center,
            style: TextStyle(color: _textoSecundario, fontSize: 10),
          ),
        ),
      ],
    );
  }

  // Estilo dos campos

  InputDecoration _decoracao({
    required String hint,
    required IconData icone,
    Widget? sufixo,
  }) {
    OutlineInputBorder borda(Color cor, [double largura = 1]) {
      return OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: cor, width: largura),
      );
    }

    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFF7189A2), fontSize: 12),
      prefixIcon: Icon(icone, color: _textoSecundario, size: 19),
      suffixIcon: sufixo,
      filled: true,
      fillColor: _fundo.withValues(alpha: 0.65),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      errorStyle: const TextStyle(fontSize: 10),
      enabledBorder: borda(_borda),
      border: borda(_borda),
      focusedBorder: borda(_azul, 1.5),
      errorBorder: borda(_erro),
      focusedErrorBorder: borda(_erro, 1.5),
    );
  }
}
