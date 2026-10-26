import 'package:flutter/material.dart';
import '../../data/models/pedido_model.dart';
import '../widgets/demand_status_filter.dart';
import '../../data/mock/demand_mock_data.dart';
import 'demand_details_page.dart';

class DemandListPage extends StatefulWidget {
  const DemandListPage({super.key});

  @override
  State<DemandListPage> createState() => _DemandListPageState();
}

class _DemandListPageState extends State<DemandListPage> {
  late Future<List<PedidoModel>> _futureDemandas;
  String? _estadoSelecionado;

  @override
  void initState() {
    super.initState();
    _futureDemandas = Future.value(DemandMockData.demandas);
  }

  void _atualizarDemandas() {
    setState(() {
      _futureDemandas = Future.value(DemandMockData.demandas);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F131C),
      appBar: AppBar(
        title: const Text('Minhas demandas'),
        backgroundColor: const Color(0xFF181C24),
        foregroundColor: const Color(0xFFDFE2EE),
        actions: [
          IconButton(
            onPressed: _atualizarDemandas,
            tooltip: 'Atualizar demandas',
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Acompanhe suas demandas',
                  style: TextStyle(
                    color: Color(0xFFDFE2EE),
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Filtre os projetos por etapa de desenvolvimento.',
                  style: TextStyle(color: Color(0xFFC2C6D6)),
                ),
                const SizedBox(height: 24),

                DemandStatusFilter(
                  statusSelecionado: _estadoSelecionado,
                  onStatusChanged: (estado) {
                    setState(() {
                      _estadoSelecionado = estado;
                    });
                  },
                ),

                const SizedBox(height: 24),

                Expanded(
                  child: FutureBuilder<List<PedidoModel>>(
                    future: _futureDemandas,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (snapshot.hasError) {
                        return Center(
                          child: Text(
                            'Não foi possível carregar as demandas.\n'
                            '${snapshot.error}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Color(0xFFFF9C9C)),
                          ),
                        );
                      }

                      final demandas = snapshot.data ?? [];

                      final filtradas = DemandStatusFilter.filtrar(
                        demandas,
                        _estadoSelecionado,
                        (pedido) => pedido.status,
                      );

                      if (filtradas.isEmpty) {
                        return Center(
                          child: Text(
                            demandas.isEmpty
                                ? 'Nenhuma demanda cadastrada.'
                                : 'Nenhuma demanda encontrada para este estado.',
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Color(0xFFC2C6D6)),
                          ),
                        );
                      }

                      return ListView.separated(
                        itemCount: filtradas.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final pedido = filtradas[index];

                          return Card(
                            color: const Color(0xFF181C24),
                            child: ListTile(
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => DemandDetailsPage(
                                      demandId: pedido.id,
                                      pedido: pedido,
                                    ),
                                  ),
                                );
                              },
                              contentPadding: const EdgeInsets.all(16),
                              title: Text(
                                pedido.titulo,
                                style: const TextStyle(
                                  color: Color(0xFFDFE2EE),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  '${pedido.descricao}\n'
                                  'Estado: ${pedido.status}',
                                  style: const TextStyle(
                                    color: Color(0xFFC2C6D6),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
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
