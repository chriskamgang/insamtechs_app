import 'backend_config.dart';

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
        // Utilise le fichier de configuration pour l'IP du backend
        // Pour changer l'IP, modifiez le fichier backend_config.dart
        return getBackendUrl();
      case Environment.staging:
        return 'https://staging.insam.com/api'; // URL de staging
      case Environment.production:
        // Pour l'environnement de production, vous pouvez aussi utiliser une IP locale
        // si vous testez avec un serveur local
        return getBackendUrl(); // Utilise la même configuration pour les tests locaux
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
          'api_timeout': 300000, // Augmenté à 300 secondes (5 minutes) pour connexions lentes
          'enable_logging': true,
          'enable_cache': false,
          'app_name': 'INSAM LMS (Dev)',
        };
      case Environment.staging:
        return {
          'api_timeout': 120000, // Augmenté à 120 secondes pour connexions lentes
          'enable_logging': true,
          'enable_cache': true,
          'app_name': 'INSAM LMS (Staging)',
        };
      case Environment.production:
        return {
          'api_timeout':
              120000, // Augmenté à 120 secondes pour serveur local lent
          'enable_logging': true, // Activé pour debug
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
