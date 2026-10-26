import '../models/pedido_model.dart';

class DemandMockData {
  static final List<PedidoModel> demandas = [
    PedidoModel(
      id: '2',
      codigoIdentificador: 'AUT-002',
      titulo: 'Configuração de rede',
      descricao: 'Configurar rede e validar conectividade.',
      status: 'HOMOLOGACAO',
      percentualProgresso: 85,
      clienteId: 'Mariana Costa',
      responsavelId: 'Lucas Silva',
      createdAt: DateTime(2026, 10, 15),
      updatedAt: DateTime(2026, 10, 20),
    ),
    PedidoModel(
      id: '7',
      codigoIdentificador: 'AUT-007',
      titulo: 'Validação do sistema',
      descricao: 'Validar as funcionalidades do sistema.',
      status: 'HOMOLOGACAO',
      percentualProgresso: 85,
      clienteId: 'Ana Paula',
      responsavelId: 'Lucas Silva',
      createdAt: DateTime(2026, 10, 18),
      updatedAt: DateTime(2026, 10, 20),
    ),
    PedidoModel(
      id: '1',
      codigoIdentificador: 'AUT-001',
      titulo: 'Manutenção de notebook',
      descricao: 'Realizar manutenção e testes.',
      status: 'EXECUCAO',
      percentualProgresso: 60,
      clienteId: 'João Silva',
      responsavelId: 'Lucas Silva',
      createdAt: DateTime(2026, 10, 16),
      updatedAt: DateTime(2026, 10, 18),
    ),
    PedidoModel(
      id: '3',
      codigoIdentificador: 'AUT-003',
      titulo: 'Instalação de sistema',
      descricao: 'Instalar e configurar o sistema.',
      status: 'CONCLUIDO',
      percentualProgresso: 100,
      clienteId: 'Mariana Costa',
      responsavelId: 'Lucas Silva',
      createdAt: DateTime(2026, 10, 15),
      updatedAt: DateTime(2026, 10, 22),
    ),
  ];
}
