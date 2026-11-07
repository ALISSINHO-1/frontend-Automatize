bool usuarioPodeEditarDemanda({
  required String perfil,
  required String idUsuario,
  required String clienteId,
  required String status,
}) {
  final perfilAtual = perfil.trim().toUpperCase();
  final estadoAtual = status.trim().toUpperCase();

  // Somente estados reconhecidos e não concluídos são editáveis.
  const estadosEditaveis = {
    'PLANEAMENTO',
    'PLANEJAMENTO',
    'EXECUCAO',
    'EXECUÇÃO',
    'HOMOLOGACAO',
    'HOMOLOGAÇÃO',
  };

  if (!estadosEditaveis.contains(estadoAtual)) return false;

  final usuario = idUsuario.trim();
  if (usuario.isEmpty) return false;

  if (perfilAtual == 'ADMIN') return true;

  return perfilAtual == 'CLIENTE' &&
      clienteId.trim().isNotEmpty &&
      usuario == clienteId.trim();
}
