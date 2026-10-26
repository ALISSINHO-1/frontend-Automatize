class PedidoModel {
  final String id;
  final String? codigoIdentificador;
  final String titulo;
  final String descricao;
  final String status;
  final double? percentualProgresso;
  final String clienteId;
  final String? responsavelId;
  final DateTime? createdAt;
  final DateTime? updatedAt;

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
  });

  factory PedidoModel.fromJson(Map<String, dynamic> json) {
    if (json['id'] is! String ||
        json['titulo'] is! String ||
        json['status'] is! String ||
        json['cliente_id'] is! String) {
      throw const FormatException(
        'A API retornou campos obrigatórios inválidos para a demanda.',
      );
    }
    return PedidoModel(
      id: json['id'].toString(),
      codigoIdentificador: json['codigo_identificador']?.toString(),
      titulo: json['titulo'] as String,
      descricao: json['descricao'] as String? ?? '',
      status: json['status'] as String,
      percentualProgresso: _parseProgress(json['percentual_progresso']),
      clienteId: json['cliente_id'].toString(),
      responsavelId: json['responsavel_id']?.toString(),
      createdAt: _parseDate(json['created_at'] ?? json['data_criacao']),
      updatedAt: _parseDate(json['updated_at']),
    );
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }

  static double? _parseProgress(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }
}
