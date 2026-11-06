import 'package:flutter/material.dart';

import '../../../demands/data/models/pedido_model.dart';
import '../../../demands/data/services/demand_service.dart';

class EditarDemandaScreen extends StatefulWidget {
  const EditarDemandaScreen({
    super.key,
    required this.pedido,
    this.demandService,
  });

  final PedidoModel pedido;
  final DemandService? demandService;

  @override
  State<EditarDemandaScreen> createState() => _EditarDemandaScreenState();
}

class _EditarDemandaScreenState extends State<EditarDemandaScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _tituloController;
  late final TextEditingController _descricaoController;
  late final DemandService _demandService;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

    _tituloController = TextEditingController(text: widget.pedido.titulo);

    _descricaoController = TextEditingController(text: widget.pedido.descricao);

    _demandService = widget.demandService ?? DemandService();
  }

  @override
  void dispose() {
    _tituloController.dispose();
    _descricaoController.dispose();

    if (widget.demandService == null) {
      _demandService.dispose();
    }

    super.dispose();
  }

  Future<void> _salvarAlteracoes() async {
    if (_isLoading) return;

    final valido = _formKey.currentState?.validate() ?? false;

    // Impede envio quando o formulário está inválido.
    if (!valido) return;

    FocusScope.of(context).unfocus();

    final titulo = _tituloController.text.trim();
    final descricao = _descricaoController.text.trim();

    setState(() => _isLoading = true);

    try {
      await _demandService.editarDemanda(
        id: widget.pedido.id,
        titulo: titulo,
        descricao: descricao,
      );

      if (!mounted) return;

      // Informa à tela anterior que houve alteração.
      Navigator.of(context).pop(true);
    } catch (erro) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Não foi possível salvar as alterações: $erro'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Editar Demanda')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 650),
            child: Form(
              key: _formKey,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: _tituloController,
                    enabled: !_isLoading,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Título da Demanda *',
                      prefixIcon: Icon(Icons.title),
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'O título é obrigatório.';
                      }

                      return null;
                    },
                  ),

                  const SizedBox(height: 20),

                  TextFormField(
                    controller: _descricaoController,
                    enabled: !_isLoading,
                    keyboardType: TextInputType.multiline,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: 'Descrição',
                      prefixIcon: Icon(Icons.description),
                      border: OutlineInputBorder(),
                    ),
                  ),

                  const SizedBox(height: 32),

                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _isLoading
                              ? null
                              : () => Navigator.of(context).pop(false),
                          child: const Text('Cancelar'),
                        ),
                      ),

                      const SizedBox(width: 12),

                      Expanded(
                        child: FilledButton.icon(
                          onPressed: _isLoading ? null : _salvarAlteracoes,
                          icon: _isLoading
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.save),
                          label: Text(
                            _isLoading ? 'Salvando...' : 'Salvar alterações',
                          ),
                        ),
                      ),
                    ],
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
