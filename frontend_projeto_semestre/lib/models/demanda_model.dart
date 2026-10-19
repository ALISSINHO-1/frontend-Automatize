
class Demanda {
  final int id;
  final String titulo;
  final String descricao;

  Demanda({
    required this.id,
    required this.titulo,
    required this.descricao,
  });

  factory Demanda.fromJson(Map<String, dynamic> json) {
    return Demanda(
      id: json['id'],
      titulo: json['titulo'] ?? 'Sem título',
      descricao: json['descricao'] ?? 'Sem descrição',
    );
  }
}