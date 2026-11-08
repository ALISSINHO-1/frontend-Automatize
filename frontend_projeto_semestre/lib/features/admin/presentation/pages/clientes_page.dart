import 'package:flutter/material.dart';

import '../../../../shared/widgets/main_layout.dart';
import '../../../demands/data/models/pedido_model.dart';
import '../../../demands/data/services/demand_service.dart';
import '../../../demands/presentation/pages/demand_tasks_page.dart';
import '../../data/models/usuario_model.dart';
import '../../data/services/admin_demand_service.dart';
import '../../data/services/usuario_atual_store.dart';

class ClientesPage extends StatefulWidget {
  const ClientesPage({super.key});

  @override
  State<ClientesPage> createState() => _ClientesPageState();
}

class _ClientesPageState extends State<ClientesPage> {
  final _admin = AdminDemandService();
  final _demandas = DemandService();
  late var _clientes = _carregar();

  Future<List<({UsuarioModel cliente, List<PedidoModel> demandas})>>
  _carregar() async {
    final usuario = await UsuarioAtualStore.instance.carregar();
    if (!mounted ||
        usuario == null ||
        (!usuario.isAdmin && usuario.perfil != 'TECNICO')) {
      throw const DemandServiceException('Área disponível para a equipe.');
    }

    final (clientes, demandas) = await (
      usuario.isAdmin
          ? _admin.listarUsuarios(perfil: 'CLIENTE')
          : _admin.listarClientesVinculados(),
      _demandas.buscarDemandas(),
    ).wait;

    final abertasPorCliente = <String, List<PedidoModel>>{};
    for (final demanda in demandas) {
      if (demanda.status != 'CONCLUIDO') {
        (abertasPorCliente[demanda.clienteId] ??= []).add(demanda);
      }
    }
    clientes.sort(
      (a, b) => a.nome.toLowerCase().compareTo(b.nome.toLowerCase()),
    );
    return [
      for (final cliente in clientes)
        (cliente: cliente, demandas: abertasPorCliente[cliente.id] ?? []),
    ];
  }

  void _atualizar() => setState(() => _clientes = _carregar());

  Future<void> _abrirTarefas(PedidoModel demanda) async {
    final usuario = await UsuarioAtualStore.instance.carregar();
    if (!mounted) return;
    final alterou = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => DemandTasksPage(
          demandaId: demanda.id,
          titulo: demanda.titulo,
          status: demanda.status,
          usuario: usuario,
        ),
      ),
    );
    if (mounted && alterou == true) _atualizar();
  }

  @override
  void dispose() {
    _admin.dispose();
    _demandas.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AutomatizeColors.background,
    appBar: AppBar(
      title: const Text('Clientes'),
      actions: [
        IconButton(
          onPressed: _atualizar,
          icon: const Icon(Icons.refresh),
          tooltip: 'Atualizar clientes',
        ),
      ],
    ),
    body: FutureBuilder(
      future: _clientes,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: TextButton(
              onPressed: _atualizar,
              child: const Text('Falha ao carregar clientes. Tentar novamente'),
            ),
          );
        }
        final clientes = snapshot.data!;
        if (clientes.isEmpty) {
          return const Center(child: Text('Nenhum cliente cadastrado.'));
        }

        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                const Padding(
                  padding: EdgeInsets.only(bottom: 16),
                  child: Text(
                    'Abra um cliente para ver as demandas em andamento.',
                  ),
                ),
                for (final grupo in clientes)
                  Card(
                    child: ExpansionTile(
                      key: PageStorageKey(grupo.cliente.id),
                      leading: const Icon(Icons.person_outline),
                      title: Text(grupo.cliente.nome),
                      subtitle: Text(
                        grupo.demandas.length == 1
                            ? '1 demanda aberta'
                            : '${grupo.demandas.length} demandas abertas',
                      ),
                      children: [
                        if (grupo.demandas.isEmpty)
                          const ListTile(
                            title: Text('Nenhuma demanda aberta.'),
                          ),
                        for (final demanda in grupo.demandas)
                          ListTile(
                            title: Text(demanda.titulo),
                            subtitle: Text(switch (demanda.status) {
                              'PLANEAMENTO' => 'Planejamento',
                              'EXECUCAO' => 'Execução',
                              'HOMOLOGACAO' => 'Homologação',
                              final status => status,
                            }),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () => _abrirTarefas(demanda),
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    ),
  );
}
