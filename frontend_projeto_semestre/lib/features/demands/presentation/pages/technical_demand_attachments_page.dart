import 'package:flutter/material.dart';

import '../../../../core/theme/redesign_colors.dart';
import '../../data/models/pedido_model.dart';
import '../widgets/anexos_homologacao_card.dart';

/// Evidências reais da demanda técnica.
/// Reutiliza o fluxo autenticado de upload, listagem e visualização de anexos
/// já utilizado na homologação, sem duplicar lógica ou tornar o Storage público.
class TechnicalDemandAttachmentsPage extends StatelessWidget {
  const TechnicalDemandAttachmentsPage({
    super.key,
    required this.pedido,
    this.fromAttachmentsHub = false,
  });

  final PedidoModel pedido;
  final bool fromAttachmentsHub;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RedesignColors.background,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1100),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 48),
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back_rounded, size: 18),
                    label: Text(
                      fromAttachmentsHub
                          ? 'Voltar à Central de Anexos'
                          : 'Voltar aos detalhes',
                    ),
                    style: TextButton.styleFrom(
                      foregroundColor: RedesignColors.textSecondary,
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                const Text(
                  'ANEXOS DA DEMANDA',
                  style: TextStyle(
                    color: RedesignColors.purple,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  '${pedido.codigoIdentificador ?? pedido.id} • ${pedido.titulo}',
                  style: const TextStyle(
                    color: RedesignColors.textPrimary,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Envie evidências reais para que o cliente possa '
                  'visualizá-las durante a homologação.',
                  style: TextStyle(
                    color: RedesignColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 24),
                AnexosHomologacaoCard(
                  key: ValueKey(pedido.id),
                  demandaId: pedido.id,
                  habilitado: true,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
