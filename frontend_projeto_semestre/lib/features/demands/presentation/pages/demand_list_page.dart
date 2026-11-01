
import 'package:flutter/material.dart';

import '../../../../core/theme/redesign_colors.dart';
import '../../../home/presentation/widgets/admin_search_controller.dart';
import '../../data/models/pedido_model.dart';
import '../../data/mock/demand_mock_data.dart';
import '../widgets/demand_status_filter.dart';
import 'demand_details_page.dart';

class DemandListPage extends StatefulWidget {
  const DemandListPage({super.key});

  @override
  State<DemandListPage> createState() => _DemandListPageState();
}

class _DemandListPageState extends State<DemandListPage> {
  late Future<List<PedidoModel>> _futureDemandas;
  String? _estadoSelecionado;

  @override
  void initState() {
    super.initState();

    _futureDemandas = Future.value(DemandMockData.demandas);
    adminSearchController.addListener(_aoAlterarBusca);
  }

  void _aoAlterarBusca() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    adminSearchController.removeListener(_aoAlterarBusca);
    super.dispose();
  }

  void _atualizarDemandas() {
    setState(() {
      _futureDemandas = Future.value(DemandMockData.demandas);
    });
  }

  Color _corEstado(String status) {
    switch (status.trim().toUpperCase()) {
      case 'PLANEJAMENTO':
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
    switch (status.trim().toUpperCase()) {
      case 'PLANEJAMENTO':
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
    switch (status.trim().toUpperCase()) {
      case 'PLANEJAMENTO':
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
                    onStatusChanged: (estado) {
                      setState(() {
                        _estadoSelecionado = estado;
                      });
                    },
                  ),
                  const SizedBox(height: 24),
                  Expanded(
                    child: FutureBuilder<List<PedidoModel>>(
                      future: _futureDemandas,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }

                        if (snapshot.hasError) {
                          return Center(
                            child: Text(
                              'Não foi possível carregar as demandas.\n'
                              '${snapshot.error}',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Color(0xFFFF9C9C),
                              ),
                            ),
                          );
                        }

                        final demandas = snapshot.data ?? [];

                        final filtradasPorEstado =
                            DemandStatusFilter.filtrar(
                          demandas,
                          _estadoSelecionado,
                          (pedido) => pedido.status,
                        );

                        final busca = adminSearchController.query
                            .trim()
                            .toLowerCase();

                        final filtradas =
                            filtradasPorEstado.where((pedido) {
                          if (busca.isEmpty) return true;

                          return pedido.titulo
                                  .toLowerCase()
                                  .contains(busca) ||
                              pedido.descricao
                                  .toLowerCase()
                                  .contains(busca) ||
                              pedido.id
                                  .toLowerCase()
                                  .contains(busca) ||
                              (pedido.codigoIdentificador
                                      ?.toLowerCase()
                                      .contains(busca) ??
                                  false);
                        }).toList();

                        if (filtradas.isEmpty) {
                          return Center(
                            child: Text(
                              demandas.isEmpty
                                  ? 'Nenhuma demanda cadastrada.'
                                  : busca.isNotEmpty
                                      ? 'Nenhuma demanda encontrada para "$busca".'
                                      : 'Nenhuma demanda encontrada para este estado.',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: RedesignColors.textSecondary,
                              ),
                            ),
                          );
                        }

                        return ListView.separated(
                          itemCount: filtradas.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final pedido = filtradas[index];
                            final cor = _corEstado(pedido.status);

                            return _DemandCard(
                              pedido: pedido,
                              cor: cor,
                              icone: _iconeEstado(pedido.status),
                              nomeEstado: _nomeEstado(pedido.status),
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        DemandDetailsPage(
                                      demandId: pedido.id,
                                      pedido: pedido,
                                    ),
                                  ),
                                );
                              },
                            );
                          },
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
                    child: Icon(
                      widget.icone,
                      color: widget.cor,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
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
