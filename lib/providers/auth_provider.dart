import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';

enum AuthStatus { loading, authenticated, unauthenticated }

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final ApiService _apiService = ApiService();

  AuthStatus _status = AuthStatus.unauthenticated;
  User? _user;
  String? _errorMessage;

  // Getters
  AuthStatus get status => _status;
  User? get user => _user;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _status == AuthStatus.authenticated;
  bool get isLoading => _status == AuthStatus.loading;

  /// Initialize authentication state
  Future<void> initialize() async {
    _setStatus(AuthStatus.loading);

    try {
      // Check if user has a valid token
      final isAuth = await _authService.isAuthenticated();

      if (isAuth) {
        // Try to get current user from AuthService
        final currentUser = await _authService.getCurrentUser();

        if (currentUser != null) {
          _user = currentUser;
          _setStatus(AuthStatus.authenticated);
        } else {
          // Token exists but no user data, try to refresh from server
          try {
            _user = await _authService.refreshUserData();
            _setStatus(AuthStatus.authenticated);
          } catch (e) {
            // Failed to refresh user data, clear token and set unauthenticated
            await _authService.logout();
            _setStatus(AuthStatus.unauthenticated);
          }
        }
      } else {
        _setStatus(AuthStatus.unauthenticated);
      }
    } catch (e) {
      debugPrint('Auth initialization error: $e');
      _setStatus(AuthStatus.unauthenticated);
    }
  }

  /// Login user with real API
  Future<bool> login({
    required String telephone,
    required String password,
  }) async {
    _setStatus(AuthStatus.loading);
    _clearError();

    try {
      final authResponse = await _authService.login(
        telephone: telephone,
        password: password,
      );

      if (authResponse.success && authResponse.token != null && authResponse.user != null) {
        _user = authResponse.user;
        _setStatus(AuthStatus.authenticated);
        return true;
      } else {
        _setError(authResponse.message);
        _setStatus(AuthStatus.unauthenticated);
        return false;
      }
    } catch (e) {
      _setError('Une erreur inattendue s\'est produite');
      _setStatus(AuthStatus.unauthenticated);
      return false;
    }
  }

  /// Register user with real API
  Future<bool> register({
    required String nom,
    required String prenom,
    required String email,
    required String telephone,
    required String password,
    required String passwordConfirmation,
    String? genre,
    String? age,
    String? about,
    List<String>? skills,
  }) async {
    _setStatus(AuthStatus.loading);
    _clearError();

    try {
      // Validate password confirmation client-side
      if (password != passwordConfirmation) {
        _setError('Les mots de passe ne correspondent pas');
        _setStatus(AuthStatus.unauthenticated);
        return false;
      }

      final authResponse = await _authService.register(
        nom: nom,
        prenom: prenom,
        email: email,
        telephone: telephone,
        password: password,
        passwordConfirmation: passwordConfirmation,
        genre: genre,
        age: age,
        about: about,
        skills: skills,
      );

      if (authResponse.success && authResponse.token != null && authResponse.user != null) {
        _user = authResponse.user;
        _setStatus(AuthStatus.authenticated);
        return true;
      } else {
        _setError(authResponse.message);
        _setStatus(AuthStatus.unauthenticated);
        return false;
      }
    } catch (e) {
      _setError('Une erreur inattendue s\'est produite');
      _setStatus(AuthStatus.unauthenticated);
      return false;
    }
  }

  /// Logout user with real API
  Future<void> logout() async {
    _setStatus(AuthStatus.loading);

    try {
      await _authService.logout();
    } catch (e) {
      debugPrint('Logout error: $e');
    } finally {
      _user = null;
      _setStatus(AuthStatus.unauthenticated);
    }
  }

  /// Update user profile with real API
  Future<bool> updateProfile({
    String? nom,
    String? prenom,
    String? email,
    String? telephone,
    String? genre,
    String? age,
  }) async {
    if (_user == null) {
      _setError('Utilisateur non connecté');
      return false;
    }

    _clearError();

    try {
      final updatedUser = await _authService.updateProfile(
        userId: _user!.id,
        nom: nom,
        prenom: prenom,
        email: email,
        telephone: telephone,
        genre: genre,
        age: age,
      );

      _user = updatedUser;
      notifyListeners();
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    }
  }

  /// Refresh user data from server
  Future<void> refreshUser() async {
    if (_status != AuthStatus.authenticated) return;

    try {
      final refreshedUser = await _authService.refreshUserData();
      if (refreshedUser != null) {
        _user = refreshedUser;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Refresh user error: $e');
      // If refresh fails with 401, logout user
      if (e.toString().contains('401')) {
        await logout();
      }
    }
  }

  /// Clear error message
  void clearError() {
    _clearError();
  }

  // Private methods
  void _setStatus(AuthStatus status) {
    _status = status;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Update user data after profile modification
  void updateUserData(User updatedUser) {
    _user = updatedUser;
    notifyListeners();
  }

  /// Get user ID quickly
  Future<int?> getUserId() async {
    if (_user != null) {
      return _user!.id;
    }
    // Try to get from secure storage
    return await _apiService.getUserId();
  }
}
