
import 'package:flutter/material.dart';

import '../../../../core/theme/redesign_colors.dart';
import '../../data/mock/demand_mock_data.dart';
import '../../data/models/pedido_model.dart';
import 'technical_demand_attachments_page.dart';

class DemandAttachmentsHubPage extends StatelessWidget {
  const DemandAttachmentsHubPage({super.key});

  @override
  Widget build(BuildContext context) {
    final demandas = List<PedidoModel>.from(DemandMockData.demandas);

    demandas.sort((a, b) {
      final codigoA = a.codigoIdentificador ?? a.id;
      final codigoB = b.codigoIdentificador ?? b.id;
      return codigoA.compareTo(codigoB);
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
                    'Central de anexos',
                    style: TextStyle(
                      color: RedesignColors.textPrimary,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Selecione uma demanda para acessar seus anexos.',
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
                              'Nenhuma demanda disponível.',
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

                              return Material(
                                color: RedesignColors.card,
                                borderRadius: BorderRadius.circular(14),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(14),
                                  hoverColor: RedesignColors.purple
                                      .withValues(alpha: 0.08),
                                  onTap: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => TechnicalDemandAttachmentsPage(
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
                                            color: RedesignColors.purple
                                                .withValues(alpha: 0.12),
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          child: const Icon(
                                            Icons.folder_open_rounded,
                                            color: RedesignColors.purple,
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
                                                '${pedido.codigoIdentificador ?? pedido.id} • Acessar anexos',
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
