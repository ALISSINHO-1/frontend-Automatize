import 'package:flutter/material.dart';

import '../widgets/technical_navigation.dart';
import '../../../../core/theme/redesign_colors.dart';
import '../../../demands/data/services/demand_service.dart';
import '../../../demands/presentation/widgets/demand_status_dashboard.dart';

class TechnicalDashboardPage extends StatefulWidget {
  const TechnicalDashboardPage({super.key});

  @override
  State<TechnicalDashboardPage> createState() => _TechnicalDashboardPageState();
}

class _TechnicalDashboardPageState extends State<TechnicalDashboardPage> {
  final DemandService _service = DemandService();

  late Future<DemandIndicators> _futureIndicadores;

  @override
  void initState() {
    super.initState();
    _futureIndicadores = _service.buscarIndicadores();
  }

  @override
  void dispose() {
    _service.dispose();
    super.dispose();
  }

  void _atualizarIndicadores() {
    setState(() {
      _futureIndicadores = _service.buscarIndicadores();
    });
  }

  Map<String, int> _normalizarContagens(DemandIndicators indicadores) {
    final porStatus = indicadores.porStatus;

    return {
      'PLANEJAMENTO':
          (porStatus['PLANEJAMENTO'] ?? 0) + (porStatus['PLANEAMENTO'] ?? 0),
      'EXECUCAO': porStatus['EXECUCAO'] ?? 0,
      'HOMOLOGACAO': porStatus['HOMOLOGACAO'] ?? 0,
      'CONCLUIDO': porStatus['CONCLUIDO'] ?? 0,
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: RedesignColors.background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isDesktop = constraints.maxWidth >= 900;
            final horizontalPadding = isDesktop ? 48.0 : 20.0;

            return SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                32,
                horizontalPadding,
                48,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1200),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Visão geral das demandas',
                              style: theme.textTheme.headlineMedium?.copyWith(
                                color: RedesignColors.textPrimary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: _atualizarIndicadores,
                            tooltip: 'Atualizar indicadores',
                            icon: const Icon(
                              Icons.refresh_rounded,
                              color: RedesignColors.textSecondary,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      const Text(
                        'Acompanhe o andamento das demandas em cada etapa.',
                        style: TextStyle(
                          color: RedesignColors.textSecondary,
                          fontSize: 15,
                        ),
                      ),

                      const SizedBox(height: 32),

                      FutureBuilder<DemandIndicators>(
                        future: _futureIndicadores,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState !=
                              ConnectionState.done) {
                            return const Padding(
                              padding: EdgeInsets.symmetric(vertical: 60),
                              child: Center(
                                child: CircularProgressIndicator(
                                  color: RedesignColors.purple,
                                ),
                              ),
                            );
                          }

                          if (snapshot.hasError) {
                            return Center(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 32,
                                ),
                                child: Column(
                                  children: [
                                    const Icon(
                                      Icons.cloud_off_outlined,
                                      color: RedesignColors.textSecondary,
                                      size: 42,
                                    ),
                                    const SizedBox(height: 16),
                                    const Text(
                                      'Não foi possível carregar os indicadores.',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: RedesignColors.textPrimary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Verifique sua conexão e tente novamente.',
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        color: RedesignColors.textSecondary,
                                        fontSize: 13,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    OutlinedButton.icon(
                                      onPressed: _atualizarIndicadores,
                                      icon: const Icon(Icons.refresh),
                                      label: const Text('Tentar novamente'),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }

                          final indicadores = snapshot.data;

                          if (indicadores == null) {
                            return const Center(
                              child: Text(
                                'Nenhum indicador disponível.',
                                style: TextStyle(
                                  color: RedesignColors.textSecondary,
                                ),
                              ),
                            );
                          }

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              DemandStatusDashboard(
                                contagens: _normalizarContagens(indicadores),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Total de demandas: ${indicadores.total}',
                                style: const TextStyle(
                                  color: RedesignColors.textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          );
                        },
                      ),

                      const SizedBox(height: 28),

                      const _GerenciamentoDemandasCard(),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _GerenciamentoDemandasCard extends StatefulWidget {
  const _GerenciamentoDemandasCard();

  @override
  State<_GerenciamentoDemandasCard> createState() =>
      _GerenciamentoDemandasCardState();
}

class _GerenciamentoDemandasCardState
    extends State<_GerenciamentoDemandasCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          color: RedesignColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: RedesignColors.purple.withValues(
              alpha: _hovered ? 0.65 : 0.24,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: RedesignColors.purple.withValues(
                alpha: _hovered ? 0.12 : 0.03,
              ),
              blurRadius: _hovered ? 26 : 12,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final compacto = constraints.maxWidth < 650;

              final conteudo = Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: RedesignColors.purple.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.dashboard_customize_outlined,
                      color: RedesignColors.purple,
                      size: 27,
                    ),
                  ),
                  const SizedBox(width: 18),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Gerenciamento de demandas',
                          style: TextStyle(
                            color: RedesignColors.textPrimary,
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Consulte as demandas cadastradas, '
                          'acompanhe seus estados e visualize '
                          'os detalhes de cada solicitação.',
                          style: TextStyle(
                            color: RedesignColors.textSecondary,
                            fontSize: 13,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );

              final botao = _BotaoVerDemandas(
                onPressed: () {
                  Navigator.pushNamed(
                  context,
                  TechnicalRoutes.demandList,
                );
                },
              );

              if (compacto) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [conteudo, const SizedBox(height: 20), botao],
                );
              }

              return Row(
                children: [
                  Expanded(child: conteudo),
                  const SizedBox(width: 24),
                  botao,
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _BotaoVerDemandas extends StatefulWidget {
  final VoidCallback onPressed;

  const _BotaoVerDemandas({required this.onPressed});

  @override
  State<_BotaoVerDemandas> createState() => _BotaoVerDemandasState();
}

class _BotaoVerDemandasState extends State<_BotaoVerDemandas> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedScale(
        scale: _hovered ? 1.035 : 1,
        duration: const Duration(milliseconds: 200),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onPressed,
            borderRadius: BorderRadius.circular(12),
            child: Ink(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [RedesignColors.purple, Color(0xFF4938F5)],
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: RedesignColors.purple.withValues(
                      alpha: _hovered ? 0.35 : 0.15,
                    ),
                    blurRadius: _hovered ? 22 : 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.list_alt_rounded, size: 18, color: Colors.white),
                    SizedBox(width: 10),
                    Text(
                      'Ver demandas',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(width: 12),
                    Icon(
                      Icons.arrow_forward_rounded,
                      size: 18,
                      color: Colors.white,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
