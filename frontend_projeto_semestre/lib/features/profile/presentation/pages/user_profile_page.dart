import 'package:flutter/material.dart';
import '../../../../app/routes/app_routes.dart';
import '../../../../features/admin/data/models/usuario_atual_model.dart';
import '../../../../features/admin/data/services/usuario_atual_store.dart';
import '../../../../features/home/presentation/pages/demanda_store.dart';
import '../../../../shared/widgets/main_layout.dart';

class UserProfilePage extends StatefulWidget {
  const UserProfilePage({super.key});
  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  final DemandaStore _store = DemandaStore.instance;
  late final Future<UsuarioAtualModel?> _usuario = UsuarioAtualStore.instance
      .carregar();
  @override
  void initState() {
    super.initState();
    _store.addListener(_atualizar);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _store.carregarDemandas();
    });
  }

  void _atualizar() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _store.removeListener(_atualizar);
    super.dispose();
  }

  String _perfil(String? valor) => switch (valor) {
    'ADMIN' => 'Administrador',
    'TECNICO' => 'Técnico',
    'CLIENTE' => 'Cliente',
    _ => 'Conta',
  };
  String _data(DateTime? valor) {
    if (valor == null) return 'Não informada';
    final local = valor.toLocal();
    String dois(int numero) => numero.toString().padLeft(2, '0');
    return '${dois(local.day)}/${dois(local.month)}/${local.year}';
  }

  List<DemandaItem> _demandasDoUsuario(UsuarioAtualModel usuario) {
    final id = usuario.id;
    if (usuario.perfil == 'TECNICO') {
      return _store.demandas.where((d) => d.responsavelId == id).toList();
    }
    // Para clientes e administradores, o conjunto retornado pela API
    // pode ter regras próprias. Não atribuímos demandas sem evidência.
    return [];
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      selectedIndex: -1,
      onDestinationSelected: (index) {
        if (index == 0) {
          Navigator.of(context).pushReplacementNamed(AppRoutes.painel);
        } else if (index == 1) {
          Navigator.of(context).pushReplacementNamed(AppRoutes.demandas);
        }
      },
      child: Scaffold(
        backgroundColor: AutomatizeColors.background,
        body: FutureBuilder<UsuarioAtualModel?>(
          future: _usuario,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError || snapshot.data == null) {
              return const Center(
                child: Text(
                  'Não foi possível carregar as informações da conta.',
                  style: TextStyle(color: AutomatizeColors.muted),
                ),
              );
            }
            final usuario = snapshot.data!;
            final demandas = _demandasDoUsuario(usuario);
            return RefreshIndicator(
              onRefresh: _store.carregarDemandas,
              child: ListView(
                padding: const EdgeInsets.all(28),
                children: [
                  const Text(
                    'Meu perfil',
                    style: TextStyle(
                      color: AutomatizeColors.text,
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Informações da conta e visão geral das atividades',
                    style: TextStyle(color: AutomatizeColors.muted),
                  ),
                  const SizedBox(height: 24),
                  _cartaoConta(usuario),
                  const SizedBox(height: 22),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final estreito = constraints.maxWidth < 620;
                      final cartoes = [
                        _indicador(
                          'Demandas atribuídas',
                          _store.carregando ? '...' : '${demandas.length}',
                          Icons.assignment_outlined,
                        ),
                        _indicador(
                          'Último acesso',
                          'Não disponível',
                          Icons.access_time_rounded,
                        ),
                      ];
                      return estreito
                          ? Column(
                              children: [
                                for (final cartao in cartoes) ...[
                                  cartao,
                                  const SizedBox(height: 12),
                                ],
                              ],
                            )
                          : Row(
                              children: [
                                Expanded(child: cartoes[0]),
                                const SizedBox(width: 16),
                                Expanded(child: cartoes[1]),
                              ],
                            );
                    },
                  ),
                  const SizedBox(height: 22),
                  _secao(
                    titulo: 'Atividades recentes',
                    icone: Icons.history_rounded,
                    conteudo: const Text(
                      'O histórico de movimentações ainda não está '
                      'disponível na API integrada.',
                      style: TextStyle(color: AutomatizeColors.muted),
                    ),
                  ),
                  const SizedBox(height: 22),
                  _secao(
                    titulo: 'Pedidos e demandas',
                    icone: Icons.folder_outlined,
                    conteudo: _conteudoDemandas(usuario, demandas),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _cartaoConta(UsuarioAtualModel usuario) {
    final nome = usuario.nome;
    final email = usuario.email.trim();
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: _decoracao(),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final estreito = constraints.maxWidth < 520;
          final avatar = Container(
            width: 88,
            height: 88,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [AutomatizeColors.cyan, AutomatizeColors.primary],
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              usuario.iniciais,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.w800,
              ),
            ),
          );
          final detalhes = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                nome,
                style: const TextStyle(
                  color: AutomatizeColors.text,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                _perfil(usuario.perfil),
                style: const TextStyle(
                  color: AutomatizeColors.cyan,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 20),
              _campo('Nome completo', nome),
              _campo('E-mail', email.isEmpty ? 'Não informado' : email),
              _campo('ID do usuário', usuario.id),
            ],
          );
          if (estreito) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [avatar, const SizedBox(height: 20), detalhes],
            );
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              avatar,
              const SizedBox(width: 24),
              Expanded(child: detalhes),
            ],
          );
        },
      ),
    );
  }

  Widget _campo(String titulo, String valor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titulo,
            style: const TextStyle(color: AutomatizeColors.muted, fontSize: 12),
          ),
          const SizedBox(height: 4),
          SelectableText(
            valor,
            style: const TextStyle(
              color: AutomatizeColors.text,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _indicador(String titulo, String valor, IconData icone) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _decoracao(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icone, color: AutomatizeColors.cyan, size: 23),
          const SizedBox(height: 14),
          Text(titulo, style: const TextStyle(color: AutomatizeColors.muted)),
          const SizedBox(height: 7),
          Text(
            valor,
            style: const TextStyle(
              color: AutomatizeColors.text,
              fontSize: 23,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _secao({
    required String titulo,
    required IconData icone,
    required Widget conteudo,
  }) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: _decoracao(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icone, color: AutomatizeColors.cyan),
              const SizedBox(width: 10),
              Text(
                titulo,
                style: const TextStyle(
                  color: AutomatizeColors.text,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          conteudo,
        ],
      ),
    );
  }

  Widget _conteudoDemandas(
    UsuarioAtualModel usuario,
    List<DemandaItem> demandas,
  ) {
    if (_store.carregando && !_store.carregado) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_store.erro != null) {
      return Text(
        'Não foi possível carregar as demandas: ${_store.erro}',
        style: const TextStyle(color: AutomatizeColors.danger),
      );
    }
    if (usuario.perfil != 'TECNICO') {
      return const Text(
        'A listagem de pedidos deste perfil ainda precisa de '
        'integração específica.',
        style: TextStyle(color: AutomatizeColors.muted),
      );
    }
    String normalizar(String status) {
      return status
          .trim()
          .toUpperCase()
          .replaceAll('Ã', 'A')
          .replaceAll('Ç', 'C')
          .replaceAll('Í', 'I')
          .replaceAll('É', 'E')
          .replaceAll('PLANEAMENTO', 'PLANEJAMENTO');
    }

    final aFazer = demandas.where((demanda) {
      return normalizar(demanda.estado) == 'PLANEJAMENTO';
    }).toList();
    final emAndamento = demandas.where((demanda) {
      final status = normalizar(demanda.estado);
      return status == 'EXECUCAO' || status == 'HOMOLOGACAO';
    }).toList();
    Widget colunaDemandas({
      required String titulo,
      required List<DemandaItem> itens,
      required IconData icone,
      required Color cor,
    }) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AutomatizeColors.panel,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AutomatizeColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icone, color: cor, size: 21),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(
                    titulo,
                    style: const TextStyle(
                      color: AutomatizeColors.text,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                ),
                Text(
                  '${itens.length}',
                  style: TextStyle(color: cor, fontWeight: FontWeight.w800),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (itens.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Center(
                  child: Text(
                    'Nenhuma demanda nesta etapa.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AutomatizeColors.muted),
                  ),
                ),
              )
            else
              for (final demanda in itens)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: () {
                        Navigator.of(
                          context,
                        ).pushNamed(AppRoutes.demandas, arguments: demanda.id);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AutomatizeColors.border),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.description_outlined,
                              color: cor,
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    demanda.titulo,
                                    style: const TextStyle(
                                      color: AutomatizeColors.text,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    '${demanda.estado} • ${_data(demanda.createdAt)}',
                                    style: const TextStyle(
                                      color: AutomatizeColors.muted,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.chevron_right_rounded,
                              color: AutomatizeColors.muted,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
          ],
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final estreito = constraints.maxWidth < 650;
        final colunaAFazer = colunaDemandas(
          titulo: 'A fazer',
          itens: aFazer,
          icone: Icons.pending_actions_outlined,
          cor: AutomatizeColors.purple,
        );
        final colunaEmAndamento = colunaDemandas(
          titulo: 'Em andamento',
          itens: emAndamento,
          icone: Icons.sync_rounded,
          cor: AutomatizeColors.cyan,
        );
        if (estreito) {
          return Column(
            children: [
              colunaAFazer,
              const SizedBox(height: 16),
              colunaEmAndamento,
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: colunaAFazer),
            const SizedBox(width: 16),
            Expanded(child: colunaEmAndamento),
          ],
        );
      },
    );
  }

  BoxDecoration _decoracao() {
    return BoxDecoration(
      color: AutomatizeColors.panel,
      borderRadius: BorderRadius.circular(17),
      border: Border.all(color: AutomatizeColors.border),
    );
  }
}
