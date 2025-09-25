enum Environment { development, staging, production }

class EnvironmentConfig {
  static Environment _currentEnvironment = Environment.development;

  static Environment get currentEnvironment => _currentEnvironment;

  static void setEnvironment(Environment environment) {
    _currentEnvironment = environment;
  }

  // API URLs pour chaque environnement
  static String get apiBaseUrl {
    switch (_currentEnvironment) {
      case Environment.development:
        return 'http://192.168.1.58:8000/api';
      case Environment.staging:
        return 'https://staging.insam.com/api'; // URL de staging
      case Environment.production:
        return 'http://192.168.1.58:8000/api'; // Backend local pour tests
    }
  }

  // Configuration debug
  static bool get isDebugMode {
    return _currentEnvironment == Environment.development;
  }

  // Configurations spécifiques
  static Map<String, dynamic> get config {
    switch (_currentEnvironment) {
      case Environment.development:
        return {
          'api_timeout': 60000,
          'enable_logging': true,
          'enable_cache': false,
          'app_name': 'INSAM LMS (Dev)',
        };
      case Environment.staging:
        return {
          'api_timeout': 15000,
          'enable_logging': true,
          'enable_cache': true,
          'app_name': 'INSAM LMS (Staging)',
        };
      case Environment.production:
        return {
          'api_timeout': 10000,
          'enable_logging': false,
          'enable_cache': true,
          'app_name': 'INSAM LMS',
        };
    }
  }

  // Utilitaires
  static bool get isDevelopment =>
      _currentEnvironment == Environment.development;
  static bool get isStaging => _currentEnvironment == Environment.staging;
  static bool get isProduction => _currentEnvironment == Environment.production;
}
