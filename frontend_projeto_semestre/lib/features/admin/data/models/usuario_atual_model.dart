/// Resposta de `GET /auth/me`. O JWT só traz o id (`sub`); o perfil vem daqui.
class UsuarioAtualModel {
  final String id;
  final String nome;
  final String email;
  final String perfil;

  const UsuarioAtualModel({
    required this.id,
    required this.nome,
    required this.email,
    required this.perfil,
  });

  factory UsuarioAtualModel.fromJson(Map<String, dynamic> json) {
    final id = json['id'], nome = json['nome'], perfil = json['perfil'];
    if (id is! String || nome is! String || perfil is! String) {
      throw const FormatException(
        'A API não retornou id, nome e perfil válidos.',
      );
    }
    return UsuarioAtualModel(
      id: id,
      nome: nome,
      email: json['email']?.toString() ?? '',
      perfil: perfil.trim().toUpperCase(),
    );
  }

  bool get isAdmin => perfil == 'ADMIN';

  String get iniciais {
    final partes = nome.trim().split(RegExp(r'\s+'));
    final letras = partes.length > 1
        ? '${partes.first[0]}${partes.last[0]}'
        : nome.trim().padRight(2).substring(0, 2);
    return letras.toUpperCase();
  }
}
