
import 'package:flutter/material.dart';

import '../../../../app/routes/app_routes.dart';
import '../../../demands/presentation/widgets/demand_status_dashboard.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  // Dados fictícios para demonstração visual.
  // A integração com a API será feita posteriormente.
  static const Map<String, int> _contagensExemplo = {
    'PLANEJAMENTO': 8,
    'EXECUCAO': 5,
    'HOMOLOGACAO': 3,
    'CONCLUIDO': 12,
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'AUTOMATIZE',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 20),
            child: Center(
              child: Text('Painel administrativo'),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final horizontalPadding =
                constraints.maxWidth >= 900 ? 48.0 : 20.0;

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
                      // Cabeçalho do dashboard
                      Text(
                        'Visão geral das demandas',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Acompanhe o andamento das demandas em cada etapa.',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Indicadores visuais
                      const DemandStatusDashboard(
                        contagens: _contagensExemplo,
                      ),

                      const SizedBox(height: 12),

                      // Identificação dos dados simulados
                      Text(
                        'Dados de demonstração. Integração com a API pendente.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),

                      const SizedBox(height: 40),

                      // Acesso à listagem de demandas
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: LayoutBuilder(
                            builder: (context, cardConstraints) {
                              final conteudo = Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Gerenciamento de demandas',
                                    style: theme.textTheme.titleLarge
                                        ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Consulte as demandas cadastradas, '
                                    'acompanhe seus estados e visualize '
                                    'os detalhes de cada solicitação.',
                                    style: theme.textTheme.bodyMedium
                                        ?.copyWith(
                                      color: colors.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              );

                              final botao = FilledButton.icon(
                                onPressed: () {
                                  Navigator.pushNamed(
                                    context,
                                    AppRoutes.demandList,
                                  );
                                },
                                icon: const Icon(Icons.list_alt),
                                label: const Text('Ver demandas'),
                              );

                              if (cardConstraints.maxWidth < 650) {
                                return Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
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
