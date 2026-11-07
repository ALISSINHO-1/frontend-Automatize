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

    // Preenche o formulário com os dados atuais da demanda.
    _tituloController = TextEditingController(text: widget.pedido.titulo);

    _descricaoController = TextEditingController(text: widget.pedido.descricao);

    // Permite utilizar um serviço simulado nos testes.
    _demandService = widget.demandService ?? DemandService();
  }

  @override
  void dispose() {
    _tituloController.dispose();
    _descricaoController.dispose();

    // Fecha somente o serviço criado por esta tela.
    if (widget.demandService == null) {
      _demandService.dispose();
    }

    super.dispose();
  }

  // Valida os campos antes de enviar alterações à API.
  Future<void> _salvarAlteracoes() async {
    if (_isLoading) return;

    final valido = _formKey.currentState?.validate() ?? false;

    // Impede o envio de dados inválidos.
    if (!valido) return;

    FocusScope.of(context).unfocus();

    // Remove espaços nas extremidades.
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

      // Avisa à tela anterior que a demanda foi alterada.
      Navigator.of(context).pop(true);
    } catch (erro) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Não foi possível salvar as alterações: $erro'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
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
                  // CAMPO: TÍTULO
                  TextFormField(
                    controller: _tituloController,
                    enabled: !_isLoading,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Título da Demanda *',
                      helperText: 'Entre 3 e 255 caracteres.',
                      prefixIcon: Icon(Icons.title),
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      final titulo = value?.trim() ?? '';

                      if (titulo.isEmpty) {
                        return 'O título é obrigatório.';
                      }

                      if (titulo.length < 3) {
                        return 'O título deve ter pelo menos 3 caracteres.';
                      }

                      if (titulo.length > 255) {
                        return 'O título deve ter no máximo 255 caracteres.';
                      }

                      return null;
                    },
                  ),

                  const SizedBox(height: 20),

                  // CAMPO: DESCRIÇÃO
                  TextFormField(
                    controller: _descricaoController,
                    enabled: !_isLoading,
                    keyboardType: TextInputType.multiline,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: 'Descrição *',
                      helperText: 'Mínimo de 5 caracteres.',
                      prefixIcon: Icon(Icons.description),
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      final descricao = value?.trim() ?? '';

                      if (descricao.isEmpty) {
                        return 'A descrição é obrigatória.';
                      }

                      if (descricao.length < 5) {
                        return 'A descrição deve ter pelo menos 5 caracteres.';
                      }

                      return null;
                    },
                  ),

                  const SizedBox(height: 32),

                  // BOTÕES: CANCELAR E SALVAR
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
