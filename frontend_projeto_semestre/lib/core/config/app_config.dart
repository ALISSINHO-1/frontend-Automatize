abstract final class AppConfig {
  static const String appName = 'Automatize';

  static const String environment = String.fromEnvironment(
    'APP_ENV',
    defaultValue: 'development',
  );

  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8000',
  );

  // Ativar somente quando a API tiver email verificado e protecao antiabuso.
  static const bool publicSignupEnabled = bool.fromEnvironment(
    'ENABLE_PUBLIC_SIGNUP',
    defaultValue: false,
  );

  // Sitekey publico. O segredo Turnstile fica SOMENTE no Render.
  static const bool passwordRecoveryEnabled = bool.fromEnvironment(
    'ENABLE_PASSWORD_RECOVERY', defaultValue: false,
  );

  static const String turnstileSiteKey = String.fromEnvironment(
    'TURNSTILE_SITE_KEY',
    defaultValue: '',
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
