
import 'package:flutter/material.dart';

import '../../../../core/theme/redesign_colors.dart';
import '../../data/models/pedido_model.dart';
import '../widgets/demand_homologation_card.dart';

class DemandHomologationPage extends StatefulWidget {
  const DemandHomologationPage({
    super.key,
    required this.pedido,
  });

  final PedidoModel pedido;

  @override
  State<DemandHomologationPage> createState() =>
      _DemandHomologationPageState();
}

class _DemandHomologationPageState
    extends State<DemandHomologationPage> {
  bool concordou = false;
  bool processando = false;

  String? responsavelAceite;
  DateTime? dataHoraAceite;

  Future<void> _aprovar() async {
    if (!concordou || processando) return;

    setState(() => processando = true);

    try {
      if (!mounted) return;

      setState(() {
        responsavelAceite = 'Cliente demonstrativo';
        dataHoraAceite = DateTime.now();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Aprovação demonstrativa. Aguardando integração com a API.',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => processando = false);
      }
    }
  }

  Future<void> _solicitarAjustes() async {
    final controller = TextEditingController();

    final observacao = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, atualizar) {
            final valido = controller.text.trim().length >= 10;

            return AlertDialog(
              backgroundColor: RedesignColors.card,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
                side: const BorderSide(
                  color: RedesignColors.border,
                ),
              ),
              title: const Row(
                children: [
                  Icon(
                    Icons.rate_review_outlined,
                    color: RedesignColors.amber,
                  ),
                  SizedBox(width: 12),
                  Text('Solicitar ajustes'),
                ],
              ),
              content: SizedBox(
                width: 420,
                child: TextField(
                  controller: controller,
                  maxLines: 5,
                  maxLength: 500,
                  onChanged: (_) => atualizar(() {}),
                  decoration: const InputDecoration(
                    labelText: 'Descreva o ajuste necessário',
                    hintText: 'Informe o que precisa ser corrigido...',
                    helperText: 'Mínimo de 10 caracteres',
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancelar'),
                ),
                FilledButton(
                  onPressed: valido
                      ? () => Navigator.pop(
                            dialogContext,
                            controller.text.trim(),
                          )
                      : null,
                  child: const Text('Enviar solicitação'),
                ),
              ],
            );
          },
        );
      },
    );

    controller.dispose();

    if (!mounted || observacao == null) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Solicitação demonstrativa. Nenhuma alteração foi enviada à API.',
        ),
      ),
    );
  }

  String _formatarData(DateTime data) {
    String doisDigitos(int valor) =>
        valor.toString().padLeft(2, '0');

    return '${doisDigitos(data.day)}/'
        '${doisDigitos(data.month)}/'
        '${data.year} às '
        '${doisDigitos(data.hour)}:'
        '${doisDigitos(data.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    final pedido = widget.pedido;

    return Scaffold(
      backgroundColor: RedesignColors.background,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 950),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(28, 28, 28, 48),
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(
                      Icons.arrow_back_rounded,
                      size: 18,
                    ),
                    label: const Text('Voltar aos detalhes'),
                    style: TextButton.styleFrom(
                      foregroundColor:
                          RedesignColors.textSecondary,
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                const Text(
                  'HOMOLOGAÇÃO DA ENTREGA',
                  style: TextStyle(
                    color: RedesignColors.purple,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),

                const SizedBox(height: 12),

                Text(
                  '${pedido.codigoIdentificador ?? pedido.id}'
                  ' • ${pedido.titulo}',
                  style: const TextStyle(
                    color: RedesignColors.textPrimary,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 10),

                const Text(
                  'Confira a entrega antes de registrar sua avaliação.',
                  style: TextStyle(
                    color: RedesignColors.textSecondary,
                    fontSize: 14,
                  ),
                ),

                const SizedBox(height: 28),

                Container(
                  padding: const EdgeInsets.all(26),
                  decoration: BoxDecoration(
                    color: RedesignColors.card,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: RedesignColors.border,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(
                            Icons.inventory_2_outlined,
                            color: RedesignColors.purple,
                            size: 22,
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Entrega aguardando sua avaliação',
                              style: TextStyle(
                                color: RedesignColors.textPrimary,
                                fontSize: 19,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      Text(
                        pedido.descricao,
                        style: const TextStyle(
                          color: RedesignColors.textSecondary,
                          fontSize: 14,
                          height: 1.5,
                        ),
                      ),

                      const SizedBox(height: 18),

                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: RedesignColors.background,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Row(
                          children: [
                            Icon(
                              Icons.layers_outlined,
                              color: RedesignColors.cyan,
                              size: 19,
                            ),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Versão da entrega: não informada',
                                style: TextStyle(
                                  color: RedesignColors.textSecondary,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      const Divider(
                        color: RedesignColors.border,
                      ),

                      Theme(
                        data: Theme.of(context).copyWith(
                          checkboxTheme: CheckboxThemeData(
                            fillColor:
                                WidgetStateProperty.resolveWith(
                              (states) {
                                if (states.contains(
                                  WidgetState.selected,
                                )) {
                                  return RedesignColors.purple;
                                }
                                return Colors.transparent;
                              },
                            ),
                          ),
                        ),
                        child: CheckboxListTile(
                          contentPadding: EdgeInsets.zero,
                          value: concordou,
                          activeColor: RedesignColors.purple,
                          onChanged: processando
                              ? null
                              : (valor) {
                                  setState(() {
                                    concordou = valor ?? false;
                                  });
                                },
                          title: const Text(
                            'Li e concordo com a entrega',
                            style: TextStyle(
                              color: RedesignColors.textPrimary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          subtitle: const Text(
                            'Confirme que revisou as informações apresentadas.',
                            style: TextStyle(
                              color: RedesignColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                          controlAffinity:
                              ListTileControlAffinity.leading,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                DemandHomologationCard(
                  status: pedido.status,
                  onAprovar:
                      concordou && !processando ? _aprovar : null,
                  onReprovar:
                      processando ? null : _solicitarAjustes,
                ),

                if (dataHoraAceite != null) ...[
                  const SizedBox(height: 20),

                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: RedesignColors.card,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: RedesignColors.green.withValues(
                          alpha: 0.45,
                        ),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(
                              Icons.check_circle_rounded,
                              color: RedesignColors.green,
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Aceite registrado (demonstração)',
                                style: TextStyle(
                                  color: RedesignColors.textPrimary,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 18),

                        Text(
                          'Responsável: '
                          '${responsavelAceite ?? "Não informado"}',
                          style: const TextStyle(
                            color: RedesignColors.textSecondary,
                          ),
                        ),

                        const SizedBox(height: 8),

                        Text(
                          'Data e hora: '
                          '${_formatarData(dataHoraAceite!)}',
                          style: const TextStyle(
                            color: RedesignColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 22),

                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: RedesignColors.purple.withValues(
                      alpha: 0.06,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: RedesignColors.border,
                    ),
                  ),
                  child: const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        color: RedesignColors.cyan,
                        size: 19,
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Modo demonstrativo: nenhuma aprovação '
                          'ou solicitação será registrada até a '
                          'integração com a API.',
                          style: TextStyle(
                            color: RedesignColors.textSecondary,
                            fontSize: 12,
                            height: 1.5,
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
    );
  }
}
