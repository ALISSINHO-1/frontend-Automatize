import 'package:flutter/material.dart';
import '../../data/models/pedido_model.dart';
import '../widgets/demand_history_timeline.dart';
import '../widgets/demand_homologation_card.dart';
import '../../data/models/historico_estado_model.dart';

class DemandDetailsPage extends StatelessWidget {
  const DemandDetailsPage({super.key, required this.demandId, this.pedido});

  final String demandId;
  final PedidoModel? pedido;

  String get nomeResponsavel {
    final responsavelId = pedido?.responsavelId;

    if (responsavelId == null || responsavelId.isEmpty) {
      return 'Não atribuído';
    }

    return 'ID: $responsavelId';
  }

  static String _formatarData(DateTime? data) {
    if (data == null) return 'Não informado';

    final dataLocal = data.toLocal();
    final dia = dataLocal.day.toString().padLeft(2, '0');
    final mes = dataLocal.month.toString().padLeft(2, '0');
    final ano = dataLocal.year;

    return '$dia/$mes/$ano';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F131C),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1200),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 32,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Voltar
                    TextButton.icon(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      icon: const Icon(Icons.arrow_back),
                      label: const Text('Meus Projetos'),
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFFADC6FF),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Identificação
                    const Text(
                      'DEMANDA',
                      style: TextStyle(
                        color: Color(0xFF4CD7F6),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.5,
                      ),
                    ),

                    const SizedBox(height: 10),

                    // Título e status
                    Wrap(
                      spacing: 16,
                      runSpacing: 12,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          pedido?.titulo ?? 'Detalhes indisponíveis',
                          style: const TextStyle(
                            color: Color(0xFFDFE2EE),
                            fontSize: 32,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(
                              0xFF4D8EFF,
                            ).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            pedido?.status ?? 'SEM DADOS',
                            style: const TextStyle(
                              color: Color(0xFFADC6FF),
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 32),

                    // Card principal
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(28),
                      decoration: BoxDecoration(
                        color: const Color(0xFF181C24),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFF424754)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Descrição',
                            style: TextStyle(
                              color: Color(0xFFDFE2EE),
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            pedido?.descricao ?? 'Descrição não disponível.',
                            style: const TextStyle(
                              color: Color(0xFFC2C6D6),
                              fontSize: 15,
                              height: 1.6,
                            ),
                          ),

                          const SizedBox(height: 32),

                          const Divider(color: Color(0xFF424754)),

                          const SizedBox(height: 24),

                          // Responsável e estado
                          Wrap(
                            spacing: 80,
                            runSpacing: 24,
                            children: [
                              _InformationItem(
                                label: 'RESPONSÁVEL',
                                value: nomeResponsavel,
                                icon: Icons.person_outline,
                              ),
                              _InformationItem(
                                label: 'ESTADO',
                                value: pedido?.status ?? 'Não informado',
                                icon: Icons.sync,
                              ),
                            ],
                          ),

                          const SizedBox(height: 36),

                          // Progresso
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Progresso',
                                style: TextStyle(
                                  color: Color(0xFFDFE2EE),
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                '${(pedido?.percentualProgresso ?? 0).toStringAsFixed(0)}%',
                                style: const TextStyle(
                                  color: Color(0xFFADC6FF),
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 12),

                          ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: LinearProgressIndicator(
                              value: ((pedido?.percentualProgresso ?? 0) / 100)
                                  .clamp(0.0, 1.0),
                              minHeight: 10,
                              backgroundColor: Color(0xFF31353E),
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Color(0xFF4D8EFF),
                              ),
                            ),
                          ),

                          const SizedBox(height: 36),

                          const Divider(color: Color(0xFF424754)),

                          const SizedBox(height: 24),

                          // Datas
                          Wrap(
                            spacing: 80,
                            runSpacing: 24,
                            children: [
                              _InformationItem(
                                label: 'CRIADA EM',
                                value: _formatarData(pedido?.createdAt),
                                icon: Icons.calendar_today_outlined,
                              ),
                              _InformationItem(
                                label: 'ATUALIZADA EM',
                                value: _formatarData(pedido?.updatedAt),
                                icon: Icons.update,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    DemandHistoryTimeline(
                      historico: [
                        HistoricoEstadoModel(
                          estadoAnterior: null,
                          novoEstado: 'ABERTO',
                          usuarioResponsavel: 'Lucas Silva',
                          dataHora: DateTime(2026, 10, 15, 9, 30),
                        ),
                        HistoricoEstadoModel(
                          estadoAnterior: 'ABERTO',
                          novoEstado: 'EXECUCAO',
                          usuarioResponsavel: 'Lucas Silva',
                          dataHora: DateTime(2026, 10, 17, 14, 15),
                        ),
                        HistoricoEstadoModel(
                          estadoAnterior: 'EXECUCAO',
                          novoEstado: 'HOMOLOGACAO',
                          usuarioResponsavel: 'Lucas Silva',
                          dataHora: DateTime(2026, 10, 20, 10, 45),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    DemandHomologationCard(
                      status: pedido?.status ?? '',
                      onAprovar: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Demanda aprovada com sucesso! (Demonstração)',
                            ),
                            backgroundColor: Colors.green,
                          ),
                        );
                      },
                      onReprovar: () async {
                        final observacao = await showDialog<String>(
                          context: context,
                          builder: (dialogContext) {
                            String texto = '';

                            return StatefulBuilder(
                              builder: (context, setDialogState) {
                                return AlertDialog(
                                  title: const Text('Solicitar ajustes'),
                                  content: TextField(
                                    maxLines: 4,
                                    maxLength: 500,
                                    onChanged: (valor) {
                                      setDialogState(() {
                                        texto = valor;
                                      });
                                    },
                                    decoration: const InputDecoration(
                                      hintText:
                                          'Descreva os ajustes necessários...',
                                      border: OutlineInputBorder(),
                                    ),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(dialogContext),
                                      child: const Text('Cancelar'),
                                    ),
                                    FilledButton(
                                      onPressed: texto.trim().isEmpty
                                          ? null
                                          : () => Navigator.pop(
                                              dialogContext,
                                              texto.trim(),
                                            ),
                                      child: const Text('Enviar solicitação'),
                                    ),
                                  ],
                                );
                              },
                            );
                          },
                        );

                        if (!context.mounted || observacao == null) return;

                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Ajustes solicitados! (Demonstração)',
                            ),
                            backgroundColor: Colors.orange,
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 24),

                    // Aviso temporário
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1C2028),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.info_outline, color: Color(0xFF4CD7F6)),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'As informações exibidas correspondem aos dados disponíveis '
                              'para esta demanda. Dados adicionais serão apresentados '
                              'quando disponibilizados pela API.',
                              style: TextStyle(
                                color: Color(0xFFC2C6D6),
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
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

class _InformationItem extends StatelessWidget {
  const _InformationItem({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 240,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFF4D8EFF).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: const Color(0xFFADC6FF), size: 21),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: Color(0xFF8C909F),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  value,
                  style: const TextStyle(
                    color: Color(0xFFDFE2EE),
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
