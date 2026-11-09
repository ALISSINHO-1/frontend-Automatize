import 'package:flutter/material.dart';

import '../../../../shared/widgets/main_layout.dart';
import '../../data/models/usuario_model.dart';
import '../../data/services/admin_demand_service.dart';
import '../../data/services/usuario_atual_store.dart';
import '../admin_style.dart';
import '../widgets/admin_user_dialogs.dart';

/// Gestão de usuários e perfis pelo ADMIN (SCRUM-99): cadastrar, trocar o
/// perfil e ativar/inativar. As travas (último ADMIN, técnico com demanda
/// aberta, cliente com demandas) são do backend; aqui só mostramos o `detail`.
class AdminUsersPage extends StatefulWidget {
  const AdminUsersPage({super.key, this.adminService, this.idUsuarioAtual});

  final AdminDemandService? adminService;

  /// Substituível nos testes; por padrão vem do `GET /auth/me` em cache.
  final String? idUsuarioAtual;

  @override
  State<AdminUsersPage> createState() => _AdminUsersPageState();
}

class _AdminUsersPageState extends State<AdminUsersPage> {
  late final AdminDemandService _admin =
      widget.adminService ?? AdminDemandService();
  late Future<List<UsuarioModel>> _usuarios = _admin.listarUsuarios();
  String? _perfil;
  bool _ocupado = false;

  String? get _euId =>
      widget.idUsuarioAtual ?? UsuarioAtualStore.instance.value?.id;

  @override
  void dispose() {
    if (widget.adminService == null) _admin.dispose();
    super.dispose();
  }

  void _recarregar() => setState(() => _usuarios = _admin.listarUsuarios());

  void _mensagem(String texto) => ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(texto)));

  Future<void> _executar(Future<void> Function() acao, String sucesso) async {
    setState(() => _ocupado = true);
    try {
      await acao();
      if (!mounted) return;
      _mensagem(sucesso);
      _recarregar();
    } catch (erro) {
      if (mounted) _mensagem('$erro');
    } finally {
      if (mounted) setState(() => _ocupado = false);
    }
  }

  Future<void> _cadastrar() async {
    final dados = await UsuarioFormDialog.show(context);
    if (dados == null || !mounted) return;
    await _executar(
      () => _admin.criarUsuario(
        nome: dados.nome,
        email: dados.email,
        senha: dados.senha,
        perfil: dados.perfil,
      ),
      'Usuário ${dados.nome} cadastrado.',
    );
  }

  Future<void> _trocarPerfil(UsuarioModel usuario) async {
    final perfil = await escolherPerfil(context, usuario);
    if (perfil == null || !mounted) return;
    await _executar(
      () => _admin.alterarPerfil(usuario.id, perfil),
      '${usuario.nome} agora é ${UsuarioModel.rotuloPerfil(perfil)}.',
    );
  }

  Future<void> _alternarAtivo(UsuarioModel usuario) async {
    if (!await confirmarAlteracaoAtivo(context, usuario)) return;
    await _executar(
      () => _admin.alterarAtivo(usuario.id, ativo: !usuario.ativo),
      usuario.ativo
          ? '${usuario.nome} foi inativado.'
          : '${usuario.nome} foi reativado.',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AdminStyle.fundo,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1000),
            child: FutureBuilder<List<UsuarioModel>>(
              future: _usuarios,
              builder: (context, snapshot) {
                final todos = snapshot.data ?? const <UsuarioModel>[];
                final visiveis = _perfil == null
                    ? todos
                    : todos.where((u) => u.perfil == _perfil).toList();
                return ListView(
                  padding: const EdgeInsets.fromLTRB(28, 24, 28, 40),
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        style: TextButton.styleFrom(
                          foregroundColor: AutomatizeColors.muted,
                        ),
                        onPressed: () => Navigator.of(context).maybePop(),
                        icon: const Icon(Icons.arrow_back_rounded, size: 18),
                        label: const Text('Painel administrativo'),
                      ),
                    ),
                    const SizedBox(height: 8),
                    _cabecalho(),
                    const SizedBox(height: 20),
                    _filtros(todos),
                    if (_ocupado) ...[
                      const SizedBox(height: 14),
                      const LinearProgressIndicator(color: AdminStyle.destaque),
                    ],
                    const SizedBox(height: 18),
                    if (snapshot.connectionState == ConnectionState.waiting)
                      const Padding(
                        padding: EdgeInsets.all(48),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else if (snapshot.hasError)
                      _erro('${snapshot.error}')
                    else if (visiveis.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(28),
                        child: Center(
                          child: Text(
                            'Nenhum usuário encontrado.',
                            style: AdminStyle.subtitulo,
                          ),
                        ),
                      )
                    else
                      for (final usuario in visiveis) ...[
                        _ItemUsuario(
                          usuario: usuario,
                          proprio: usuario.id == _euId,
                          ocupado: _ocupado,
                          onTrocarPerfil: () => _trocarPerfil(usuario),
                          onAlternarAtivo: () => _alternarAtivo(usuario),
                        ),
                        const SizedBox(height: 10),
                      ],
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _cabecalho() => Wrap(
    spacing: 16,
    runSpacing: 16,
    alignment: WrapAlignment.spaceBetween,
    crossAxisAlignment: WrapCrossAlignment.center,
    children: [
      const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Usuários e perfis', style: AdminStyle.titulo),
          SizedBox(height: 6),
          Text(
            'Cadastre pessoas, defina o perfil e controle o acesso.',
            style: AdminStyle.subtitulo,
          ),
        ],
      ),
      FilledButton.icon(
        style: FilledButton.styleFrom(
          backgroundColor: AdminStyle.destaque,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onPressed: _ocupado ? null : _cadastrar,
        icon: const Icon(Icons.person_add_alt_1_rounded),
        label: const Text('Novo usuário'),
      ),
    ],
  );

  Widget _filtros(List<UsuarioModel> todos) => Wrap(
    spacing: 10,
    runSpacing: 10,
    children: [
      for (final perfil in [null, ...UsuarioModel.perfis])
        ChoiceChip(
          label: Text(
            '${perfil == null ? 'Todos' : UsuarioModel.rotuloPerfil(perfil)}'
            ' (${perfil == null ? todos.length : todos.where((u) => u.perfil == perfil).length})',
          ),
          selected: _perfil == perfil,
          onSelected: (_) => setState(() => _perfil = perfil),
        ),
    ],
  );

  Widget _erro(String mensagem) => Container(
    padding: const EdgeInsets.all(28),
    decoration: AdminStyle.caixa(),
    child: Column(
      children: [
        Text(
          'Não foi possível carregar os usuários.\n$mensagem',
          textAlign: TextAlign.center,
          style: AdminStyle.subtitulo,
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: _recarregar,
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('Tentar novamente'),
        ),
      ],
    ),
  );
}

class _ItemUsuario extends StatelessWidget {
  const _ItemUsuario({
    required this.usuario,
    required this.proprio,
    required this.ocupado,
    required this.onTrocarPerfil,
    required this.onAlternarAtivo,
  });

  final UsuarioModel usuario;
  final bool proprio;
  final bool ocupado;
  final VoidCallback onTrocarPerfil;
  final VoidCallback onAlternarAtivo;

  static Color _corPerfil(String perfil) => switch (perfil) {
    'ADMIN' => AdminStyle.destaqueClaro,
    'TECNICO' => const Color(0xFF3B8BFF),
    _ => const Color(0xFF2FD3A1),
  };

  @override
  Widget build(BuildContext context) {
    final cor = _corPerfil(usuario.perfil);
    // No celular os selos dividindo a linha espremiam o nome letra por letra:
    // em tela estreita eles descem para baixo do e-mail.
    final estreito = MediaQuery.sizeOf(context).width < 640;
    final selos = [
      _Selo(UsuarioModel.rotuloPerfil(usuario.perfil), cor),
      _Selo(
        usuario.ativo ? 'Ativo' : 'Inativo',
        usuario.ativo ? const Color(0xFF2FD3A1) : AutomatizeColors.muted,
      ),
    ];
    return Opacity(
      opacity: usuario.ativo ? 1 : 0.6,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: AdminStyle.caixa(),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: cor.withValues(alpha: 0.18),
              foregroundColor: cor,
              child: Text(
                usuario.nome.isEmpty ? '?' : usuario.nome[0].toUpperCase(),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    proprio ? '${usuario.nome} (você)' : usuario.nome,
                    style: AdminStyle.tituloCard,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    usuario.email,
                    style: AdminStyle.subtitulo.copyWith(fontSize: 13),
                  ),
                  if (estreito) ...[
                    const SizedBox(height: 8),
                    Wrap(spacing: 8, runSpacing: 6, children: selos),
                  ],
                ],
              ),
            ),
            if (!estreito) ...[selos[0], const SizedBox(width: 8), selos[1]],
            // O backend recusa alterar a própria conta (403): nem oferece.
            if (proprio)
              SizedBox(width: estreito ? 8 : 48)
            else
              PopupMenuButton<String>(
                tooltip: 'Ações do usuário',
                enabled: !ocupado,
                color: AdminStyle.card,
                iconColor: AutomatizeColors.muted,
                onSelected: (acao) =>
                    acao == 'perfil' ? onTrocarPerfil() : onAlternarAtivo(),
                itemBuilder: (_) => [
                  const PopupMenuItem(
                    value: 'perfil',
                    child: Text('Alterar perfil'),
                  ),
                  PopupMenuItem(
                    value: 'ativo',
                    child: Text(usuario.ativo ? 'Inativar' : 'Reativar'),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _Selo extends StatelessWidget {
  const _Selo(this.texto, this.cor);

  final String texto;
  final Color cor;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: cor.withValues(alpha: 0.14),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: cor.withValues(alpha: 0.45)),
    ),
    child: Text(
      texto,
      style: TextStyle(color: cor, fontSize: 11, fontWeight: FontWeight.w800),
    ),
  );
}
