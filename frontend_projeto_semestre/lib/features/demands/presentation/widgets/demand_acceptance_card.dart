import 'package:flutter/material.dart';

class DemandAcceptanceCard extends StatelessWidget {
  const DemandAcceptanceCard({
    super.key,
    required this.responsavel,
    required this.dataAceite,
  });

  final String responsavel;
  final DateTime dataAceite;

  @override
  Widget build(BuildContext context) {
    final dataLocal = dataAceite.toLocal();

    final dataFormatada =
        '${dataLocal.day.toString().padLeft(2, '0')}/'
        '${dataLocal.month.toString().padLeft(2, '0')}/'
        '${dataLocal.year} às '
        '${dataLocal.hour.toString().padLeft(2, '0')}:'
        '${dataLocal.minute.toString().padLeft(2, '0')}';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1C2028),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF4CD7F6),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.verified_outlined,
                color: Color(0xFF4CD7F6),
              ),
              SizedBox(width: 12),
              Text(
                'Aceite da demanda',
                style: TextStyle(
                  color: Color(0xFFDFE2EE),
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Responsável: $responsavel',
            style: const TextStyle(
              color: Color(0xFFC2C6D6),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Data do aceite: $dataFormatada',
            style: const TextStyle(
              color: Color(0xFFC2C6D6),
            ),
          ),
        ],
      ),
    );
  }
}