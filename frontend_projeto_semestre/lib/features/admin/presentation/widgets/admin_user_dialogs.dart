import 'package:flutter/material.dart';

import '../../data/models/usuario_model.dart';

/// Mesmo mínimo do backend (`UsuarioAdminService.TAMANHO_MINIMO_SENHA`).
const tamanhoMinimoSenha = 8;

class NovoUsuarioResult {
  final String nome;
  final String email;
  final String senha;
  final String perfil;

  const NovoUsuarioResult({
    required this.nome,
    required this.email,
    required this.senha,
    required this.perfil,
  });
}

/// Cadastro de usuário pelo ADMIN. A senha inicial é definida aqui e
/// repassada à pessoa; o backend só guarda o hash.
class UsuarioFormDialog extends StatefulWidget {
  const UsuarioFormDialog({super.key, this.perfilFixo});

  final String? perfilFixo;

  static Future<NovoUsuarioResult?> show(
    BuildContext context, {
    String? perfilFixo,
  }) => showDialog<NovoUsuarioResult>(
    context: context,
    builder: (_) => UsuarioFormDialog(perfilFixo: perfilFixo),
  );

  @override
  State<UsuarioFormDialog> createState() => _UsuarioFormDialogState();
}

class _UsuarioFormDialogState extends State<UsuarioFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nome = TextEditingController();
  final _email = TextEditingController();
  final _senha = TextEditingController();
  String? _perfil;
  bool _senhaVisivel = false;

  @override
  void dispose() {
    _nome.dispose();
    _email.dispose();
    _senha.dispose();
    super.dispose();
  }

  void _salvar() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).pop(
      NovoUsuarioResult(
        nome: _nome.text.trim(),
        email: _email.text.trim(),
        senha: _senha.text,
        perfil: widget.perfilFixo ?? _perfil!,
      ),
    );
  }

  static String? _validarEmail(String? valor) {
    final email = valor?.trim() ?? '';
    final partes = email.split('@');
    final valido =
        partes.length == 2 &&
        partes[0].isNotEmpty &&
        partes[1].contains('.') &&
        !email.contains(' ');
    return valido ? null : 'Informe um e-mail válido.';
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      scrollable: true,
      title: Text(
        widget.perfilFixo == 'CLIENTE' ? 'Novo cliente' : 'Novo usuário',
      ),
      content: SizedBox(
        width: 440,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nome,
                autofocus: true,
                maxLength: 255,
                decoration: const InputDecoration(labelText: 'Nome'),
                validator: (v) => (v?.trim().length ?? 0) < 3
                    ? 'Informe o nome (mínimo 3 caracteres).'
                    : null,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'E-mail'),
                validator: _validarEmail,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _senha,
                obscureText: !_senhaVisivel,
                decoration: InputDecoration(
                  labelText: 'Senha inicial',
                  helperText: 'Mínimo $tamanhoMinimoSenha caracteres.',
                  suffixIcon: IconButton(
                    tooltip: _senhaVisivel ? 'Ocultar senha' : 'Mostrar senha',
                    onPressed: () =>
                        setState(() => _senhaVisivel = !_senhaVisivel),
                    icon: Icon(
                      _senhaVisivel ? Icons.visibility_off : Icons.visibility,
                    ),
                  ),
                ),
                validator: (v) => (v?.length ?? 0) < tamanhoMinimoSenha
                    ? 'A senha deve ter no mínimo $tamanhoMinimoSenha caracteres.'
                    : null,
              ),
              if (widget.perfilFixo == null) const SizedBox(height: 12),
              if (widget.perfilFixo == null)
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: 'Perfil'),
                  items: [
                    for (final perfil in UsuarioModel.perfis)
                      DropdownMenuItem(
                        value: perfil,
                        child: Text(UsuarioModel.rotuloPerfil(perfil)),
                      ),
                  ],
                  onChanged: (perfil) => _perfil = perfil,
                  validator: (perfil) =>
                      perfil == null ? 'Selecione o perfil.' : null,
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(onPressed: _salvar, child: const Text('Cadastrar')),
      ],
    );
  }
}

/// Escolha do novo perfil (só os diferentes do atual).
Future<String?> escolherPerfil(BuildContext context, UsuarioModel usuario) {
  return showDialog<String>(
    context: context,
    builder: (context) => SimpleDialog(
      title: Text('Perfil de ${usuario.nome}'),
      children: [
        for (final perfil in UsuarioModel.perfis)
          if (perfil != usuario.perfil)
            SimpleDialogOption(
              onPressed: () => Navigator.of(context).pop(perfil),
              child: Text('Tornar ${UsuarioModel.rotuloPerfil(perfil)}'),
            ),
      ],
    ),
  );
}

/// Inativar corta o acesso na hora (inclusive sessões abertas), por isso pede confirmação.
Future<bool> confirmarAlteracaoAtivo(
  BuildContext context,
  UsuarioModel usuario,
) async {
  final inativar = usuario.ativo;
  final confirmado = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(inativar ? 'Inativar usuário' : 'Reativar usuário'),
      content: Text(
        inativar
            ? '${usuario.nome} perde o acesso imediatamente. O histórico e as '
                  'demandas continuam registrados.'
            : '${usuario.nome} volta a conseguir entrar no sistema.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(inativar ? 'Inativar' : 'Reativar'),
        ),
      ],
    ),
  );
  return confirmado ?? false;
}
