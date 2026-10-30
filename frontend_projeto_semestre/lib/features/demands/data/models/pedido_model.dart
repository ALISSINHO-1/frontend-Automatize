class PedidoModel {
  final String id;
  final String? codigoIdentificador;
  final String titulo;
  final String descricao;
  final String status;
  final double percentualProgresso;
  final bool progressoInformado;
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
    this.progressoInformado = true,
    required this.clienteId,
    this.responsavelId,
    this.createdAt,
    this.updatedAt,
  });

  factory PedidoModel.fromJson(Map<String, dynamic> json) {
    if (!json.containsKey('percentual_progresso')) {
      throw const FormatException('Campo percentual_progresso ausente na API.');
    }

    final percentual = _parsePercentual(json['percentual_progresso']);

    return PedidoModel(
      id: _textoObrigatorio(json, 'id'),
      codigoIdentificador: _textoOpcional(json['codigo_identificador']),
      titulo: _textoObrigatorio(json, 'titulo'),
      descricao: _textoOpcional(json['descricao']) ?? '',
      status: _textoObrigatorio(json, 'status'),
      percentualProgresso: percentual ?? 0.0,
      progressoInformado: percentual != null,
      clienteId: _textoObrigatorio(json, 'cliente_id'),
      responsavelId: _textoOpcional(json['responsavel_id']),
      createdAt: _parseDate(json['created_at'] ?? json['data_criacao']),
      updatedAt: _parseDate(json['updated_at']),
    );
  }

  static double? _parsePercentual(dynamic valor) {
    if (valor == null) {
      return null;
    }

    if (valor is num && valor.isFinite) {
      return valor.toDouble();
    }

    if (valor is String) {
      final percentual = double.tryParse(valor.trim());

      if (percentual != null && percentual.isFinite) {
        return percentual;
      }
    }

    throw const FormatException('Percentual de progresso inválido na API.');
  }

  static String _textoObrigatorio(Map<String, dynamic> json, String campo) {
    final valor = json[campo];

    if (valor is! String || valor.trim().isEmpty) {
      throw FormatException('Campo obrigatório inválido na API: $campo.');
    }

    return valor;
  }

  static String? _textoOpcional(dynamic valor) {
    if (valor == null) {
      return null;
    }

    if (valor is String) {
      return valor;
    }

    throw const FormatException('Campo de texto opcional inválido na API.');
  }

  static DateTime? _parseDate(dynamic valor) {
    if (valor == null) {
      return null;
    }

    if (valor is! String) {
      throw const FormatException('Data recebida em formato inválido.');
    }

    final data = DateTime.tryParse(valor);

    if (data == null) {
      throw const FormatException('Data recebida em formato inválido.');
    }

    return data;
  }
}
