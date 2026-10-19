
class HistoricoEstadoModel {
  final String? estadoAnterior;
  final String novoEstado;
  final String usuarioResponsavel;
  final DateTime dataHora;

  const HistoricoEstadoModel({
    required this.estadoAnterior,
    required this.novoEstado,
    required this.usuarioResponsavel,
    required this.dataHora,
  });

  factory HistoricoEstadoModel.fromJson(Map<String, dynamic> json) {
    return HistoricoEstadoModel(
      estadoAnterior: json['estado_anterior']?.toString(),
      novoEstado: json['novo_estado'].toString(),
      usuarioResponsavel: json['usuario_responsavel'].toString(),
      dataHora: DateTime.parse(json['timestamp'].toString()),
    );
  }
}
