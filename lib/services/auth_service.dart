import '../models/user.dart';
import '../models/auth_response.dart';
import '../config/api_config.dart';
import 'api_service.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final ApiService _apiService = ApiService();
  User? _currentUser;

  /// Login user with phone number and password
  Future<AuthResponse> login({
    required String telephone,
    required String password,
  }) async {
    try {
      final loginRequest = LoginRequest(
        telephone: telephone,
        password: password,
      );

      final response = await _apiService.post(
        ApiConfig.loginEndpoint,
        data: loginRequest.toJson(),
      );

      // Gérer les réponses d'erreur d'authentification
      if (response.statusCode == 401 || response.statusCode == 422) {
        return AuthResponse(
          message: response.data['message'] ?? 'Erreur d\'authentification',
          token: null,
          user: null,
        );
      }

      final authResponse = AuthResponse.fromJson(response.data);

      // Save token if login successful
      if (authResponse.success && authResponse.token != null) {
        await _apiService.setToken(authResponse.token!);

        // Save user data to secure storage
        if (authResponse.user != null) {
          await _saveUserData(authResponse.user!);
        }
      }

      return authResponse;
    } catch (e) {
      // Au lieu de lancer une exception, retourner une AuthResponse avec échec
      final error = _handleAuthError(e);
      return AuthResponse(
        message: error is AuthException ? error.message : error.toString(),
        token: null,
        user: null,
      );
    }
  }

  /// Register new user
  Future<AuthResponse> register({
    required String nom,
    required String prenom,
    required String email,
    required String telephone,
    required String password,
    required String passwordConfirmation,
    String? genre,
    String? age,
  }) async {
    try {
      final registerRequest = RegisterRequest(
        nom: nom,
        prenom: prenom,
        telephone: telephone,
        password: password,
      );

      final response = await _apiService.post(
        ApiConfig.registerEndpoint,
        data: registerRequest.toJson(),
      );

      // Gérer les réponses d'erreur d'authentification
      if (response.statusCode == 401 || response.statusCode == 422) {
        return AuthResponse(
          message: response.data['message'] ?? 'Erreur d\'inscription',
          token: null,
          user: null,
        );
      }

      final authResponse = AuthResponse.fromJson(response.data);

      // Save token if registration successful
      if (authResponse.success && authResponse.token != null) {
        await _apiService.setToken(authResponse.token!);

        // Save user data to secure storage
        if (authResponse.user != null) {
          await _saveUserData(authResponse.user!);
        }
      }

      return authResponse;
    } catch (e) {
      // Au lieu de lancer une exception, retourner une AuthResponse avec échec
      final error = _handleAuthError(e);
      return AuthResponse(
        message: error is AuthException ? error.message : error.toString(),
        token: null,
        user: null,
      );
    }
  }

  /// Logout user
  Future<void> logout() async {
    try {
      // Call logout endpoint if token exists
      final token = await _apiService.getToken();
      if (token != null) {
        await _apiService.post(ApiConfig.logoutEndpoint);
      }
    } catch (e) {
      // Even if logout fails on server, clear local data
      print('Logout API call failed: $e');
    } finally {
      // Always clear local data
      await _clearUserData();
    }
  }

  /// Get current user from memory
  Future<User?> getCurrentUser() async {
    return _currentUser;
  }

  /// Check if user is authenticated
  Future<bool> isAuthenticated() async {
    final token = await _apiService.getToken();
    return token != null && token.isNotEmpty;
  }

  /// Update user profile
  Future<User> updateProfile({
    required int userId,
    String? nom,
    String? prenom,
    String? email,
    String? telephone,
    String? genre,
    String? age,
  }) async {
    try {
      final updateData = <String, dynamic>{};

      if (nom != null) updateData['nom'] = nom;
      if (prenom != null) updateData['prenom'] = prenom;
      if (email != null) updateData['email'] = email;
      if (telephone != null) updateData['tel_1'] = telephone;
      if (genre != null) updateData['genre'] = genre;
      if (age != null) updateData['age'] = age;

      final response = await _apiService.post(
        ApiConfig.updateProfileEndpoint,
        data: updateData,
      );

      // Assuming the response contains updated user data
      final userData = response.data['user'] ?? response.data;
      final updatedUser = User.fromJson(userData);

      // Save updated user data
      await _saveUserData(updatedUser);

      return updatedUser;
    } catch (e) {
      throw _handleAuthError(e);
    }
  }

  /// Refresh user data from server
  Future<User?> refreshUserData() async {
    try {
      final response = await _apiService.get(ApiConfig.userProfileEndpoint);
      final userData = response.data['user'] ?? response.data;
      final user = User.fromJson(userData);

      await _saveUserData(user);
      return user;
    } catch (e) {
      throw _handleAuthError(e);
    }
  }

  /// Save user data to memory
  Future<void> _saveUserData(User user) async {
    _currentUser = user;
  }

  /// Clear all user data
  Future<void> _clearUserData() async {
    await _apiService.clearToken();
    _currentUser = null;
  }

  /// Handle authentication errors
  Exception _handleAuthError(dynamic error) {
    if (error is ApiException) {
      switch (error.statusCode) {
        case 401:
          return AuthException('Identifiants invalides');
        case 422:
          // Pour les erreurs de validation, utiliser le message du backend
          return AuthException(error.message);
        case 429:
          return AuthException('Trop de tentatives. Réessayez plus tard');
        case 500:
          return AuthException('Erreur serveur. Réessayez plus tard');
        default:
          return AuthException(error.message);
      }
    } else if (error is ApiException && error.statusCode == 0) {
      return AuthException('Pas de connexion internet');
    } else {
      return AuthException('Une erreur inattendue s\'est produite');
    }
  }
}

/// Custom authentication exception
class AuthException implements Exception {
  final String message;

  AuthException(this.message);

  @override
  String toString() => message;
}

