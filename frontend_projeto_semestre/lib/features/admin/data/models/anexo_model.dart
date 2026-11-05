/// Resposta de `POST /demandas/{id}/evidencias`.
class AnexoModel {
  final String id;
  final String pedidoId;
  final String nomeArquivo;
  final String extensao;
  final int tamanhoBytes;
  final DateTime? createdAt;

  const AnexoModel({
    required this.id,
    required this.pedidoId,
    required this.nomeArquivo,
    required this.extensao,
    required this.tamanhoBytes,
    this.createdAt,
  });

  /// Mesmas regras de `app/domain/regras/arquivos.py`; validar antes evita
  /// subir 10 MB só para receber 422.
  static const Set<String> extensoesPermitidas = {
    'pdf',
    'png',
    'jpg',
    'jpeg',
    'docx',
  };
  static const int tamanhoMaximoBytes = 10 * 1024 * 1024;

  factory AnexoModel.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final nome = json['nome_arquivo'];
    if (id is! String || nome is! String) {
      throw const FormatException('A API retornou uma evidência inválida.');
    }
    final tamanho = json['tamanho_bytes'];

    return AnexoModel(
      id: id,
      pedidoId: json['pedido_id']?.toString() ?? '',
      nomeArquivo: nome,
      extensao: json['extensao']?.toString() ?? '',
      tamanhoBytes: tamanho is num ? tamanho.toInt() : 0,
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? ''),
    );
  }
}
