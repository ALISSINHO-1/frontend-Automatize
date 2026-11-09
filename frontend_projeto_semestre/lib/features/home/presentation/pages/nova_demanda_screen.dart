import 'package:flutter/material.dart';

import '../../../demands/data/services/demand_service.dart';

class NovaDemandaScreen extends StatefulWidget {
  const NovaDemandaScreen({super.key});

  @override
  State<NovaDemandaScreen> createState() => _NovaDemandaScreenState();
}

class _NovaDemandaScreenState extends State<NovaDemandaScreen> {
  final _formKey = GlobalKey<FormState>();

  final _tituloController = TextEditingController();
  final _descricaoController = TextEditingController();

  final DemandService _demandService = DemandService();

  bool _isLoading = false;
  DateTime? _previsao;

  @override
  void dispose() {
    _tituloController.dispose();
    _descricaoController.dispose();
    _demandService.dispose();
    super.dispose();
  }

  Future<void> _guardarDemanda() async {
    if (_isLoading) return;

    final formularioValido = _formKey.currentState?.validate() ?? false;

    if (!formularioValido) return;

    FocusScope.of(context).unfocus();

    final titulo = _tituloController.text.trim();
    final descricao = _descricaoController.text.trim();

    setState(() => _isLoading = true);

    try {
      await _demandService.criarDemanda(
        titulo,
        descricao,
        dataPrevisao: _previsao,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Demanda criada com sucesso!'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.of(context).pop(true);
    } catch (erro) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Não foi possível cadastrar a demanda: $erro'),
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
      appBar: AppBar(title: const Text('Nova Demanda')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 650),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: _tituloController,
                    enabled: !_isLoading,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Título da Demanda *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.title),
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
                      border: OutlineInputBorder(),
                      prefixIcon: Padding(
                        padding: EdgeInsets.only(bottom: 60),
                        child: Icon(Icons.description),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: _isLoading
                        ? null
                        : () async {
                            final data = await showDatePicker(
                              context: context,
                              initialDate: _previsao ?? DateTime.now(),
                              firstDate: DateTime(1900),
                              lastDate: DateTime(2200, 12, 31),
                            );
                            if (mounted && data != null)
                              setState(() => _previsao = data);
                          },
                    icon: const Icon(Icons.event_outlined),
                    label: Text(
                      _previsao == null
                          ? 'Definir previsão de entrega (opcional)'
                          : 'Previsão: ${MaterialLocalizations.of(context).formatCompactDate(_previsao!)}',
                    ),
                  ),
                  if (_previsao != null)
                    TextButton(
                      onPressed: _isLoading
                          ? null
                          : () => setState(() => _previsao = null),
                      child: const Text('Remover previsão'),
                    ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 50,
                    child: FilledButton.icon(
                      onPressed: _isLoading ? null : _guardarDemanda,
                      icon: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.save),
                      label: Text(
                        _isLoading ? 'Salvando...' : 'Salvar Demanda',
                        style: const TextStyle(fontSize: 16),
                      ),
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
