class LocalStorageService {
  // JWT mantido somente durante a sessão atual da página.
  static String? _token;

  // Evita processar repetidamente a mesma expiração.
  static bool _sessaoInvalidada = false;

  // Salva o token após o login bem-sucedido.
  static Future<void> saveToken(String token) async {
    if (token.trim().isEmpty) {
      throw ArgumentError('Não é possível salvar um token vazio.');
    }

    _token = token.trim();
    _sessaoInvalidada = false;
  }

  // Recupera o token da sessão atual.
  static Future<String?> getToken() async {
    return _token;
  }

  // Remove o token no logout.
  static Future<void> removeToken() async {
    _token = null;
    _sessaoInvalidada = true;
  }

  // Invalida a sessão somente se a resposta 401
  // pertencer à sessão que fez a requisição.
  static bool invalidarSeAtual(String? tokenUtilizado) {
    if (_sessaoInvalidada || _token != tokenUtilizado) {
      return false;
    }

    _token = null;
    _sessaoInvalidada = true;

    return true;
  }
}
