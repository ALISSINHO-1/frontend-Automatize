
import 'package:flutter/material.dart';

import '../../../../app/routes/app_routes.dart';
import '../../../../core/theme/redesign_colors.dart';
import '../../../demands/presentation/widgets/demand_status_dashboard.dart';
import '../../../demands/data/models/pedido_model.dart';
import '../../../demands/data/mock/demand_mock_data.dart';
import '../widgets/admin_sidebar.dart';

class TechnicalDashboardPage extends StatelessWidget {
  const TechnicalDashboardPage({super.key});

  // Dados fictícios para demonstração visual.
  // A integração com a API será feita posteriormente.
  static Map<String, int> calcularContagens(List<PedidoModel> demandas) {
    final contagens = {
      'PLANEJAMENTO': 0,
      'EXECUCAO': 0,
      'HOMOLOGACAO': 0,
      'CONCLUIDO': 0,
    };

    final idsProcessados = <String>{};

    for (final demanda in demandas) {
      if (!idsProcessados.add(demanda.id)) continue;

      final status = demanda.status.trim().toUpperCase();

      if (contagens.containsKey(status)) {
        contagens[status] = contagens[status]! + 1;
      }
    }

    return contagens;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: RedesignColors.background,
      drawer: MediaQuery.sizeOf(context).width < 900
          ? const Drawer(child: AdminSidebar())
          : null,
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
                      // Cabeçalho do dashboard.
                      Text(
                        'Visão geral das demandas',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          color: RedesignColors.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
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

                      // Indicadores de status.
                      DemandStatusDashboard(
                        contagens: calcularContagens(
                          DemandMockData.demandas,
                        ),
                      ),

                      const SizedBox(height: 12),

                      const Text(
                        'Dados de demonstração. Integração com a API pendente.',
                        style: TextStyle(
                          color: RedesignColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),

                      const SizedBox(height: 28),

                      // Card de gerenciamento.
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
                    AppRoutes.demandList,
                  );
                },
              );

              if (compacto) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    conteudo,
                    const SizedBox(height: 20),
                    botao,
                  ],
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

  const _BotaoVerDemandas({
    required this.onPressed,
  });

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
                  colors: [
                    RedesignColors.purple,
                    Color(0xFF4938F5),
                  ],
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
                padding: EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 14,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.list_alt_rounded,
                      size: 18,
                      color: Colors.white,
                    ),
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
