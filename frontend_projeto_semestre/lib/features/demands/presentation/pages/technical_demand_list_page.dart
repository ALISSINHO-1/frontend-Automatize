
import 'package:flutter/material.dart';

import '../../../../core/theme/redesign_colors.dart';
import '../../../home/presentation/widgets/admin_search_controller.dart';
import '../../data/models/pedido_model.dart';
import '../../data/services/demand_service.dart';
import '../widgets/demand_status_filter.dart';
import 'technical_demand_details_page.dart';

class TechnicalDemandListPage extends StatefulWidget {
  const TechnicalDemandListPage({super.key});

  @override
  State<TechnicalDemandListPage> createState() => _DemandListPageState();
}

class _DemandListPageState extends State<TechnicalDemandListPage> {
  static const int _tamanhoPagina = 10;

  final DemandService _service = DemandService();

  late Future<List<PedidoModel>> _futureDemandas;

  String? _estadoSelecionado;
  int _paginaAtual = 0;
  String _buscaAtual = '';

  @override
  void initState() {
    super.initState();

    _buscaAtual = adminSearchController.query.trim();
    _futureDemandas = _buscarDemandas();

    adminSearchController.addListener(_aoAlterarBusca);
  }

  DemandFilters get _filtros => DemandFilters(
    busca: _buscaAtual.isEmpty ? null : _buscaAtual,
    status: _estadoSelecionado,
  );

  Future<List<PedidoModel>> _buscarDemandas() {
    return _service.buscarPaginaDemandas(
      offset: _paginaAtual * _tamanhoPagina,
      limit: _tamanhoPagina,
      filtros: _filtros,
    );
  }

  void _aoAlterarBusca() {
    final novaBusca = adminSearchController.query.trim();

    if (novaBusca == _buscaAtual || !mounted) return;

    setState(() {
      _buscaAtual = novaBusca;
      _paginaAtual = 0;
      _futureDemandas = _buscarDemandas();
    });
  }

  void _atualizarDemandas() {
    setState(() {
      _futureDemandas = _buscarDemandas();
    });
  }

  void _alterarStatus(String? status) {
    setState(() {
      _estadoSelecionado = status;
      _paginaAtual = 0;
      _futureDemandas = _buscarDemandas();
    });
  }

  void _proximaPagina() {
    setState(() {
      _paginaAtual++;
      _futureDemandas = _buscarDemandas();
    });
  }

  void _paginaAnterior() {
    if (_paginaAtual == 0) return;

    setState(() {
      _paginaAtual--;
      _futureDemandas = _buscarDemandas();
    });
  }

  @override
  void dispose() {
    adminSearchController.removeListener(_aoAlterarBusca);
    _service.dispose();
    super.dispose();
  }

  Color _corEstado(String status) {
    switch (DemandStatusFilter.normalizarStatus(status)) {
      case 'PLANEAMENTO':
        return RedesignColors.purple;
      case 'EXECUCAO':
        return RedesignColors.cyan;
      case 'HOMOLOGACAO':
        return RedesignColors.amber;
      case 'CONCLUIDO':
        return RedesignColors.green;
      default:
        return RedesignColors.textSecondary;
    }
  }

  IconData _iconeEstado(String status) {
    switch (DemandStatusFilter.normalizarStatus(status)) {
      case 'PLANEAMENTO':
        return Icons.edit_calendar_outlined;
      case 'EXECUCAO':
        return Icons.laptop_mac_outlined;
      case 'HOMOLOGACAO':
        return Icons.fact_check_outlined;
      case 'CONCLUIDO':
        return Icons.check_circle_outline_rounded;
      default:
        return Icons.assignment_outlined;
    }
  }

  String _nomeEstado(String status) {
    switch (DemandStatusFilter.normalizarStatus(status)) {
      case 'PLANEAMENTO':
        return 'PLANEJAMENTO';
      case 'EXECUCAO':
        return 'EXECUÇÃO';
      case 'HOMOLOGACAO':
        return 'HOMOLOGAÇÃO';
      case 'CONCLUIDO':
        return 'CONCLUÍDO';
      default:
        return status.toUpperCase();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RedesignColors.background,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Minhas demandas',
                          style: TextStyle(
                            color: RedesignColors.textPrimary,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: _atualizarDemandas,
                        tooltip: 'Atualizar demandas',
                        icon: const Icon(
                          Icons.refresh_rounded,
                          color: RedesignColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Acompanhe suas demandas.',
                    style: TextStyle(
                      color: RedesignColors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 24),
                  DemandStatusFilter(
                    statusSelecionado: _estadoSelecionado,
                    onStatusChanged: _alterarStatus,
                  ),
                  const SizedBox(height: 24),
                  Expanded(
                    child: FutureBuilder<List<PedidoModel>>(
                      future: _futureDemandas,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState != ConnectionState.done) {
                          return const Center(
                            child: CircularProgressIndicator(
                              color: RedesignColors.purple,
                            ),
                          );
                        }

                        if (snapshot.hasError) {
                          return Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.cloud_off_outlined,
                                  color: RedesignColors.textSecondary,
                                  size: 42,
                                ),
                                const SizedBox(height: 12),
                                const Text(
                                  'Não foi possível carregar as demandas.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: RedesignColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '${snapshot.error}',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: RedesignColors.textSecondary,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                OutlinedButton.icon(
                                  onPressed: _atualizarDemandas,
                                  icon: const Icon(Icons.refresh),
                                  label: const Text('Tentar novamente'),
                                ),
                              ],
                            ),
                          );
                        }

                        final demandas = snapshot.data ?? [];

                        if (demandas.isEmpty) {
                          return Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _paginaAtual == 0
                                      ? 'Nenhuma demanda encontrada.'
                                      : 'Não há demandas nesta página.',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: RedesignColors.textSecondary,
                                  ),
                                ),
                                if (_paginaAtual > 0) ...[
                                  const SizedBox(height: 12),
                                  OutlinedButton(
                                    onPressed: _paginaAnterior,
                                    child: const Text('Página anterior'),
                                  ),
                                ],
                              ],
                            ),
                          );
                        }

                        return Column(
                          children: [
                            Expanded(
                              child: ListView.separated(
                                itemCount: demandas.length,
                                separatorBuilder: (_, _) =>
                                    const SizedBox(height: 10),
                                itemBuilder: (context, index) {
                                  final pedido = demandas[index];
                                  final cor = _corEstado(pedido.status);

                                  return _DemandCard(
                                    pedido: pedido,
                                    cor: cor,
                                    icone: _iconeEstado(pedido.status),
                                    nomeEstado: _nomeEstado(pedido.status),
                                    onTap: () async {
                                      await Navigator.of(context).push(
                                        MaterialPageRoute<void>(
                                          builder: (_) =>
                                              TechnicalDemandDetailsPage(
                                                demandId: pedido.id,
                                                pedido: pedido,
                                              ),
                                        ),
                                      );

                                      if (mounted) {
                                        _atualizarDemandas();
                                      }
                                    },
                                  );
                                },
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                OutlinedButton(
                                  onPressed: _paginaAtual > 0
                                      ? _paginaAnterior
                                      : null,
                                  child: const Text('Anterior'),
                                ),
                                const SizedBox(width: 16),
                                Text(
                                  'Página ${_paginaAtual + 1}',
                                  style: const TextStyle(
                                    color: RedesignColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                OutlinedButton(
                                  onPressed: demandas.length == _tamanhoPagina
                                      ? _proximaPagina
                                      : null,
                                  child: const Text('Próxima'),
                                ),
                              ],
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DemandCard extends StatefulWidget {
  const _DemandCard({
    required this.pedido,
    required this.cor,
    required this.icone,
    required this.nomeEstado,
    required this.onTap,
  });

  final PedidoModel pedido;
  final Color cor;
  final IconData icone;
  final String nomeEstado;
  final VoidCallback onTap;

  @override
  State<_DemandCard> createState() => _DemandCardState();
}

class _DemandCardState extends State<_DemandCard> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          color: RedesignColors.card,
          borderRadius: BorderRadius.circular(13),
          border: Border.all(
            color: _hover
                ? widget.cor.withValues(alpha: 0.65)
                : RedesignColors.border.withValues(alpha: 0.7),
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(13),
            child: Padding(
              padding: const EdgeInsets.all(15),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: widget.cor.withValues(alpha: 0.13),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(widget.icone, color: widget.cor, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (widget.pedido.codigoIdentificador != null &&
                            widget.pedido.codigoIdentificador!.isNotEmpty) ...[
                          Text(
                            widget.pedido.codigoIdentificador!,
                            style: const TextStyle(
                              color: RedesignColors.purple,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                        ],
                        Text(
                          widget.pedido.titulo,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: RedesignColors.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          widget.pedido.descricao,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: RedesignColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Cliente: ${widget.pedido.clienteId}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: RedesignColors.textSecondary,
                            fontSize: 11,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            const Text(
                              'Progresso',
                              style: TextStyle(
                                color: RedesignColors.textSecondary,
                                fontSize: 11,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              '${widget.pedido.percentualProgresso.toStringAsFixed(0)}%',
                              style: const TextStyle(
                                color: RedesignColors.textPrimary,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 5),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: widget.pedido.percentualProgresso / 100,
                            minHeight: 5,
                            backgroundColor: RedesignColors.border,
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              RedesignColors.purple,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: widget.cor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      widget.nomeEstado,
                      style: TextStyle(
                        color: widget.cor,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: RedesignColors.textSecondary,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
