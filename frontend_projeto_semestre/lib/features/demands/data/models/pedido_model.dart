class PedidoModel {
  final String id;
  final String? codigoIdentificador;
  final String titulo;
  final String descricao;
  final String status;

  // Percentual recebido do backend.
  final double percentualProgresso;

  // Indica se a API realmente informou o progresso.
  final bool progressoInformado;

  final String clienteId;
  final String? responsavelId;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? dataInicio;
  final DateTime? dataPrevisao;
  final DateTime? dataConclusao;

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
    this.dataInicio,
    this.dataPrevisao,
    this.dataConclusao,
  });

  // Converte o JSON da FastAPI para o modelo Flutter.
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

      // O valor zero é usado internamente quando o dado é null.
      // A interface consulta progressoInformado antes de exibi-lo.
      percentualProgresso: percentual ?? 0.0,
      progressoInformado: percentual != null,

      clienteId: _textoObrigatorio(json, 'cliente_id'),
      responsavelId: _textoOpcional(json['responsavel_id']),
      createdAt: _parseDate(json['created_at'] ?? json['data_criacao']),
      updatedAt: _parseDate(json['updated_at']),
      dataInicio: _parseDate(json['data_inicio'])?.toLocal(),
      dataPrevisao: _parseDate(json['data_previsao']),
      dataConclusao: _parseDate(json['data_conclusao'])?.toLocal(),
    );
  }

  // Aceita Decimal como String, número ou null.
  static double? _parsePercentual(Object? valor) {
    if (valor == null) {
      return null;
    }

    double? percentual;

    if (valor is num) {
      percentual = valor.toDouble();
    } else if (valor is String) {
      percentual = double.tryParse(valor.trim());
    }

    if (percentual == null ||
        !percentual.isFinite ||
        percentual < 0 ||
        percentual > 100) {
      throw const FormatException('Percentual de progresso inválido na API.');
    }

    return percentual;
  }

  // Valida campos de texto obrigatórios.
  static String _textoObrigatorio(Map<String, dynamic> json, String campo) {
    final valor = json[campo];

    if (valor is! String || valor.trim().isEmpty) {
      throw FormatException('Campo obrigatório inválido na API: $campo.');
    }

    return valor;
  }

  // Converte campos de texto opcionais.
  static String? _textoOpcional(Object? valor) {
    if (valor == null) {
      return null;
    }

    if (valor is String) {
      return valor;
    }

    throw const FormatException('Campo de texto opcional inválido na API.');
  }

  // Converte datas enviadas pelo backend.
  static DateTime? _parseDate(Object? valor) {
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
