import 'package:flutter/material.dart';
import '../../data/models/pedido_model.dart';
import '../widgets/demand_homologation_card.dart';

class DemandHomologationPage extends StatefulWidget {
  const DemandHomologationPage({super.key, required this.pedido});

  final PedidoModel pedido;

  @override
  State<DemandHomologationPage> createState() => _DemandHomologationPageState();
}

class _DemandHomologationPageState extends State<DemandHomologationPage> {
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
              title: const Text('Solicitar ajustes'),
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
                    border: OutlineInputBorder(),
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
                      ? () =>
                            Navigator.pop(dialogContext, controller.text.trim())
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

  @override
  Widget build(BuildContext context) {
    final pedido = widget.pedido;

    return Scaffold(
      backgroundColor: const Color(0xFF0F131C),
      appBar: AppBar(
        title: const Text('Homologação da entrega'),
        backgroundColor: const Color(0xFF181C24),
        foregroundColor: const Color(0xFFDFE2EE),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 950),
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Text(
                '${pedido.codigoIdentificador ?? pedido.id} • ${pedido.titulo}',
                style: const TextStyle(
                  color: Color(0xFFDFE2EE),
                  fontSize: 25,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Confira a entrega antes de registrar sua avaliação.',
                style: TextStyle(color: Color(0xFFC2C6D6)),
              ),
              const SizedBox(height: 24),
              Card(
                color: const Color(0xFF181C24),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Entrega aguardando sua avaliação',
                        style: TextStyle(
                          color: Color(0xFFDFE2EE),
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        pedido.descricao,
                        style: const TextStyle(color: Color(0xFFC2C6D6)),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Versão da entrega: não informada',
                        style: TextStyle(color: Color(0xFFC2C6D6)),
                      ),
                      const SizedBox(height: 12),
                      CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        value: concordou,
                        onChanged: (valor) {
                          setState(() => concordou = valor ?? false);
                        },
                        title: const Text(
                          'Li e concordo com a entrega',
                          style: TextStyle(color: Color(0xFFDFE2EE)),
                        ),
                        controlAffinity: ListTileControlAffinity.leading,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              DemandHomologationCard(
                status: pedido.status,
                onAprovar: concordou && !processando ? _aprovar : null,
                onReprovar: processando ? null : _solicitarAjustes,
              ),
                            if (dataHoraAceite != null) ...[
                Card(
                  color: const Color(0xFF181C24),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                        children: [
                          Icon(
                            Icons.check_circle,
                            color: Colors.greenAccent,
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Aceite registrado (demonstração)',
                              softWrap: true,
                              style: TextStyle(
                                color: Color(0xFFDFE2EE),
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                        const SizedBox(height: 16),
                        Text(
                          'Responsável: ${responsavelAceite ?? "Não informado"}',
                          style: const TextStyle(
                            color: Color(0xFFC2C6D6),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Data e hora: '
                          '${dataHoraAceite!.day.toString().padLeft(2, '0')}/'
                          '${dataHoraAceite!.month.toString().padLeft(2, '0')}/'
                          '${dataHoraAceite!.year} às '
                          '${dataHoraAceite!.hour.toString().padLeft(2, '0')}:'
                          '${dataHoraAceite!.minute.toString().padLeft(2, '0')}',
                          style: const TextStyle(
                            color: Color(0xFFC2C6D6),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              const SizedBox(height: 16),
              const Text(
                'Modo demonstrativo: nenhuma aprovação ou solicitação '
                'será registrada até a integração com a API.',
                style: TextStyle(color: Color(0xFF8C909F)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
