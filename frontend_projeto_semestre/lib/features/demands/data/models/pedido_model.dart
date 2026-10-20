
class PedidoModel {
  final String id;
  final String? codigoIdentificador;
  final String titulo;
  final String descricao;
  final String status;
  final double percentualProgresso;
  final String clienteId;
  final String? responsavelId;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? responsavelAceite;
  final DateTime? dataAceite;

  const PedidoModel({
    required this.id,
    this.codigoIdentificador,
    required this.titulo,
    required this.descricao,
    required this.status,
    required this.percentualProgresso,
    required this.clienteId,
    this.responsavelId,
    this.createdAt,
    this.updatedAt,
    this.responsavelAceite,
    this.dataAceite,
  });

  factory PedidoModel.fromJson(Map<String, dynamic> json) {
    return PedidoModel(
      id: json['id'].toString(),
      codigoIdentificador: json['codigo_identificador']?.toString(),
      titulo: json['titulo'] as String,
      descricao: json['descricao'] as String? ?? '',
      status: json['status'] as String,
      percentualProgresso:
          (json['percentual_progresso'] as num?)?.toDouble() ?? 0.0,
      clienteId: json['cliente_id'].toString(),
      responsavelId: json['responsavel_id']?.toString(),
      createdAt: _parseDate(json['created_at'] ?? json['data_criacao']),
      updatedAt: _parseDate(json['updated_at']),
      responsavelAceite: json['responsavel_aceite']?.toString(),
      dataAceite: _parseDate(json['data_aceite']),
    );
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }
}
