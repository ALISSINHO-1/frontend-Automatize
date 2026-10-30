import 'package:flutter/material.dart';

import '../../../../shared/widgets/main_layout.dart';
import '../../../demands/data/models/pedido_model.dart';
import '../../../demands/data/services/demand_service.dart';
import '../../../home/presentation/pages/demandas_screen.dart';
import '../../../home/presentation/pages/painel_screen.dart';
import '../../data/services/admin_demand_service.dart';
import '../admin_style.dart';
import '../widgets/admin_demand_dialogs.dart';
import 'admin_demand_details_page.dart';

/// Painel administrativo: contagem por estado (SCRUM-63) e gestão das
/// demandas (SCRUM-77). O filtro por estado serve para acompanhar a fila de
/// homologação (SCRUM-78). Protegido por `AdminGuard` na rota.
class AdminPanelPage extends StatefulWidget {
  const AdminPanelPage({super.key, this.service, this.adminService});

  final DemandService? service;
  final AdminDemandService? adminService;

  @override
  State<AdminPanelPage> createState() => _AdminPanelPageState();
}

class _AdminPanelPageState extends State<AdminPanelPage> {
  late final DemandService _service = widget.service ?? DemandService();
  late final AdminDemandService _admin =
      widget.adminService ?? AdminDemandService();
  late Future<List<PedidoModel>> _demandas = _service.buscarDemandas();
  String? _estado;
  bool _ocupado = false;

  static const _estados = [
    'PLANEAMENTO',
    'EXECUCAO',
    'HOMOLOGACAO',
    'CONCLUIDO',
  ];

  @override
  void dispose() {
    if (widget.service == null) _service.dispose();
    if (widget.adminService == null) _admin.dispose();
    super.dispose();
  }

  void _recarregar() => setState(() => _demandas = _service.buscarDemandas());

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

  void _mensagem(String texto) => ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(texto)));

  Future<void> _cadastrar() async {
    final dados = await DemandFormDialog.show(context);
    if (dados == null || !mounted) return;
    await _executar(
      () => _admin.criarDemanda(
        titulo: dados.titulo,
        descricao: dados.descricao,
        clienteId: dados.clienteId,
      ),
      'Demanda cadastrada.',
    );
  }

  Future<void> _editar(PedidoModel pedido) async {
    final dados = await DemandFormDialog.show(
      context,
      tituloInicial: pedido.titulo,
      descricaoInicial: pedido.descricao,
    );
    if (dados == null || !mounted) return;
    await _executar(
      () => _admin.editarDemanda(
        pedido.id,
        titulo: dados.titulo,
        descricao: dados.descricao,
      ),
      'Demanda atualizada.',
    );
  }

  Future<void> _atribuir(PedidoModel pedido) async {
    final responsavel = await AssignTechnicianDialog.show(
      context,
      responsavelAtual: pedido.responsavelId,
    );
    if (responsavel == null || !mounted) return;
    await _executar(
      () => _admin.atribuirResponsavel(pedido.id, responsavel),
      'Técnico atribuído.',
    );
  }

  Future<void> _excluir(PedidoModel pedido) async {
    if (!await confirmarExclusaoDemanda(context, pedido.titulo)) return;
    await _executar(
      () => _admin.excluirDemanda(pedido.id),
      'Demanda excluída.',
    );
  }

  Future<void> _abrir(PedidoModel pedido) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => AdminDemandDetailsPage(
          pedido: pedido,
          adminService: widget.adminService,
        ),
      ),
    );
    // Os detalhes podem ter editado ou excluído a demanda.
    if (mounted) _recarregar();
  }

  void _trocarTela(Widget tela) => Navigator.of(
    context,
  ).pushReplacement(MaterialPageRoute<void>(builder: (_) => tela));

  @override
  Widget build(BuildContext context) {
    // O Material evita o sublinhado amarelo do Flutter nos textos do menu lateral.
    return Material(
      color: AdminStyle.fundo,
      child: MainLayout(
        selectedIndex: MainLayout.indiceAdmin,
        onDestinationSelected: (index) {
          if (index == 0) _trocarTela(const PainelScreen());
          if (index == 1) _trocarTela(const DemandasScreen());
        },
        child: Scaffold(
          backgroundColor: AdminStyle.fundo,
          body: SafeArea(
            child: FutureBuilder<List<PedidoModel>>(
              future: _demandas,
              builder: (context, snapshot) {
                final todas = snapshot.data ?? const <PedidoModel>[];
                return ListView(
                  padding: const EdgeInsets.fromLTRB(32, 32, 32, 40),
                  children: [
                    _cabecalho(),
                    const SizedBox(height: 28),
                    if (snapshot.connectionState == ConnectionState.waiting)
                      const Padding(
                        padding: EdgeInsets.all(48),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else if (snapshot.hasError)
                      _erro('${snapshot.error}')
                    else ...[
                      _contagens(todas),
                      const SizedBox(height: 32),
                      _gerenciamento(todas),
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
          Text('Painel administrativo', style: AdminStyle.titulo),
          SizedBox(height: 6),
          Text(
            'Gerencie as demandas, os responsáveis e acompanhe cada etapa.',
            style: AdminStyle.subtitulo,
          ),
        ],
      ),
      Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: 'Atualizar',
            onPressed: _recarregar,
            color: AutomatizeColors.muted,
            icon: const Icon(Icons.refresh_rounded),
          ),
          const SizedBox(width: 8),
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
            icon: const Icon(Icons.add_rounded),
            label: const Text('Nova demanda'),
          ),
        ],
      ),
    ],
  );

  Widget _contagens(List<PedidoModel> todas) {
    const icones = {
      'PLANEAMENTO': Icons.calendar_month_rounded,
      'EXECUCAO': Icons.build_rounded,
      'HOMOLOGACAO': Icons.fact_check_rounded,
      'CONCLUIDO': Icons.check_circle_outline_rounded,
    };
    return Wrap(
      spacing: 18,
      runSpacing: 18,
      children: [
        for (final estado in _estados)
          _CardEstado(
            estado: estado,
            icone: icones[estado]!,
            total: todas
                .where((d) => AdminStyle.normalizar(d.status) == estado)
                .length,
            selecionado: _estado == estado,
            // Clicar no card filtra a lista; clicar de novo limpa o filtro.
            onTap: () =>
                setState(() => _estado = _estado == estado ? null : estado),
          ),
      ],
    );
  }

  Widget _gerenciamento(List<PedidoModel> todas) {
    final visiveis = _estado == null
        ? todas
        : todas
              .where((d) => AdminStyle.normalizar(d.status) == _estado)
              .toList();
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: AdminStyle.caixa(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AdminStyle.destaque.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.admin_panel_settings_rounded,
                  color: AdminStyle.destaqueClaro,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Gerenciamento de demandas',
                      style: AdminStyle.tituloCard,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _estado == null
                          ? '${todas.length} demanda(s) cadastrada(s).'
                          : '${visiveis.length} em ${AdminStyle.rotuloEstado(_estado!)}.',
                      style: AdminStyle.subtitulo,
                    ),
                  ],
                ),
              ),
              if (_estado != null)
                TextButton.icon(
                  onPressed: () => setState(() => _estado = null),
                  icon: const Icon(Icons.filter_alt_off_rounded, size: 18),
                  label: const Text('Limpar filtro'),
                ),
            ],
          ),
          if (_ocupado) ...[
            const SizedBox(height: 14),
            const LinearProgressIndicator(color: AdminStyle.destaque),
          ],
          const SizedBox(height: 18),
          if (visiveis.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 28),
              child: Center(
                child: Text(
                  'Nenhuma demanda encontrada.',
                  style: AdminStyle.subtitulo,
                ),
              ),
            )
          else
            for (final pedido in visiveis) ...[
              _ItemDemanda(
                pedido: pedido,
                ocupado: _ocupado,
                onAbrir: () => _abrir(pedido),
                onEditar: () => _editar(pedido),
                onAtribuir: () => _atribuir(pedido),
                onExcluir: () => _excluir(pedido),
              ),
              const SizedBox(height: 12),
            ],
        ],
      ),
    );
  }

  Widget _erro(String mensagem) => Container(
    padding: const EdgeInsets.all(28),
    decoration: AdminStyle.caixa(),
    child: Column(
      children: [
        const Icon(
          Icons.cloud_off_rounded,
          color: AutomatizeColors.danger,
          size: 36,
        ),
        const SizedBox(height: 12),
        Text(
          'Não foi possível carregar as demandas.\n$mensagem',
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

class _CardEstado extends StatelessWidget {
  const _CardEstado({
    required this.estado,
    required this.icone,
    required this.total,
    required this.selecionado,
    required this.onTap,
  });

  final String estado;
  final IconData icone;
  final int total;
  final bool selecionado;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cor = AdminStyle.corEstado(estado);
    return SizedBox(
      width: 240,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Ink(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: cor.withValues(alpha: selecionado ? 0.95 : 0.55),
                width: selecionado ? 2 : 1,
              ),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AdminStyle.card, cor.withValues(alpha: 0.16)],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icone, color: cor, size: 26),
                const SizedBox(height: 14),
                Text(
                  '$total',
                  style: const TextStyle(
                    color: AutomatizeColors.text,
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        AdminStyle.rotuloEstado(estado) == 'EXECUÇÃO'
                            ? 'Execução'
                            : _capitalizar(AdminStyle.rotuloEstado(estado)),
                        style: const TextStyle(
                          color: AutomatizeColors.text,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Icon(Icons.bar_chart_rounded, color: cor, size: 20),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static String _capitalizar(String texto) =>
      texto[0] + texto.substring(1).toLowerCase();
}

class _ItemDemanda extends StatelessWidget {
  const _ItemDemanda({
    required this.pedido,
    required this.ocupado,
    required this.onAbrir,
    required this.onEditar,
    required this.onAtribuir,
    required this.onExcluir,
  });

  final PedidoModel pedido;
  final bool ocupado;
  final VoidCallback onAbrir;
  final VoidCallback onEditar;
  final VoidCallback onAtribuir;
  final VoidCallback onExcluir;

  @override
  Widget build(BuildContext context) {
    final cor = AdminStyle.corEstado(pedido.status);
    // Concluída é imutável no backend (409): só sobra abrir os detalhes.
    final concluida = AdminStyle.normalizar(pedido.status) == 'CONCLUIDO';
    return Material(
      color: AdminStyle.fundo,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onAbrir,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AdminStyle.cardBorda),
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: cor.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.assignment_rounded, color: cor),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(pedido.titulo, style: AdminStyle.tituloCard),
                    const SizedBox(height: 4),
                    Text(
                      pedido.descricao.isEmpty
                          ? 'Sem descrição.'
                          : pedido.descricao,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AdminStyle.subtitulo.copyWith(fontSize: 13),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 18,
                      runSpacing: 6,
                      children: [
                        _Meta(
                          Icons.tag_rounded,
                          pedido.codigoIdentificador ?? 'Sem código',
                        ),
                        _Meta(
                          Icons.engineering_rounded,
                          // A API ainda não lista usuários: só há o UUID do técnico.
                          pedido.responsavelId == null
                              ? 'Técnico: não atribuído'
                              : 'Técnico: ${pedido.responsavelId!.substring(0, 8)}…',
                        ),
                        _Meta(
                          Icons.event_rounded,
                          AdminStyle.data(pedido.createdAt),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              EstadoChip(pedido.status),
              PopupMenuButton<String>(
                tooltip: 'Ações da demanda',
                enabled: !ocupado,
                color: AdminStyle.card,
                iconColor: AutomatizeColors.muted,
                onSelected: (acao) => switch (acao) {
                  'editar' => onEditar(),
                  'atribuir' => onAtribuir(),
                  'excluir' => onExcluir(),
                  _ => onAbrir(),
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(
                    value: 'abrir',
                    child: Text('Abrir detalhes'),
                  ),
                  if (!concluida) ...const [
                    PopupMenuItem(value: 'editar', child: Text('Editar')),
                    PopupMenuItem(
                      value: 'atribuir',
                      child: Text('Atribuir técnico'),
                    ),
                    PopupMenuItem(value: 'excluir', child: Text('Excluir')),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Meta extends StatelessWidget {
  const _Meta(this.icone, this.texto);

  final IconData icone;
  final String texto;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icone, size: 14, color: AutomatizeColors.muted),
      const SizedBox(width: 5),
      Text(
        texto,
        style: const TextStyle(color: AutomatizeColors.muted, fontSize: 12),
      ),
    ],
  );
}
