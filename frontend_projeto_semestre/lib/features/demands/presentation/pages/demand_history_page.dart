
import 'package:flutter/material.dart';

import '../../../../core/theme/redesign_colors.dart';
import '../../data/mock/demand_mock_data.dart';
import '../../data/models/pedido_model.dart';
import 'technical_demand_details_page.dart';

class DemandHistoryPage extends StatelessWidget {
  const DemandHistoryPage({super.key});

  DateTime? _dataReferencia(PedidoModel pedido) {
    return pedido.updatedAt ?? pedido.createdAt;
  }

  String _formatarData(DateTime? data) {
    if (data == null) return 'Data não informada';

    final dia = data.day.toString().padLeft(2, '0');
    final mes = data.month.toString().padLeft(2, '0');

    return '$dia/$mes/${data.year}';
  }

  Color _corStatus(String status) {
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

  String _nomeStatus(String status) {
    switch (status.trim().toUpperCase()) {
      case 'EXECUCAO':
        return 'EXECUÇÃO';
      case 'HOMOLOGACAO':
        return 'HOMOLOGAÇÃO';
      case 'CONCLUIDO':
        return 'CONCLUÍDO';
      case 'PLANEJAMENTO':
        return 'PLANEJAMENTO';
      default:
        return status.toUpperCase();
    }
  }

  @override
  Widget build(BuildContext context) {
    final demandas = List<PedidoModel>.from(DemandMockData.demandas);

    demandas.sort((a, b) {
      final dataA = _dataReferencia(a);
      final dataB = _dataReferencia(b);

      if (dataA == null && dataB == null) {
        return a.id.compareTo(b.id);
      }

      if (dataA == null) return 1;
      if (dataB == null) return -1;

      final comparacao = dataB.compareTo(dataA);

      if (comparacao != 0) return comparacao;

      return a.id.compareTo(b.id);
    });

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
                  const Text(
                    'Histórico de demandas',
                    style: TextStyle(
                      color: RedesignColors.textPrimary,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Acompanhe as demandas atualizadas recentemente.',
                    style: TextStyle(
                      color: RedesignColors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 28),
                  Expanded(
                    child: demandas.isEmpty
                        ? const Center(
                            child: Text(
                              'Nenhuma demanda encontrada.',
                              style: TextStyle(
                                color: RedesignColors.textSecondary,
                              ),
                            ),
                          )
                        : ListView.separated(
                            itemCount: demandas.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final pedido = demandas[index];
                              final cor = _corStatus(pedido.status);
                              final data = _dataReferencia(pedido);

                              return Material(
                                color: RedesignColors.card,
                                borderRadius: BorderRadius.circular(14),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(14),
                                  hoverColor:
                                      RedesignColors.purple.withValues(
                                    alpha: 0.08,
                                  ),
                                  onTap: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => TechnicalDemandDetailsPage(
                                          demandId: pedido.id,
                                          pedido: pedido,
                                        ),
                                      ),
                                    );
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(20),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(
                                        color: RedesignColors.border,
                                        width: 0.7,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 44,
                                          height: 44,
                                          decoration: BoxDecoration(
                                            color: cor.withValues(alpha: 0.12),
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          child: Icon(
                                            Icons.history_rounded,
                                            color: cor,
                                            size: 23,
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                pedido.titulo,
                                                maxLines: 1,
                                                overflow:
                                                    TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                  color: RedesignColors
                                                      .textPrimary,
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              const SizedBox(height: 6),
                                              Text(
                                                '${pedido.codigoIdentificador ?? pedido.id} • '
                                                '${pedido.updatedAt != null ? 'Atualizada' : 'Criada'} em ${_formatarData(data)}',
                                                style: const TextStyle(
                                                  color: RedesignColors
                                                      .textSecondary,
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
                                            color: cor.withValues(alpha: 0.12),
                                            borderRadius:
                                                BorderRadius.circular(20),
                                          ),
                                          child: Text(
                                            _nomeStatus(pedido.status),
                                            style: TextStyle(
                                              color: cor,
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        const Icon(
                                          Icons.chevron_right_rounded,
                                          color: RedesignColors.textSecondary,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
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
