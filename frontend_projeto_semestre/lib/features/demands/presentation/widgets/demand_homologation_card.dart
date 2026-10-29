import 'package:flutter/material.dart';

class DemandHomologationCard extends StatelessWidget {
  const DemandHomologationCard({
    super.key,
    required this.status,
    this.onAprovar,
    this.onReprovar,
  });

  final String status;
  final VoidCallback? onAprovar;
  final VoidCallback? onReprovar;

  @override
  Widget build(BuildContext context) {
    final emHomologacao =
        status.trim().toUpperCase() == 'HOMOLOGACAO' ||
        status.trim().toUpperCase() == 'HOMOLOGAÇÃO';

    if (!emHomologacao) {
      return const SizedBox.shrink();
    }

    return Card(
      color: const Color(0xFF181C24),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Homologação da demanda',
              style: TextStyle(
                color: Color(0xFFDFE2EE),
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Esta demanda está aguardando validação. '
              'Analise as informações antes de aprovar ou reprovar.',
              style: TextStyle(color: Color(0xFFC2C6D6)),
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                FilledButton.icon(
                  onPressed: onAprovar,
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Text('Aprovar'),
                ),
                OutlinedButton.icon(
                  onPressed: onReprovar,
                  icon: const Icon(Icons.cancel_outlined),
                  label: const Text('Reprovar'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
