import 'environment.dart';

class ApiConfig {
  // Backend API base URL - Utilise EnvironmentConfig
  static String get baseUrl => EnvironmentConfig.apiBaseUrl;

  // API Endpoints
  static const String loginEndpoint = '/login';
  static const String registerEndpoint = '/register';
  static const String logoutEndpoint = '/logout';
  static const String userProfileEndpoint = '/user/profile';
  static const String updateProfileEndpoint = '/user/update';

  // Course endpoints
  static const String coursesEndpoint = '/formations';
  static const String formationsEndpoint = '/formations';
  static const String coursesByCategoryEndpoint = '/formation';
  static const String courseBySlugEndpoint = '/formation_by_Slug';
  static const String searchEndpoint = '/search';

  // Enrollment endpoints
  static const String commanderFormationEndpoint = '/commander_formation';
  static const String getCommandeEndpoint = '/get_commande';
  static const String mesFormationsEndpoint = '/mes_formations';
  static const String userEnrollmentsEndpoint = '/user/enrollments';
  static const String paymentConfirmationEndpoint = '/payment/confirm';
  static const String updateProgressEndpoint = '/enrollment/progress';
  static const String cancelEnrollmentEndpoint = '/enrollment/cancel';
  static const String enrollmentStatsEndpoint = '/enrollment/stats';

  // Other endpoints
  static const String categoriesEndpoint = '/categories';
  static const String wishlistEndpoint = '/wishlist';

  // Request timeouts - Utilise la configuration d'environnement
  static int get connectTimeout => EnvironmentConfig.config['api_timeout'];
  static int get receiveTimeout => EnvironmentConfig.config['api_timeout'];
  static int get sendTimeout => EnvironmentConfig.config['api_timeout'];

  // Headers
  static Map<String, String> get defaultHeaders => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  static Map<String, String> getAuthHeaders(String token) => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    'Authorization': 'Bearer $token',
  };

  // Storage keys
  static const String tokenKey = 'auth_token';
  static const String userKey = 'user_data';
  static const String languageKey = 'app_language';

  // Default values
  static const String defaultLanguage = 'fr';
  static const int defaultPerPage = 20;
}