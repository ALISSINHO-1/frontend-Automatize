class HistoricoEstadoModel {
  final String? estadoAnterior;
  final String novoEstado;
  final String usuarioResponsavel;
  final DateTime? dataHora;
  final String? acao;
  final Map<String, dynamic>? detalhes;

  const HistoricoEstadoModel({
    required this.estadoAnterior,
    required this.novoEstado,
    required this.usuarioResponsavel,
    required this.dataHora,
    this.acao,
    this.detalhes,
  });

  factory HistoricoEstadoModel.fromJson(Map<String, dynamic> json) {
    return HistoricoEstadoModel(
      estadoAnterior: json['estado_anterior']?.toString(),
      novoEstado:
          json['novo_estado']?.toString() ??
          json['acao']?.toString() ??
          'Ação registrada',
      usuarioResponsavel:
          json['usuario_responsavel']?.toString() ??
          (json['usuario_id'] == null
              ? 'Usuário não informado'
              : 'ID: ${json['usuario_id']}'),
      dataHora: DateTime.tryParse(
        (json['timestamp'] ?? json['created_at'])?.toString() ?? '',
      ),
      acao: json['acao']?.toString(),
      detalhes: json['detalhes'] is Map<String, dynamic>
          ? json['detalhes'] as Map<String, dynamic>
          : null,
    );
  }
}
