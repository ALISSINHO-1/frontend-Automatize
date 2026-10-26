import 'package:flutter/material.dart';

import '../../../../app/routes/app_routes.dart';
import '../../../demands/data/models/pedido_model.dart';
import '../../../demands/data/services/demand_service.dart';
import '../../../demands/presentation/widgets/demand_status_dashboard.dart';
import '../../data/auth_service.dart';

class RoleDashboardPage extends StatefulWidget {
  const RoleDashboardPage({
    super.key,
    required this.session,
    required this.role,
    required this.onLogout,
    this.service,
  });

  final AuthSession session;
  final UserRole role;
  final VoidCallback onLogout;
  final DemandService? service;

  @override
  State<RoleDashboardPage> createState() => _RoleDashboardPageState();
}

class _RoleDashboardPageState extends State<RoleDashboardPage> {
  late final DemandService _service;
  late final bool _ownsService;
  late Future<List<PedidoModel>> _demands;

  String get _roleTitle => switch (widget.role) {
    UserRole.admin => 'Painel administrativo',
    UserRole.tecnico => 'Painel técnico',
    UserRole.cliente => 'Portal do cliente',
  };

  String get _description => switch (widget.role) {
    UserRole.admin =>
      'Visão geral das demandas autorizadas para administração.',
    UserRole.tecnico => 'Demandas atribuídas ao técnico autenticado.',
    UserRole.cliente => 'Acompanhe as demandas vinculadas à sua conta.',
  };

  @override
  void initState() {
    super.initState();
    _ownsService = widget.service == null;
    _service =
        widget.service ??
        DemandService(
          accessToken: widget.session.accessToken,
          onUnauthorized: widget.onLogout,
        );
    _demands = _service.buscarTodasDemandas();
  }

  @override
  void dispose() {
    if (_ownsService) _service.dispose();
    super.dispose();
  }

  void _refresh() => setState(() => _demands = _service.buscarTodasDemandas());

  static Map<String, int> _countByStatus(List<PedidoModel> demands) {
    final counts = {
      'PLANEAMENTO': 0,
      'EXECUCAO': 0,
      'HOMOLOGACAO': 0,
      'CONCLUIDO': 0,
    };
    for (final demand in demands) {
      final status = demand.status.trim().toUpperCase();
      if (counts.containsKey(status)) counts[status] = counts[status]! + 1;
    }
    return counts;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final horizontalPadding = MediaQuery.sizeOf(context).width >= 900
        ? 48.0
        : 20.0;

    return PopScope(
      canPop: false,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'AUTOMATIZE',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          actions: [
            if (MediaQuery.sizeOf(context).width >= 540)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Center(child: Text(_roleTitle)),
              ),
            IconButton(
              tooltip: 'Atualizar demandas',
              onPressed: _refresh,
              icon: const Icon(Icons.refresh),
            ),
            IconButton(
              tooltip: 'Sair',
              onPressed: widget.onLogout,
              icon: const Icon(Icons.logout),
            ),
          ],
        ),
        body: SafeArea(
          child: FutureBuilder<List<PedidoModel>>(
            future: _demands,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return _MessageState(
                  icon: Icons.cloud_off_outlined,
                  message:
                      'Não foi possível carregar as demandas.\n${snapshot.error}',
                  action: _refresh,
                );
              }
              final demands = snapshot.data ?? const <PedidoModel>[];
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
                        Text(
                          _roleTitle,
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _description,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 32),
                        DemandStatusDashboard(
                          titulo: 'Demandas por estado',
                          contagens: _countByStatus(demands),
                        ),
                        const SizedBox(height: 28),
                        if (widget.role == UserRole.cliente &&
                            demands.any(
                              (demand) =>
                                  demand.status.toUpperCase() == 'HOMOLOGACAO',
                            ))
                          const Card(
                            child: ListTile(
                              leading: Icon(Icons.fact_check_outlined),
                              title: Text(
                                'Há demandas aguardando sua homologação',
                              ),
                              subtitle: Text(
                                'Abra os detalhes para aprovar ou solicitar ajustes.',
                              ),
                            ),
                          ),
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                final intro = Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Demandas',
                                      style: theme.textTheme.titleLarge
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      demands.isEmpty
                                          ? 'A API não retornou demandas para esta conta.'
                                          : '${demands.length} demanda(s) retornada(s) pela API.',
                                      style: theme.textTheme.bodyMedium
                                          ?.copyWith(
                                            color: theme
                                                .colorScheme
                                                .onSurfaceVariant,
                                          ),
                                    ),
                                  ],
                                );
                                final button = FilledButton.icon(
                                  onPressed: () => Navigator.pushNamed(
                                    context,
                                    AppRoutes.demandList,
                                  ),
                                  icon: const Icon(Icons.list_alt),
                                  label: const Text('Ver demandas'),
                                );
                                if (constraints.maxWidth < 650) {
                                  return Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      intro,
                                      const SizedBox(height: 20),
                                      button,
                                    ],
                                  );
                                }
                                return Row(
                                  children: [
                                    Expanded(child: intro),
                                    const SizedBox(width: 24),
                                    button,
                                  ],
                                );
                              },
                            ),
                          ),
                        ),
                        if (demands.isEmpty) ...[
                          const SizedBox(height: 24),
                          const _MessageState(
                            icon: Icons.inbox_outlined,
                            message:
                                'Nenhuma demanda disponível para esta conta.',
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _MessageState extends StatelessWidget {
  const _MessageState({required this.icon, required this.message, this.action});

  final IconData icon;
  final String message;
  final VoidCallback? action;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 40,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center),
          if (action != null) ...[
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: action,
              icon: const Icon(Icons.refresh),
              label: const Text('Tentar novamente'),
            ),
          ],
        ],
      ),
    ),
  );
}
