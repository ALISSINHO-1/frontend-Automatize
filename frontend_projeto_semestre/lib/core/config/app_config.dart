abstract final class AppConfig {
  static const String appName = 'Projeto Semestral';

  static const String environment = String.fromEnvironment(
    'APP_ENV',
    defaultValue: 'development',
  );

  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8000',
  );

  static Uri apiUri([String path = '']) {
    final normalizedBase = apiBaseUrl.endsWith('/')
        ? apiBaseUrl.substring(0, apiBaseUrl.length - 1)
        : apiBaseUrl;
    final normalizedPath = path.isEmpty
        ? ''
        : path.startsWith('/')
            ? path
            : '/$path';

    return Uri.parse('$normalizedBase$normalizedPath');
  }
}
