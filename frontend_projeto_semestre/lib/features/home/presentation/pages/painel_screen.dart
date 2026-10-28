
import 'package:flutter/material.dart';

import '../../../../app/routes/app_routes.dart';
import '../../../../core/storage/local_storage_service.dart';
import '../../../../shared/widgets/main_layout.dart';
import 'demanda_store.dart';
import 'demandas_screen.dart';

class PainelScreen extends StatefulWidget {
  const PainelScreen({super.key});

  @override
  State<PainelScreen> createState() => _PainelScreenState();
}

class _PainelScreenState extends State<PainelScreen> {
  final DemandaStore _store = DemandaStore.instance;

  @override
  void initState() {
    super.initState();

    _store.addListener(_atualizarPainel);
    _store.carregarDemandas();
  }

  void _atualizarPainel() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _store.removeListener(_atualizarPainel);
    super.dispose();
  }

  String _normalizarStatus(String estado) {
    return estado
        .trim()
        .toUpperCase()
        .replaceAll('Ç', 'C')
        .replaceAll('Ã', 'A')
        .replaceAll('Í', 'I');
  }

  Color _corStatus(String estado) {
    switch (_normalizarStatus(estado)) {
      case 'PLANEJAMENTO':
        return const Color(0xFF6366F1);

      case 'HOMOLOGACAO':
        return const Color(0xFF8B5CF6);

      case 'CONCLUIDO':
        return const Color(0xFF059669);

      default:
        return Colors.blueGrey;
    }
  }

  void _navegarParaDemandas() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => const DemandasScreen(),
      ),
    );
  }

  Future<void> _sair() async {
    await LocalStorageService.removeToken();

    _store.limpar();

    if (!mounted) return;

    Navigator.of(
      context,
      rootNavigator: true,
    ).pushNamedAndRemoveUntil(
      AppRoutes.login,
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final demandas = _store.demandas;

    final total = demandas.length;

    final planejamento = demandas
        .where(
          (d) => _normalizarStatus(d.estado) == 'PLANEJAMENTO',
        )
        .length;

    final homologacao = demandas
        .where(
          (d) => _normalizarStatus(d.estado) == 'HOMOLOGACAO',
        )
        .length;

    final concluidas = demandas
        .where(
          (d) => _normalizarStatus(d.estado) == 'CONCLUIDO',
        )
        .length;

    final recentes = demandas.take(5).toList();

    return MainLayout(
      selectedIndex: 0,
      onDestinationSelected: (index) {
        if (index == 1) {
          _navegarParaDemandas();
        }
      },
      onLogout: _sair,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        body: SafeArea(
          child: _store.carregando
              ? const Center(
                  child: CircularProgressIndicator(),
                )
              : _store.erro != null
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _store.erro!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Color(0xFFB91C1C),
                              ),
                            ),
                            const SizedBox(height: 16),
                            FilledButton.icon(
                              onPressed: _store.carregarDemandas,
                              icon: const Icon(Icons.refresh),
                              label: const Text('Tentar novamente'),
                            ),
                          ],
                        ),
                      ),
                    )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(28),
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Painel',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Acompanhe o resumo das suas demandas.',
                            style: TextStyle(
                              color: Color(0xFF64748B),
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 28),
                          const Text(
                            'Visão geral',
                            style: TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Wrap(
                            spacing: 16,
                            runSpacing: 16,
                            children: [
                              _IndicadorCard(
                                titulo: 'Total de demandas',
                                valor: '$total',
                                descricao: 'Demandas cadastradas',
                                icone: Icons.assignment_outlined,
                                cor: const Color(0xFF1677F2),
                              ),
                              _IndicadorCard(
                                titulo: 'Planejamento',
                                valor: '$planejamento',
                                descricao: 'Em planejamento',
                                icone: Icons.calendar_month_outlined,
                                cor: const Color(0xFF6366F1),
                              ),
                              _IndicadorCard(
                                titulo: 'Homologação',
                                valor: '$homologacao',
                                descricao: 'Em homologação',
                                icone: Icons.fact_check_outlined,
                                cor: const Color(0xFF8B5CF6),
                              ),
                              _IndicadorCard(
                                titulo: 'Concluídas',
                                valor: '$concluidas',
                                descricao: 'Finalizadas',
                                icone: Icons.check_circle_outline,
                                cor: const Color(0xFF059669),
                              ),
                            ],
                          ),
                          const SizedBox(height: 32),
                          const Text(
                            'Demandas recentes',
                            style: TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Card(
                            elevation: 0,
                            color: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(12),
                              side: const BorderSide(
                                color: Color(0xFFE2E8F0),
                              ),
                            ),
                            child: recentes.isEmpty
                                ? const Padding(
                                    padding: EdgeInsets.all(32),
                                    child: Center(
                                      child: Column(
                                        children: [
                                          Icon(
                                            Icons.assignment_outlined,
                                            size: 42,
                                            color: Color(0xFF94A3B8),
                                          ),
                                          SizedBox(height: 12),
                                          Text(
                                            'Nenhuma demanda cadastrada.',
                                            style: TextStyle(
                                              color: Color(0xFF64748B),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  )
                                : ListView.separated(
                                    shrinkWrap: true,
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    itemCount: recentes.length,
                                    separatorBuilder: (_, _) =>
                                        const Divider(
                                      height: 1,
                                      color: Color(0xFFE2E8F0),
                                    ),
                                    itemBuilder: (context, index) {
                                      final demanda = recentes[index];
                                      final cor = _corStatus(
                                        demanda.estado,
                                      );

                                      return Padding(
                                        padding:
                                            const EdgeInsets.all(16),
                                        child: Row(
                                          children: [
                                            Container(
                                              width: 42,
                                              height: 42,
                                              decoration: BoxDecoration(
                                                color: cor.withValues(
                                                  alpha: 0.12,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(
                                                  10,
                                                ),
                                              ),
                                              child: Icon(
                                                Icons.assignment_outlined,
                                                color: cor,
                                              ),
                                            ),
                                            const SizedBox(width: 14),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    demanda.titulo,
                                                    style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color:
                                                          Color(0xFF0F172A),
                                                    ),
                                                  ),
                                                  const SizedBox(height: 5),
                                                  Text(
                                                    demanda.codigo,
                                                    style: const TextStyle(
                                                      fontSize: 12,
                                                      color:
                                                          Color(0xFF64748B),
                                                    ),
                                                  ),
                                                  const SizedBox(height: 10),
                                                  Wrap(
                                                    spacing: 12,
                                                    runSpacing: 8,
                                                    crossAxisAlignment:
                                                        WrapCrossAlignment
                                                            .center,
                                                    children: [
                                                      Container(
                                                        padding:
                                                            const EdgeInsets
                                                                .symmetric(
                                                          horizontal: 9,
                                                          vertical: 5,
                                                        ),
                                                        decoration:
                                                            BoxDecoration(
                                                          color: cor
                                                              .withValues(
                                                            alpha: 0.12,
                                                          ),
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(
                                                            6,
                                                          ),
                                                        ),
                                                        child: Text(
                                                          demanda.estado,
                                                          style: TextStyle(
                                                            color: cor,
                                                            fontSize: 12,
                                                            fontWeight:
                                                                FontWeight
                                                                    .w600,
                                                          ),
                                                        ),
                                                      ),
                                                      Text(
                                                        'Progresso: '
                                                        '${demanda.progresso}%',
                                                        style:
                                                            const TextStyle(
                                                          color:
                                                              Color(0xFF64748B),
                                                          fontSize: 12,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 10),
                                                  LinearProgressIndicator(
                                                    value:
                                                        (demanda.progresso /
                                                                100)
                                                            .clamp(0.0, 1.0),
                                                    minHeight: 6,
                                                    backgroundColor:
                                                        const Color(
                                                      0xFFE2E8F0,
                                                    ),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                      8,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'As informações exibidas são consultadas na API.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
        ),
      ),
    );
  }
}

class _IndicadorCard extends StatelessWidget {
  final String titulo;
  final String valor;
  final String descricao;
  final IconData icone;
  final Color cor;

  const _IndicadorCard({
    required this.titulo,
    required this.valor,
    required this.descricao,
    required this.icone,
    required this.cor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 225,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  titulo,
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 13,
                  ),
                ),
              ),
              Icon(
                icone,
                color: cor,
                size: 23,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            valor,
            style: const TextStyle(
              color: Color(0xFF0F172A),
              fontSize: 30,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            descricao,
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
