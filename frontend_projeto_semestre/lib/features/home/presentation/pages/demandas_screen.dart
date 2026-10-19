import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../../../models/demanda_model.dart'; 
import '../../../../shared/widgets/custom_loading.dart';
import '../../../../shared/widgets/custom_error.dart';

class DemandasScreen extends StatefulWidget {
  const DemandasScreen({super.key});

  @override
  State<DemandasScreen> createState() => _DemandasScreenState();
}

class _DemandasScreenState extends State<DemandasScreen> {
  late Future<List<Demanda>> futureDemandas;
  final DemandaService _demandaService = DemandaService();
  
  @override
  void initState() {
    super.initState();
    _carregarDemandas();
  }

  void _carregarDemandas() {
    setState(() {
      futureDemandas = _demandaService.fetchDemandas();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Listagem de Demandas'),
      ),
      body: FutureBuilder<List<Demanda>>(
        future: futureDemandas,
       builder: (context, snapshot) {
          // 1. Estado de Carregamento Padronizado
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const CustomLoading(message: 'A carregar demandas...');
          }

          // 2. Tratamento de Erro Padronizado (Rede ou HTTP)
          if (snapshot.hasError) {
            // O botão de retry chama o _carregarDemandas para tentar de novo
            return CustomError(
              message: snapshot.error.toString(),
              onRetry: _carregarDemandas,
            );
          }

          // Estado Vazio
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Nenhuma demanda encontrada.'));
          }

          // Estado com Dados (Listagem)
          List<Demanda> demandas = snapshot.data!;
          return ListView.builder(
            itemCount: demandas.length,
            itemBuilder: (context, index) {
              final demanda = demandas[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    child: Text(demanda.id.toString()),
                  ),
                  title: Text(demanda.titulo),
                  subtitle: Text(demanda.descricao),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _carregarDemandas,
        tooltip: 'Atualizar',
        child: const Icon(Icons.refresh),
      ),
    );
  }
}

class DemandaService {
 
  final String baseUrl = 'http://10.0.2.2:8000'; 

  Future<List<Demanda>> fetchDemandas() async {
    final response = await http.get(Uri.parse('$baseUrl/demandas'));

    if (response.statusCode == 200) {
      List<dynamic> jsonResponse = json.decode(response.body);
      return jsonResponse.map((data) => Demanda.fromJson(data)).toList();
    } else {
      throw Exception('Falha ao carregar as demandas do servidor');
    }
  }
}