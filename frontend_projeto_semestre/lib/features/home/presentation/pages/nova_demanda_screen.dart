import 'package:flutter/material.dart';
import '../../../demands/data/services/demand_service.dart';

class NovaDemandaScreen extends StatefulWidget {
  const NovaDemandaScreen({super.key, this.demandService});

  // Permite utilizar um serviço simulado nos testes.
  // No aplicativo normal, utiliza o DemandService real.
  final DemandService? demandService;

  @override
  State<NovaDemandaScreen> createState() => _NovaDemandaScreenState();
}

class _NovaDemandaScreenState extends State<NovaDemandaScreen> {
  final _formKey = GlobalKey<FormState>();

  final _tituloController = TextEditingController();
  final _descricaoController = TextEditingController();

  late final DemandService _demandService;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

    // Reutiliza o serviço informado nos testes.
    // Caso contrário, cria o serviço HTTP normal.
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

  // Valida o formulário antes de enviar para a API.
  Future<void> _guardarDemanda() async {
    if (_isLoading) return;

    final formularioValido = _formKey.currentState?.validate() ?? false;

    // Dados inválidos não são enviados à API.
    if (!formularioValido) return;

    FocusScope.of(context).unfocus();

    final titulo = _tituloController.text.trim();
    final descricao = _descricaoController.text.trim();

    setState(() => _isLoading = true);

    try {
      await _demandService.criarDemanda(titulo, descricao);

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

                  // CAMPO: DESCRIÇÃO
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

                  const SizedBox(height: 32),

                  // BOTÃO: SALVAR DEMANDA
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
