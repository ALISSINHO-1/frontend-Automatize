import 'package:flutter/material.dart';

import '../../../admin/data/models/usuario_atual_model.dart';
import '../../data/services/demand_service.dart';

class DemandTasksPage extends StatefulWidget {
  const DemandTasksPage({
    super.key,
    required this.demandaId,
    required this.titulo,
    required this.status,
    required this.usuario,
    this.service,
  });

  final String demandaId;
  final String titulo;
  final String status;
  final UsuarioAtualModel? usuario;
  final DemandService? service;

  @override
  State<DemandTasksPage> createState() => _DemandTasksPageState();
}

class _DemandTasksPageState extends State<DemandTasksPage> {
  late final _api = widget.service ?? DemandService();
  final _descricao = TextEditingController();
  late var _tarefas = _api.listarTarefas(widget.demandaId);
  bool _salvando = false;
  bool _alterou = false;

  bool get _operacional =>
      widget.usuario?.isAdmin == true || widget.usuario?.perfil == 'TECNICO';

  void _recarregar() =>
      setState(() => _tarefas = _api.listarTarefas(widget.demandaId));

  Future<void> _salvar(Future<void> Function() acao) async {
    if (_salvando) return;
    setState(() => _salvando = true);
    try {
      await acao();
      if (!mounted) return;
      _alterou = true;
      _recarregar();
    } catch (erro) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(erro.toString())));
      }
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  @override
  void dispose() {
    if (widget.service == null) _api.dispose();
    _descricao.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final emExecucao = widget.status == 'EXECUCAO';
    final podeCriar =
        _operacional && (emExecucao || widget.status == 'PLANEAMENTO');

    return PopScope(
      canPop: !_salvando,
      child: Scaffold(
        appBar: AppBar(
          leading: BackButton(
            onPressed: _salvando
                ? null
                : () => Navigator.pop(context, _alterou),
          ),
          title: const Text('Tarefas da demanda'),
          actions: [
            IconButton(
              tooltip: 'Atualizar tarefas',
              onPressed: _salvando ? null : _recarregar,
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Text(
                  widget.titulo,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 16),
                if (podeCriar) ...[
                  TextField(
                    controller: _descricao,
                    enabled: !_salvando,
                    maxLength: 255,
                    decoration: const InputDecoration(
                      labelText: 'Descrição da nova tarefa',
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: FilledButton.icon(
                      onPressed: _salvando || _descricao.text.trim().length < 3
                          ? null
                          : () => _salvar(() async {
                              await _api.criarTarefa(
                                widget.demandaId,
                                _descricao.text.trim(),
                              );
                              if (mounted) _descricao.clear();
                            }),
                      icon: const Icon(Icons.add),
                      label: const Text('Adicionar tarefa'),
                    ),
                  ),
                ],
                if (_salvando) const LinearProgressIndicator(),
                const SizedBox(height: 16),
                FutureBuilder(
                  future: _tarefas,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState != ConnectionState.done) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return TextButton(
                        onPressed: _recarregar,
                        child: const Text(
                          'Falha ao carregar tarefas. Tentar novamente',
                        ),
                      );
                    }
                    final tarefas = snapshot.data!;
                    if (tarefas.isEmpty) {
                      return const Text(
                        'Nenhuma tarefa cadastrada nesta demanda.',
                      );
                    }
                    return Column(
                      children: [
                        for (final tarefa in tarefas)
                          Card(
                            child: ListTile(
                              leading: Icon(
                                tarefa.concluida
                                    ? Icons.check_circle_outline
                                    : Icons.radio_button_unchecked,
                              ),
                              title: Text(tarefa.descricao),
                              subtitle: Text(
                                tarefa.concluida ? 'Concluída' : 'Pendente',
                              ),
                              trailing:
                                  _operacional &&
                                      emExecucao &&
                                      !tarefa.concluida
                                  ? TextButton(
                                      onPressed: _salvando
                                          ? null
                                          : () => _salvar(
                                              () => _api.concluirTarefa(
                                                widget.demandaId,
                                                tarefa.id,
                                              ),
                                            ),
                                      child: const Text('Concluir'),
                                    )
                                  : null,
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
