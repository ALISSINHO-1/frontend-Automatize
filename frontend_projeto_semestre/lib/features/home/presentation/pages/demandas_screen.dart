import 'package:flutter/material.dart';

import '../../../../app/routes/app_routes.dart';
import '../../../../core/storage/local_storage_service.dart';
import '../../../../shared/widgets/main_layout.dart';
import '../../../admin/data/models/usuario_atual_model.dart';
import '../../../admin/data/services/usuario_atual_store.dart';
import '../../../demands/presentation/pages/demand_tasks_page.dart';
import 'demanda_store.dart';
import 'nova_demanda_screen.dart';
import 'visualizacoes_demandas.dart';

enum _Visualizacao { lista, quadro, calendario }

class DemandasScreen extends StatefulWidget {
  const DemandasScreen({super.key});
  @override
  State<DemandasScreen> createState() => _DemandasScreenState();
}

class _DemandasScreenState extends State<DemandasScreen> {
  final TextEditingController _buscaController = TextEditingController();
  final DemandaStore _store = DemandaStore.instance;
  late final Future<UsuarioAtualModel?> _usuario = UsuarioAtualStore.instance
      .carregar();
  List<DemandaItem> get _demandas => _store.demandas;
  bool get _carregando => _store.carregando;
  String? get _erro => _store.erro;
  // Compartilha com o painel os dados que vieram da API.
  Future<void> _carregarDemandas() => _store.carregarDemandas();
  void _atualizarDemandas() {
    if (mounted) setState(() {});
  }

  // Apresenta os nomes dos estados, sem mudar os valores vindos do backend.
  String _rotuloEstado(String estado) {
    switch (estado.trim().toUpperCase()) {
      case 'PLANEAMENTO':
      case 'PLANEJAMENTO':
        return 'Planejamento';
      case 'EXECUCAO':
      case 'EXECUÇÃO':
        return 'Execução';
      case 'HOMOLOGACAO':
      case 'HOMOLOGAÇÃO':
        return 'Homologação';
      case 'CONCLUIDO':
      case 'CONCLUÍDO':
        return 'Concluído';
      default:
        return estado.trim().isEmpty ? 'Não informado' : estado;
    }
  }

  String _formatarProgresso(DemandaItem demanda) {
    if (!demanda.progressoInformado) return 'Não informado';
    return '${demanda.progresso.toStringAsFixed(2).replaceAll('.', ',')}%';
  }

  // Um valor null mostra uma faixa neutra, não um progresso fictício de 0%.
  Widget _barraProgresso(DemandaItem demanda, Color cor, {double altura = 6}) {
    if (!demanda.progressoInformado) {
      return Container(
        height: altura,
        decoration: BoxDecoration(
          color: AutomatizeColors.border,
          borderRadius: BorderRadius.circular(altura),
        ),
      );
    }
    return LinearProgressIndicator(
      value: (demanda.progresso / 100).clamp(0.0, 1.0),
      minHeight: altura,
      backgroundColor: AutomatizeColors.border,
      valueColor: AlwaysStoppedAnimation<Color>(cor),
    );
  }

  Future<void> _abrirCadastro() async {
    final criado = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(builder: (_) => const NovaDemandaScreen()),
    );
    if (!mounted) return;
    if (criado == true) await _carregarDemandas();
  }

  _Visualizacao _visualizacao = _Visualizacao.lista;
  bool _movendoDemanda = false;

  String _filtroStatus = 'Todos os estados';
  static const List<String> _estados = [
    'Planejamento',
    'Execução',
    'Homologação',
    'Concluído',
  ];
  @override
  void initState() {
    super.initState();
    _store.addListener(_atualizarDemandas);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _carregarDemandas();
    });
  }

  @override
  void dispose() {
    _store.removeListener(_atualizarDemandas);
    _buscaController.dispose();
    super.dispose();
  }

  List<DemandaItem> get _demandasFiltradas {
    final busca = _buscaController.text.trim().toLowerCase();
    return _demandas.where((demanda) {
      final correspondeBusca =
          demanda.codigo.toLowerCase().contains(busca) ||
          demanda.titulo.toLowerCase().contains(busca) ||
          demanda.descricao.toLowerCase().contains(busca);
      final correspondeStatus =
          _filtroStatus == 'Todos os estados' ||
          _rotuloEstado(demanda.estado) == _filtroStatus;
      return correspondeBusca && correspondeStatus;
    }).toList();
  }

  int _contarEstado(String estado) => _demandas
      .where((demanda) => _rotuloEstado(demanda.estado) == estado)
      .length;
  Color _corStatus(String estado) {
    switch (_rotuloEstado(estado)) {
      case 'Planejamento':
        return const Color(0xFF8C9DFF);
      case 'Execução':
        return const Color(0xFF63A8FF);
      case 'Homologação':
        return AutomatizeColors.purple;
      case 'Concluído':
        return AutomatizeColors.success;
      default:
        return AutomatizeColors.muted;
    }
  }

  Future<void> _moverNoQuadro(
    DemandaItem demanda,
    String origem,
    String destino,
  ) async {
    if (_movendoDemanda) return;
    setState(() => _movendoDemanda = true);
    try {
      await _store.moverNoQuadro(demanda.id, origem, destino);
    } catch (erro) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('$erro')));
      await _carregarDemandas();
    } finally {
      if (mounted) setState(() => _movendoDemanda = false);
    }
  }

  Future<void> _editarPrevisao(DemandaItem demanda) async {
    final primeira = DateTime(1900);
    final ultima = DateTime(2200, 12, 31);
    final atual = demanda.dataPrevisao;
    final data = await showDatePicker(
      context: context,
      initialDate:
          atual == null || atual.isBefore(primeira) || atual.isAfter(ultima)
          ? DateTime.now()
          : atual,
      firstDate: primeira,
      lastDate: ultima,
    );
    if (!mounted || data == null) return;
    await _salvarPrevisao(demanda, data);
  }

  Future<void> _salvarPrevisao(DemandaItem demanda, DateTime? data) async {
    try {
      await _store.atualizarPrevisao(demanda.id, data);
    } catch (erro) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('$erro')));
    }
  }

  Future<void> _visualizarDemanda(DemandaItem demanda) async {
    final perfil = (await _usuario)?.perfil;
    if (!mounted) return;
    if (perfil == 'CLIENTE') {
      await Navigator.of(context).pushNamed(
        AppRoutes.clienteDetalhes,
        arguments: demanda.id,
      );
      if (mounted) await _carregarDemandas();
      return;
    }
    final podeEditar =
        (perfil == 'ADMIN' || perfil == 'CLIENTE') &&
        _rotuloEstado(demanda.estado) != 'Concluído';
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        final cor = _corStatus(demanda.estado);
        return AlertDialog(
          backgroundColor: AutomatizeColors.panel,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
            side: const BorderSide(color: AutomatizeColors.border),
          ),
          titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
          contentPadding: const EdgeInsets.fromLTRB(24, 10, 24, 12),
          title: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AutomatizeColors.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Icon(
                  Icons.assignment_outlined,
                  color: AutomatizeColors.cyan,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Detalhes da demanda',
                      style: TextStyle(
                        color: AutomatizeColors.text,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Informações e andamento',
                      style: TextStyle(
                        color: AutomatizeColors.muted,
                        fontSize: 12,
                        fontWeight: FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: 460,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: AutomatizeColors.panelLight,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AutomatizeColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _detailLine('Código', demanda.codigo),
                        const SizedBox(height: 14),
                        _detailLine('Título', demanda.titulo),
                        const SizedBox(height: 14),
                        _detailLine(
                          'Descrição',
                          demanda.descricao.isEmpty
                              ? 'Nenhuma descrição informada.'
                              : demanda.descricao,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 24,
                    runSpacing: 12,
                    children: [
                      for (final evento in datasDaDemanda(demanda))
                        _detailLine(
                          evento.rotulo,
                          evento.data == null
                              ? 'Sem data'
                              : MaterialLocalizations.of(
                                  context,
                                ).formatCompactDate(evento.data!),
                        ),
                    ],
                  ),
                  if (podeEditar)
                    Wrap(
                      children: [
                        TextButton(
                          onPressed: () {
                            Navigator.of(dialogContext).pop();
                            _editarPrevisao(demanda);
                          },
                          child: const Text('Alterar previsão'),
                        ),
                        if (demanda.dataPrevisao != null)
                          TextButton(
                            onPressed: () {
                              Navigator.of(dialogContext).pop();
                              _salvarPrevisao(demanda, null);
                            },
                            child: const Text('Remover previsão'),
                          ),
                      ],
                    ),
                  const SizedBox(height: 20),
                  const Text(
                    'ESTADO ATUAL',
                    style: TextStyle(
                      color: AutomatizeColors.muted,
                      fontSize: 10,
                      letterSpacing: 1.2,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 9),
                  _StatusChip(
                    status: _rotuloEstado(demanda.estado),
                    color: cor,
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Progresso da demanda',
                        style: TextStyle(
                          color: AutomatizeColors.text,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        _formatarProgresso(demanda),
                        style: TextStyle(
                          color: cor,
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 9),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: _barraProgresso(demanda, cor, altura: 9),
                  ),
                ],
              ),
            ),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
          actions: [
            TextButton.icon(
              onPressed: () async {
                final usuario = await _usuario;
                if (!dialogContext.mounted) return;
                await Navigator.of(dialogContext).push<bool>(
                  MaterialPageRoute(
                    builder: (_) => DemandTasksPage(
                      demandaId: demanda.id,
                      titulo: demanda.titulo,
                      status: demanda.estado,
                      usuario: usuario,
                    ),
                  ),
                );
                if (mounted) await _carregarDemandas();
              },
              icon: const Icon(Icons.checklist),
              label: const Text('Tarefas'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AutomatizeColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(11),
                ),
              ),
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Entendi'),
            ),
          ],
        );
      },
    );
  }

  Widget _detailLine(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            color: AutomatizeColors.muted,
            fontSize: 10,
            letterSpacing: 1.1,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          value,
          style: const TextStyle(
            color: AutomatizeColors.text,
            fontSize: 13,
            height: 1.45,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  void _navegarParaPainel() {
    Navigator.of(context).pushReplacementNamed(AppRoutes.painel);
  }

  Future<void> _sair() async {
    await LocalStorageService.removeToken();
    DemandaStore.instance.limpar();
    if (!mounted) return;
    Navigator.of(
      context,
      rootNavigator: true,
    ).pushNamedAndRemoveUntil(AppRoutes.login, (route) => false);
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<UsuarioAtualModel?>(
    future: _usuario,
    builder: (context, snapshot) => _pagina(snapshot.data),
  );

  Widget _pagina(UsuarioAtualModel? usuario) {
    final perfil = usuario?.perfil;
    final demandasVisiveis = _demandasFiltradas;
    return MainLayout(
      selectedIndex: 1,
      onDestinationSelected: (index) {
        if (index == 0) _navegarParaPainel();
      },
      onLogout: _sair,
      child: Scaffold(
        backgroundColor: AutomatizeColors.background,
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, area) {
              final compacto = area.maxWidth < 560;
              return Padding(
                padding: compacto
                    ? const EdgeInsets.fromLTRB(14, 14, 14, 10)
                    : const EdgeInsets.fromLTRB(28, 26, 28, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _pageHeader(perfil, compacto: compacto),
                    SizedBox(height: compacto ? 12 : 23),
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: area.maxHeight * .48,
                      ),
                      child: SingleChildScrollView(
                        primary: false,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _indicadores(perfil, compacto: compacto),
                            SizedBox(height: compacto ? 12 : 22),
                            _buildFilters(perfil),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: compacto ? 10 : 17),
                    Expanded(
                      child: _carregando
                          ? const Center(child: CircularProgressIndicator())
                          : _erro != null
                          ? Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    _erro!,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: AutomatizeColors.danger,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  FilledButton.icon(
                                    onPressed: _carregarDemandas,
                                    icon: const Icon(Icons.refresh),
                                    label: const Text('Tentar novamente'),
                                  ),
                                ],
                              ),
                            )
                          : switch (_visualizacao) {
                              _Visualizacao.lista => _buildDemandasTable(
                                demandasVisiveis,
                              ),
                              _Visualizacao.quadro => QuadroDemandas(
                                demandas: demandasVisiveis,
                                estados: _estados,
                                rotuloEstado: _rotuloEstado,
                                corEstado: _corStatus,
                                abrir: _visualizarDemanda,
                                tecnicoId: perfil == 'TECNICO'
                                    ? usuario?.id
                                    : null,
                                mover: _movendoDemanda ? null : _moverNoQuadro,
                              ),
                              _Visualizacao.calendario => CalendarioDemandas(
                                demandas: demandasVisiveis,
                                abrir: _visualizarDemanda,
                              ),
                            },
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(
                          Icons.shield_outlined,
                          size: 15,
                          color: AutomatizeColors.muted,
                        ),
                        const SizedBox(width: 7),
                        const Expanded(
                          child: Text(
                            'As informações são exibidas conforme a atualização das demandas.',
                            style: TextStyle(
                              color: AutomatizeColors.muted,
                              fontSize: 10,
                            ),
                          ),
                        ),
                        Text(
                          '${demandasVisiveis.length} '
                          '${demandasVisiveis.length == 1 ? 'resultado' : 'resultados'}',
                          style: const TextStyle(
                            color: AutomatizeColors.muted,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _pageHeader(String? perfil, {required bool compacto}) {
    final (titulo, subtitulo, area) = switch (perfil) {
      'TECNICO' => (
        'Demandas atribuídas',
        'Acompanhe as demandas sob sua responsabilidade.',
        'Área técnica',
      ),
      'ADMIN' => (
        'Demandas',
        'Acompanhe o andamento das demandas cadastradas.',
        'Área administrativa',
      ),
      'CLIENTE' => (
        'Minhas demandas',
        'Acompanhe o andamento e as atualizações do seu projeto.',
        'Área do cliente',
      ),
      _ => ('Demandas', 'Acompanhe o andamento das demandas.', 'Área da conta'),
    };
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: AutomatizeColors.primary.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AutomatizeColors.primary.withValues(alpha: 0.26),
            ),
          ),
          child: const Icon(
            Icons.assignment_rounded,
            color: AutomatizeColors.cyan,
            size: 25,
          ),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                titulo,
                style: const TextStyle(
                  color: AutomatizeColors.text,
                  fontSize: 25,
                  height: 1.15,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.6,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                subtitulo,
                style: const TextStyle(
                  color: AutomatizeColors.muted,
                  fontSize: 12,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
        if (!compacto) ...[
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: BoxDecoration(
              color: AutomatizeColors.panel,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AutomatizeColors.border),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.verified_user_outlined,
                  size: 15,
                  color: AutomatizeColors.success,
                ),
                const SizedBox(width: 7),
                Text(
                  area,
                  style: const TextStyle(
                    color: AutomatizeColors.muted,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _indicadores(String? perfil, {required bool compacto}) {
    final cards = <Widget>[
      _summaryCard(
        title: 'Total de demandas',
        value: _demandas.length.toString(),
        subtitle: perfil == 'TECNICO'
            ? 'Atribuídas a você'
            : 'Visíveis para sua conta',
        icon: Icons.view_list_rounded,
        color: AutomatizeColors.cyan,
      ),
      _summaryCard(
        title: 'Em planejamento',
        value: _contarEstado('Planejamento').toString(),
        subtitle: 'Em fase de organização',
        icon: Icons.event_note_rounded,
        color: const Color(0xFF8C9DFF),
      ),
      _summaryCard(
        title: 'Em execução',
        value: _contarEstado('Execução').toString(),
        subtitle: 'Em andamento',
        icon: Icons.autorenew_rounded,
        color: const Color(0xFF63A8FF),
      ),
      _summaryCard(
        title: 'Em homologação',
        value: _contarEstado('Homologação').toString(),
        subtitle: 'Aguardando validação',
        icon: Icons.fact_check_outlined,
        color: AutomatizeColors.purple,
      ),
      _summaryCard(
        title: 'Concluídas',
        value: _contarEstado('Concluído').toString(),
        subtitle: 'Etapas finalizadas',
        icon: Icons.task_alt_rounded,
        color: AutomatizeColors.success,
      ),
    ];
    if (!compacto) return Wrap(spacing: 14, runSpacing: 12, children: cards);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(spacing: 10, children: cards),
    );
  }

  Widget _summaryCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return SizedBox(
      width: 220,
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AutomatizeColors.panel,
              AutomatizeColors.panel.withValues(alpha: 0.86),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(17),
          border: Border.all(color: AutomatizeColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    value,
                    style: const TextStyle(
                      color: AutomatizeColors.text,
                      fontSize: 23,
                      height: 1.1,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AutomatizeColors.text,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AutomatizeColors.muted,
                      fontSize: 9,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilters(String? perfil) {
    return Wrap(
      spacing: 11,
      runSpacing: 10,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        for (final (modo, rotulo) in const [
          (_Visualizacao.lista, 'Lista'),
          (_Visualizacao.quadro, 'Quadro'),
          (_Visualizacao.calendario, 'Calendário'),
        ])
          ChoiceChip(
            label: Text(rotulo),
            selected: _visualizacao == modo,
            onSelected: (_) => setState(() => _visualizacao = modo),
          ),
        if (perfil == 'CLIENTE')
          FilledButton.icon(
            onPressed: _carregando ? null : _abrirCadastro,
            icon: const Icon(Icons.add),
            label: const Text('Nova demanda'),
          ),
        IconButton(
          tooltip: 'Atualizar demandas',
          onPressed: _carregando ? null : _carregarDemandas,
          icon: const Icon(Icons.refresh),
        ),
        SizedBox(
          width: 350,
          child: TextField(
            controller: _buscaController,
            onChanged: (_) => setState(() {}),
            style: const TextStyle(color: AutomatizeColors.text, fontSize: 12),
            decoration: _fieldDecoration(
              hint: 'Buscar por código, título ou descrição...',
              prefixIcon: const Icon(
                Icons.search_rounded,
                color: AutomatizeColors.muted,
                size: 20,
              ),
              suffixIcon: _buscaController.text.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Limpar busca',
                      onPressed: () {
                        _buscaController.clear();
                        setState(() {});
                      },
                      icon: const Icon(
                        Icons.close_rounded,
                        color: AutomatizeColors.muted,
                        size: 17,
                      ),
                    ),
            ),
          ),
        ),
        SizedBox(
          width: 218,
          child: DropdownButtonFormField<String>(
            key: ValueKey(_filtroStatus),
            initialValue: _filtroStatus,
            isExpanded: true,
            dropdownColor: AutomatizeColors.panelLight,
            style: const TextStyle(color: AutomatizeColors.text, fontSize: 12),
            iconEnabledColor: AutomatizeColors.muted,
            decoration: _fieldDecoration(
              label: 'Filtrar por estado',
              prefixIcon: const Icon(
                Icons.tune_rounded,
                color: AutomatizeColors.muted,
                size: 18,
              ),
            ),
            items: ['Todos os estados', ..._estados].map((estado) {
              return DropdownMenuItem<String>(
                value: estado,
                child: Text(
                  estado,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AutomatizeColors.text,
                    fontSize: 12,
                  ),
                ),
              );
            }).toList(),
            onChanged: (valor) {
              if (valor != null) {
                setState(() => _filtroStatus = valor);
              }
            },
          ),
        ),
        OutlinedButton.icon(
          onPressed:
              _buscaController.text.isEmpty &&
                  _filtroStatus == 'Todos os estados'
              ? null
              : () {
                  _buscaController.clear();
                  setState(() {
                    _filtroStatus = 'Todos os estados';
                  });
                },
          style: OutlinedButton.styleFrom(
            foregroundColor: AutomatizeColors.muted,
            disabledForegroundColor: AutomatizeColors.muted.withValues(
              alpha: 0.45,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
            side: const BorderSide(color: AutomatizeColors.border),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          icon: const Icon(Icons.filter_alt_off_rounded, size: 17),
          label: const Text(
            'Limpar filtros',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }

  InputDecoration _fieldDecoration({
    String? label,
    String? hint,
    Widget? prefixIcon,
    Widget? suffixIcon,
  }) {
    OutlineInputBorder outline(Color color, [double width = 1]) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: color, width: width),
        );
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      labelStyle: const TextStyle(color: AutomatizeColors.muted, fontSize: 11),
      hintStyle: const TextStyle(color: Color(0xFF7189A2), fontSize: 11),
      filled: true,
      fillColor: AutomatizeColors.panel,
      contentPadding: const EdgeInsets.symmetric(horizontal: 13, vertical: 14),
      border: outline(AutomatizeColors.border),
      enabledBorder: outline(AutomatizeColors.border),
      focusedBorder: outline(AutomatizeColors.primary, 1.4),
    );
  }

  Widget _buildDemandasTable(List<DemandaItem> demandas) {
    return Container(
      decoration: BoxDecoration(
        color: AutomatizeColors.panel,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AutomatizeColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.10),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(19, 15, 19, 15),
            decoration: const BoxDecoration(
              color: AutomatizeColors.panelLight,
              border: Border(
                bottom: BorderSide(color: AutomatizeColors.border),
              ),
            ),
            child: Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Visão geral',
                        style: TextStyle(
                          color: AutomatizeColors.text,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: 3),
                      Text(
                        'Lista de demandas e progresso atual',
                        style: TextStyle(
                          color: AutomatizeColors.muted,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AutomatizeColors.background,
                    borderRadius: BorderRadius.circular(9),
                    border: Border.all(color: AutomatizeColors.border),
                  ),
                  child: Text(
                    '${demandas.length} '
                    '${demandas.length == 1 ? 'demanda' : 'demandas'}',
                    style: const TextStyle(
                      color: AutomatizeColors.muted,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: demandas.isEmpty
                ? _emptyState()
                : Scrollbar(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        return SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: SingleChildScrollView(
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                minWidth: constraints.maxWidth,
                              ),
                              child: DataTable(
                                headingRowHeight: 47,
                                dataRowMinHeight: 66,
                                dataRowMaxHeight: 76,
                                columnSpacing: 25,
                                horizontalMargin: 19,
                                dividerThickness: 0.6,
                                headingRowColor: WidgetStateProperty.all(
                                  AutomatizeColors.panelLight,
                                ),
                                dataRowColor:
                                    WidgetStateProperty.resolveWith<Color?>((
                                      states,
                                    ) {
                                      if (states.contains(
                                        WidgetState.hovered,
                                      )) {
                                        return AutomatizeColors.panelLight
                                            .withValues(alpha: 0.5);
                                      }
                                      return null;
                                    }),
                                columns: const [
                                  DataColumn(label: _TableHeader('CÓDIGO')),
                                  DataColumn(label: _TableHeader('DEMANDA')),
                                  DataColumn(label: _TableHeader('ESTADO')),
                                  DataColumn(label: _TableHeader('PROGRESSO')),
                                  DataColumn(label: _TableHeader('DATAS')),
                                  DataColumn(label: _TableHeader('')),
                                ],
                                rows: demandas.map((demanda) {
                                  final cor = _corStatus(demanda.estado);
                                  return DataRow(
                                    cells: [
                                      DataCell(
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 9,
                                            vertical: 6,
                                          ),
                                          decoration: BoxDecoration(
                                            color: AutomatizeColors.background,
                                            borderRadius: BorderRadius.circular(
                                              7,
                                            ),
                                            border: Border.all(
                                              color: AutomatizeColors.border,
                                            ),
                                          ),
                                          child: Text(
                                            demanda.codigo,
                                            style: const TextStyle(
                                              color: AutomatizeColors.cyan,
                                              fontSize: 10,
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                        ),
                                      ),
                                      DataCell(
                                        SizedBox(
                                          width: 270,
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                demanda.titulo,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                  color: AutomatizeColors.text,
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                              const SizedBox(height: 5),
                                              Text(
                                                demanda.descricao.isEmpty
                                                    ? 'Sem descrição adicional'
                                                    : demanda.descricao,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                  color: AutomatizeColors.muted,
                                                  fontSize: 10,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      DataCell(
                                        _StatusChip(
                                          status: _rotuloEstado(demanda.estado),
                                          color: cor,
                                        ),
                                      ),
                                      DataCell(
                                        SizedBox(
                                          width: 160,
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Expanded(
                                                    child: ClipRRect(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            12,
                                                          ),
                                                      child: _barraProgresso(
                                                        demanda,
                                                        cor,
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 10),
                                                  Text(
                                                    _formatarProgresso(demanda),
                                                    style: TextStyle(
                                                      color: cor,
                                                      fontSize: 10,
                                                      fontWeight:
                                                          FontWeight.w800,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 5),
                                              Text(
                                                demanda.progressoInformado
                                                    ? 'Percentual informado pelo sistema'
                                                    : 'Aguardando informação de progresso',
                                                style: const TextStyle(
                                                  color: AutomatizeColors.muted,
                                                  fontSize: 9,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      DataCell(
                                        Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            for (final evento in datasDaDemanda(
                                              demanda,
                                            ))
                                              Text(
                                                '${evento.rotulo}: ${evento.data == null ? '—' : MaterialLocalizations.of(context).formatCompactDate(evento.data!)}',
                                                style: const TextStyle(
                                                  color: AutomatizeColors.muted,
                                                  fontSize: 10,
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                      DataCell(
                                        IconButton.filledTonal(
                                          tooltip: 'Ver detalhes',
                                          onPressed: () =>
                                              _visualizarDemanda(demanda),
                                          style: IconButton.styleFrom(
                                            backgroundColor: AutomatizeColors
                                                .primary
                                                .withValues(alpha: 0.13),
                                            foregroundColor:
                                                AutomatizeColors.cyan,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                          ),
                                          icon: const Icon(
                                            Icons.arrow_outward_rounded,
                                            size: 17,
                                          ),
                                        ),
                                      ),
                                    ],
                                  );
                                }).toList(),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _emptyState() {
    final temFiltro =
        _buscaController.text.trim().isNotEmpty ||
        _filtroStatus != 'Todos os estados';
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 74,
              height: 74,
              decoration: BoxDecoration(
                color: AutomatizeColors.panelLight,
                borderRadius: BorderRadius.circular(22),
              ),
              child: Icon(
                temFiltro ? Icons.search_off_rounded : Icons.inbox_rounded,
                color: AutomatizeColors.cyan,
                size: 34,
              ),
            ),
            const SizedBox(height: 17),
            Text(
              temFiltro
                  ? 'Nenhuma demanda encontrada'
                  : 'Ainda não há demandas',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AutomatizeColors.text,
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 7),
            Text(
              temFiltro
                  ? 'Tente mudar os termos de busca ou o estado selecionado.'
                  : 'Quando houver demandas vinculadas ao seu projeto, elas aparecerão aqui.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AutomatizeColors.muted,
                fontSize: 11,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TableHeader extends StatelessWidget {
  const _TableHeader(this.label);
  final String label;
  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        color: AutomatizeColors.muted,
        fontSize: 9,
        fontWeight: FontWeight.w900,
        letterSpacing: 1.1,
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status, required this.color});
  final String status;
  final Color color;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: color.withValues(alpha: 0.32)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 7),
          Text(
            status,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
