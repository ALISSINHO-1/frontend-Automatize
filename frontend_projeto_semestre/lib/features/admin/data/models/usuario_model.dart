/// Usuário como o ADMIN vê em `GET /usuarios` (nunca traz a senha).
class UsuarioModel {
  final String id;
  final String nome;
  final String email;
  final String perfil;
  final bool ativo;
  final DateTime? createdAt;

  const UsuarioModel({
    required this.id,
    required this.nome,
    required this.perfil,
    this.email = '',
    this.ativo = true,
    this.createdAt,
  });

  static const perfis = ['ADMIN', 'TECNICO', 'CLIENTE'];

  factory UsuarioModel.fromJson(Map<String, dynamic> json) {
    final id = json['id'], nome = json['nome'], perfil = json['perfil'];
    if (id is! String || nome is! String || perfil is! String) {
      throw const FormatException('A API retornou um usuário inválido.');
    }
    return UsuarioModel(
      id: id,
      nome: nome,
      email: json['email']?.toString() ?? '',
      perfil: perfil.trim().toUpperCase(),
      // `ativo` é anulável no banco; só `true` conta como ativo (mesma regra do backend).
      ativo: json['ativo'] == true,
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? ''),
    );
  }

  static String rotuloPerfil(String perfil) => switch (perfil) {
    'ADMIN' => 'Administrador',
    'TECNICO' => 'Técnico',
    'CLIENTE' => 'Cliente',
    final outro => outro,
  };
}
