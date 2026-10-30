/// Registro de `GET /demandas/{id}/historico`, que no backend é a trilha de
/// auditoria (toda ação de escrita gera uma linha com `acao` + `detalhes`).
class AuditoriaModel {
  final String id;
  final String? usuarioId;
  final String acao;
  final Map<String, dynamic> detalhes;
  final DateTime? createdAt;

  const AuditoriaModel({
    required this.id,
    this.usuarioId,
    required this.acao,
    this.detalhes = const {},
    this.createdAt,
  });

  static const Map<String, String> _rotulos = {
    'CRIACAO_DEMANDA': 'Demanda cadastrada',
    'EDICAO_DEMANDA': 'Demanda editada',
    'EXCLUSAO_DEMANDA': 'Demanda excluída',
    'ALTERACAO_ESTADO': 'Estado alterado',
    'REJEICAO_HOMOLOGACAO': 'Homologação rejeitada',
    'CADASTRO_ETAPA': 'Etapa cadastrada',
    'CONCLUSAO_ETAPA': 'Etapa concluída',
    'ATRIBUICAO_RESPONSAVEL': 'Técnico atribuído',
    'ENVIO_EVIDENCIA': 'Evidência enviada',
  };

  factory AuditoriaModel.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final acao = json['acao'];
    if (id is! String || acao is! String) {
      throw const FormatException(
        'A API retornou um registro de auditoria inválido.',
      );
    }
    final detalhes = json['detalhes'];

    return AuditoriaModel(
      id: id,
      usuarioId: json['usuario_id']?.toString(),
      acao: acao,
      detalhes: detalhes is Map<String, dynamic> ? detalhes : const {},
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? ''),
    );
  }

  /// Ações novas no backend ainda aparecem, só que com o código cru.
  String get rotulo => _rotulos[acao] ?? acao.replaceAll('_', ' ');

  bool get isEvidencia => acao == 'ENVIO_EVIDENCIA';

  // Não existe rota para listar anexos; o registro de auditoria do envio é a
  // única fonte do nome/tamanho das evidências de uma demanda.
  String? get nomeArquivo => detalhes['nome_arquivo']?.toString();

  int? get tamanhoBytes {
    final valor = detalhes['tamanho_bytes'];
    return valor is num ? valor.toInt() : int.tryParse('${valor ?? ''}');
  }
}
