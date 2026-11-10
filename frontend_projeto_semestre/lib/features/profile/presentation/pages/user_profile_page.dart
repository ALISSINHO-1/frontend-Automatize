import 'package:flutter/material.dart';

import '../../../../app/routes/app_routes.dart';
import '../../../../core/auth/current_user_session.dart';
import '../../../../core/storage/local_storage_service.dart';
import '../../../admin/data/models/usuario_atual_model.dart';
import '../../../admin/data/services/usuario_atual_store.dart';
import '../../../home/data/current_user_service.dart';
import '../../../home/presentation/pages/demanda_store.dart';
import '../../../home/presentation/widgets/admin_layout.dart';
import '../../../home/presentation/widgets/technical_navigation.dart';
import '../../../../shared/widgets/main_layout.dart';
import '../../data/perfil_service.dart';

class UserProfilePage extends StatefulWidget {
  const UserProfilePage({super.key});

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  final PerfilService _service = PerfilService();
  final DemandaStore _demandas = DemandaStore.instance;
  late Future<UsuarioAtualModel?> _usuario;
  late Future<PerfilDetalhes> _detalhes;

  @override
  void initState() {
    super.initState();
    _usuario = UsuarioAtualStore.instance.carregar();
    _detalhes = _service.detalhes();
    _demandas.addListener(_redesenhar);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _demandas.carregarDemandas();
    });
  }

  void _redesenhar() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _demandas.removeListener(_redesenhar);
    _service.dispose();
    super.dispose();
  }

  void _notificar(String mensagem, {bool erro = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(mensagem),
      backgroundColor: erro ? AutomatizeColors.danger : AutomatizeColors.panelLight,
    ));
  }

  Future<void> _recarregar() async {
    setState(() => _detalhes = _service.detalhes());
    await _demandas.carregarDemandas();
  }

  Future<void> _editarNome(UsuarioAtualModel usuario) async {
    final controller = TextEditingController(text: usuario.nome);
    final form = GlobalKey<FormState>();
    final resultado = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Editar meu perfil'),
        content: Form(
          key: form,
          child: TextFormField(
            controller: controller,
            autofocus: true,
            maxLength: 255,
            decoration: const InputDecoration(labelText: 'Nome completo'),
            validator: (value) => (value?.trim().length ?? 0) < 2
                ? 'Informe pelo menos 2 caracteres.' : null,
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancelar')),
          FilledButton(onPressed: () {
            if (form.currentState!.validate()) Navigator.pop(dialogContext, controller.text.trim());
          }, child: const Text('Salvar')),
        ],
      ),
    );
    controller.dispose();
    if (resultado == null || resultado == usuario.nome) return;
    try {
      final atualizado = await _service.alterarNome(resultado);
      UsuarioAtualStore.instance.atualizarUsuario(atualizado);
      currentUserSession.setUser(CurrentUser.fromJson({
        'id': atualizado.id, 'nome': atualizado.nome,
        'email': atualizado.email, 'perfil': atualizado.perfil,
      }));
      if (!mounted) return;
      setState(() => _usuario = Future.value(atualizado));
      _notificar('Nome atualizado com sucesso.');
    } catch (error) {
      _notificar(error.toString(), erro: true);
    }
  }

  Future<void> _trocarSenha() async {
    final atual = TextEditingController();
    final nova = TextEditingController();
    final confirmar = TextEditingController();
    final form = GlobalKey<FormState>();
    final valores = await showDialog<List<String>>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Alterar senha'),
        content: SizedBox(
          width: 400,
          child: Form(key: form, child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextFormField(controller: atual, obscureText: true,
              decoration: const InputDecoration(labelText: 'Senha atual'),
              validator: (value) => (value ?? '').isEmpty ? 'Informe a senha atual.' : null),
            const SizedBox(height: 12),
            TextFormField(controller: nova, obscureText: true,
              decoration: const InputDecoration(labelText: 'Nova senha'),
              validator: (value) => (value ?? '').length < 8 ? 'Use pelo menos 8 caracteres.' : null),
            const SizedBox(height: 12),
            TextFormField(controller: confirmar, obscureText: true,
              decoration: const InputDecoration(labelText: 'Confirme a nova senha'),
              validator: (value) => value != nova.text ? 'As senhas não coincidem.' : null),
          ])),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancelar')),
          FilledButton(onPressed: () {
            if (form.currentState!.validate()) {
              Navigator.pop(dialogContext, [atual.text, nova.text]);
            }
          }, child: const Text('Alterar senha')),
        ],
      ),
    );
    atual.dispose(); nova.dispose(); confirmar.dispose();
    if (valores == null) return;
    try {
      await _service.alterarSenha(valores[0], valores[1]);
      await LocalStorageService.removeToken();
      UsuarioAtualStore.instance.limparSessao();
      _demandas.limpar();
      currentUserSession.clear();
      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil(AppRoutes.login, (route) => false);
    } catch (error) {
      _notificar(error.toString(), erro: true);
    }
  }

  String _papel(String perfil) => switch (perfil) {
    'ADMIN' => 'Administrador',
    'TECNICO' => 'Desenvolvedor',
    'CLIENTE' => 'Cliente',
    _ => 'Usuário',
  };

  String _data(DateTime? value) {
    if (value == null) return 'Não informada';
    final local = value.toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    return two(local.day) + '/' + two(local.month) + '/' + local.year.toString();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<UsuarioAtualModel?>(
      future: _usuario,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(backgroundColor: AutomatizeColors.background,
            body: Center(child: CircularProgressIndicator()));
        }
        if (!snapshot.hasData || snapshot.hasError) {
          return Scaffold(backgroundColor: AutomatizeColors.background,
            body: Center(child: TextButton(onPressed: () {
              setState(() => _usuario = UsuarioAtualStore.instance.carregar());
            }, child: const Text('Não foi possível carregar o perfil. Tentar novamente'))));
        }
        final usuario = snapshot.data!;
        final conteudo = _conteudo(usuario);
        if (usuario.perfil == 'TECNICO') {
          return AdminLayout(child: conteudo);
        }
        return MainLayout(
          selectedIndex: -1,
          onDestinationSelected: (index) {
            if (index == 0) Navigator.of(context).pushReplacementNamed(AppRoutes.painel);
            if (index == 1) Navigator.of(context).pushReplacementNamed(AppRoutes.demandas);
          },
          child: conteudo,
        );
      },
    );
  }

  Widget _conteudo(UsuarioAtualModel usuario) {
    return Scaffold(
      backgroundColor: AutomatizeColors.background,
      body: RefreshIndicator(
        onRefresh: _recarregar,
        child: LayoutBuilder(builder: (context, limits) {
          final horizontal = limits.maxWidth >= 900 ? 34.0 : 16.0;
          return ListView(
            padding: EdgeInsets.fromLTRB(horizontal, 28, horizontal, 48),
            children: [
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1220),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('Meu perfil', style: TextStyle(color: AutomatizeColors.text, fontSize: 27, fontWeight: FontWeight.w800)),
                        SizedBox(height: 6),
                        Text('Gerencie seus dados pessoais, segurança e preferências.',
                          style: TextStyle(color: AutomatizeColors.muted)),
                      ])),
                      IconButton(onPressed: _recarregar, tooltip: 'Atualizar perfil',
                        icon: const Icon(Icons.refresh_rounded, color: AutomatizeColors.cyan)),
                    ]),
                    const SizedBox(height: 22),
                    FutureBuilder<PerfilDetalhes>(
                      future: _detalhes,
                      builder: (context, resultado) => _paineis(usuario,
                        resultado.hasData ? resultado.data : null,
                        mensagemDetalhes: resultado.hasError
                          ? 'Os detalhes da conta estão temporariamente indisponíveis.' : null),
                    ),
                  ]),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _paineis(UsuarioAtualModel usuario, PerfilDetalhes? detalhes, {String? mensagemDetalhes}) {
    return LayoutBuilder(builder: (context, box) {
      final largo = box.maxWidth >= 850;
      final gap = 16.0;
      final col = largo ? (box.maxWidth - gap) / 2 : box.maxWidth;
      final demandaDisponivel = _demandas.carregado && _demandas.erro == null;
      final visiveis = usuario.perfil == 'TECNICO'
        ? _demandas.demandas.where((d) => d.responsavelId == usuario.id).toList()
        : _demandas.demandas;

      Widget grupo(Widget esquerda, Widget direita) {
        return Wrap(spacing: gap, runSpacing: gap, children: [
          SizedBox(width: col, child: esquerda),
          SizedBox(width: col, child: direita),
        ]);
      }

      return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        grupo(_cabecalho(usuario, detalhes), _conta(usuario, detalhes, mensagemDetalhes)),
        const SizedBox(height: 16),
        grupo(_pessoais(usuario), _seguranca()),
        const SizedBox(height: 16),
        grupo(_preferencias(), _porPapel(usuario, visiveis, demandaDisponivel)),
        const SizedBox(height: 16),
        _cartao(
          titulo: 'Atividade da conta',
          subtitulo: 'Transparência sobre os dados disponíveis neste ambiente.',
          icone: Icons.timeline_rounded,
          cor: AutomatizeColors.success,
          child: const Text(
            'O histórico detalhado de acessos e alterações ainda não está disponível pela API. '
            'Nenhuma atividade fictícia será exibida.',
            style: TextStyle(color: AutomatizeColors.muted, height: 1.55),
          ),
        ),
      ]);
    });
  }

  Widget _cabecalho(UsuarioAtualModel u, PerfilDetalhes? d) {
    return _cartao(titulo: '', icone: Icons.person_rounded, cor: AutomatizeColors.purple,
      child: LayoutBuilder(builder: (context, c) {
        final pequeno = c.maxWidth < 390;
        final avatar = CircleAvatar(
          radius: 38, backgroundColor: AutomatizeColors.purple,
          child: Text(u.iniciais, style: const TextStyle(color: Colors.white,
            fontWeight: FontWeight.w800, fontSize: 24)),
        );
        final info = Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(u.nome, maxLines: 2, overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: AutomatizeColors.text, fontSize: 23, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text(_papel(u.perfil), style: const TextStyle(color: AutomatizeColors.muted)),
          const SizedBox(height: 6),
          Text(u.email, overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: AutomatizeColors.muted, fontSize: 12)),
          const SizedBox(height: 9),
          Text(d == null ? 'Conta autenticada' : (d.ativo ? '● Ativo' : 'Inativo'),
            style: const TextStyle(color: AutomatizeColors.success, fontWeight: FontWeight.w700)),
        ]);
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (pequeno) ...[avatar, const SizedBox(height: 14), info]
          else Row(children: [avatar, const SizedBox(width: 18), Expanded(child: info)]),
          const SizedBox(height: 16),
          FilledButton.icon(onPressed: () => _editarNome(u),
            icon: const Icon(Icons.edit_outlined, size: 17),
            label: const Text('Editar perfil')),
        ]);
      }),
    );
  }

  Widget _conta(UsuarioAtualModel u, PerfilDetalhes? d, String? erro) {
    return _cartao(titulo: 'Informações da conta', icone: Icons.info_outline_rounded,
      cor: AutomatizeColors.cyan,
      child: Column(children: [
        _linha('Tipo de conta', _papel(u.perfil)),
        _linha('Criada em', d == null ? 'Não informado' : _data(d.criadoEm)),
        _linha('E-mail', d == null ? 'Não verificado' : (d.emailVerificado ? 'Verificado' : 'Não verificado')),
        _linha('Situação', d == null ? 'Consultando' : (d.ativo ? 'Ativa' : 'Inativa')),
        if (erro != null) Padding(padding: const EdgeInsets.only(top: 12),
          child: Text(erro, style: const TextStyle(color: AutomatizeColors.warning))),
      ]),
    );
  }

  Widget _pessoais(UsuarioAtualModel u) {
    return _cartao(titulo: 'Informações pessoais', subtitulo: 'Dados reais vinculados à sua conta.',
      icone: Icons.badge_outlined, cor: AutomatizeColors.purple,
      child: Column(children: [
        _linha('Nome completo', u.nome),
        _linha('E-mail', u.email),
        _linha('Identificador', u.id),
        const SizedBox(height: 7),
        const Text('O e-mail e o tipo de conta são protegidos. '
          'Somente seu nome pode ser alterado nesta tela.',
          style: TextStyle(color: AutomatizeColors.muted, fontSize: 12)),
      ]),
    );
  }

  Widget _seguranca() {
    return _cartao(titulo: 'Segurança da conta',
      subtitulo: 'Proteja sua identidade e suas credenciais.',
      icone: Icons.shield_outlined, cor: AutomatizeColors.primary,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Alterar senha', style: TextStyle(
          color: AutomatizeColors.text, fontWeight: FontWeight.w700)),
        const SizedBox(height: 5),
        const Text('Confirme sua senha atual. Após a alteração, será necessário entrar novamente.',
          style: TextStyle(color: AutomatizeColors.muted, fontSize: 12)),
        const SizedBox(height: 12),
        OutlinedButton.icon(onPressed: _trocarSenha, icon: const Icon(Icons.lock_reset_rounded),
          label: const Text('Alterar senha')),
        const Divider(color: AutomatizeColors.border, height: 30),
        const Text('Autenticação em duas etapas e sessões ativas',
          style: TextStyle(color: AutomatizeColors.text, fontWeight: FontWeight.w700)),
        const SizedBox(height: 5),
        const Text('Essas funcionalidades ainda não são oferecidas pela API. '
          'Não exibimos uma proteção como ativada sem que esteja implementada.',
          style: TextStyle(color: AutomatizeColors.muted, fontSize: 12, height: 1.5)),
      ]),
    );
  }

  Widget _preferencias() {
    return _cartao(titulo: 'Preferências', subtitulo: 'Configurações da interface atual.',
      icone: Icons.tune_rounded, cor: AutomatizeColors.cyan,
      child: const Column(children: [
        _PreferenceRow(Icons.dark_mode_outlined, 'Tema', 'Escuro'),
        Divider(color: AutomatizeColors.border, height: 24),
        _PreferenceRow(Icons.language_rounded, 'Idioma', 'Português (Brasil)'),
        Divider(color: AutomatizeColors.border, height: 24),
        Text('As preferências personalizáveis de notificações e tema serão disponibilizadas '
          'quando houver suporte de persistência.',
          style: TextStyle(color: AutomatizeColors.muted, fontSize: 12, height: 1.5)),
      ]),
    );
  }

  Widget _porPapel(UsuarioAtualModel u, List<DemandaItem> demandas, bool disponivel) {
    final tipo = u.perfil;
    final titulo = tipo == 'ADMIN' ? 'Administração e permissões'
      : tipo == 'TECNICO' ? 'Ferramentas de desenvolvimento' : 'Resumo de solicitações';
    final icone = tipo == 'ADMIN' ? Icons.admin_panel_settings_outlined
      : tipo == 'TECNICO' ? Icons.code_rounded : Icons.fact_check_outlined;
    final destino = tipo == 'ADMIN' ? AppRoutes.admin
      : tipo == 'TECNICO' ? TechnicalRoutes.demandList : AppRoutes.demandas;
    final textoDestino = tipo == 'ADMIN' ? 'Abrir painel administrativo'
      : tipo == 'TECNICO' ? 'Ver demandas atribuídas' : 'Ver minhas demandas';
    String normalizar(String valor) => valor.trim().toUpperCase()
        .replaceAll('Ç', 'C').replaceAll('Ã', 'A').replaceAll('É', 'E')
        .replaceAll('PLANEAMENTO', 'PLANEJAMENTO');
    final pendentes = demandas.where((d) => normalizar(d.estado) == 'PLANEJAMENTO').length;
    final execucao = demandas.where((d) => normalizar(d.estado) == 'EXECUCAO').length;
    final homologacao = demandas.where((d) => normalizar(d.estado) == 'HOMOLOGACAO').length;
    final concluido = demandas.where((d) => normalizar(d.estado) == 'CONCLUIDO').length;
    return _cartao(titulo: titulo,
      subtitulo: tipo == 'TECNICO' ? 'Demandas atribuídas a você.'
        : 'Dados restritos às demandas visíveis pela sua conta.',
      icone: icone, cor: AutomatizeColors.success,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (_demandas.erro != null)
          const Text('Não foi possível carregar as demandas.',
            style: TextStyle(color: AutomatizeColors.warning))
        else if (!disponivel)
          const LinearProgressIndicator()
        else Wrap(spacing: 10, runSpacing: 10, children: [
          _indicador('Planejamento', pendentes, AutomatizeColors.purple),
          _indicador('Execução', execucao, AutomatizeColors.primary),
          _indicador('Homologação', homologacao, AutomatizeColors.warning),
          _indicador('Concluído', concluido, AutomatizeColors.success),
        ]),
        const SizedBox(height: 16),
        Align(alignment: Alignment.centerLeft,
          child: OutlinedButton.icon(
            onPressed: () => Navigator.of(context).pushNamed(destino),
            icon: const Icon(Icons.arrow_forward_rounded, size: 17),
            label: Text(textoDestino),
          )),
      ]),
    );
  }

  Widget _indicador(String title, int n, Color color) {
    return Container(
      width: 123, padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AutomatizeColors.background,
        border: Border.all(color: color.withValues(alpha: 0.5)),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(color: AutomatizeColors.muted, fontSize: 11)),
        const SizedBox(height: 6),
        Text(n.toString(), style: TextStyle(color: color, fontSize: 24, fontWeight: FontWeight.w800)),
      ]),
    );
  }

  Widget _cartao({
    required String titulo, required IconData icone, required Color cor,
    String? subtitulo, required Widget child,
  }) => Container(
    padding: const EdgeInsets.all(21),
    decoration: BoxDecoration(
      gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight,
        colors: [AutomatizeColors.panel, AutomatizeColors.panelLight.withValues(alpha: 0.60)]),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: cor.withValues(alpha: 0.55)),
      boxShadow: [BoxShadow(color: cor.withValues(alpha: 0.07), blurRadius: 18)],
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      if (titulo.isNotEmpty) ...[
        Row(children: [
          Container(padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: cor.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(10)),
            child: Icon(icone, color: cor, size: 22)),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(titulo, style: const TextStyle(color: AutomatizeColors.text,
              fontWeight: FontWeight.w800, fontSize: 16)),
            if (subtitulo != null) Padding(padding: const EdgeInsets.only(top: 3),
              child: Text(subtitulo, style: const TextStyle(color: AutomatizeColors.muted, fontSize: 12))),
          ])),
        ]),
        const SizedBox(height: 18),
      ],
      child,
    ]),
  );

  Widget _linha(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 7),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SizedBox(width: 124, child: Text(label,
        style: const TextStyle(color: AutomatizeColors.muted, fontSize: 12))),
      Expanded(child: SelectableText(value,
        style: const TextStyle(color: AutomatizeColors.text, fontWeight: FontWeight.w600, fontSize: 12))),
    ]),
  );
}

class _PreferenceRow extends StatelessWidget {
  const _PreferenceRow(this.icon, this.label, this.value);
  final IconData icon;
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Row(children: [
    Icon(icon, color: AutomatizeColors.cyan, size: 19),
    const SizedBox(width: 10),
    Expanded(child: Text(label, style: const TextStyle(color: AutomatizeColors.muted))),
    Text(value, style: const TextStyle(color: AutomatizeColors.text, fontWeight: FontWeight.w700)),
  ]);
}
