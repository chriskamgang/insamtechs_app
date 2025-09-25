import 'package:flutter/foundation.dart';
import '../models/user.dart';

enum AuthStatus { loading, authenticated, unauthenticated }

class AuthProvider extends ChangeNotifier {
  AuthStatus _status = AuthStatus.unauthenticated;
  User? _user;
  String? _errorMessage;

  // Mock user for demo purposes
  static final _mockUser = User(
    id: 1,
    nom: 'Dupont',
    prenom: 'Jean',
    email: 'jean.dupont@example.com',
    telephone: '0123456789',
    genre: 'Homme',
    age: '25',
    createdAt: DateTime.now().toIso8601String(),
    updatedAt: DateTime.now().toIso8601String(),
  );

  // Getters
  AuthStatus get status => _status;
  User? get user => _user;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _status == AuthStatus.authenticated;
  bool get isLoading => _status == AuthStatus.loading;

  /// Initialize authentication state (mock implementation)
  Future<void> initialize() async {
    _setStatus(AuthStatus.loading);

    try {
      await Future.delayed(const Duration(milliseconds: 500));

      // For demo purposes, keep user unauthenticated by default
      _setStatus(AuthStatus.unauthenticated);
    } catch (e) {
      _setStatus(AuthStatus.unauthenticated);
    }
  }

  /// Login user (mock implementation)
  Future<bool> login({
    required String telephone,
    required String password,
  }) async {
    _setStatus(AuthStatus.loading);
    _clearError();

    try {
      await Future.delayed(const Duration(milliseconds: 1000)); // Simulate network delay

      // Simple mock validation
      if (telephone.isNotEmpty && password.length >= 4) {
        _user = _mockUser;
        _setStatus(AuthStatus.authenticated);
        return true;
      } else {
        _setError('Identifiants invalides');
        _setStatus(AuthStatus.unauthenticated);
        return false;
      }
    } catch (e) {
      _setError('Une erreur inattendue s\'est produite');
      _setStatus(AuthStatus.unauthenticated);
      return false;
    }
  }

  /// Register user (mock implementation)
  Future<bool> register({
    required String nom,
    required String prenom,
    required String email,
    required String telephone,
    required String password,
    required String passwordConfirmation,
    String? genre,
    String? age,
  }) async {
    _setStatus(AuthStatus.loading);
    _clearError();

    try {
      await Future.delayed(const Duration(milliseconds: 1200)); // Simulate network delay

      // Simple mock validation
      if (nom.isNotEmpty &&
          prenom.isNotEmpty &&
          email.isNotEmpty &&
          telephone.isNotEmpty &&
          password.length >= 4 &&
          password == passwordConfirmation) {

        _user = User(
          id: 2,
          nom: nom,
          prenom: prenom,
          email: email,
          telephone: telephone,
          genre: genre,
          age: age,
          createdAt: DateTime.now().toIso8601String(),
          updatedAt: DateTime.now().toIso8601String(),
        );
        _setStatus(AuthStatus.authenticated);
        return true;
      } else {
        _setError('Veuillez vérifier tous les champs');
        _setStatus(AuthStatus.unauthenticated);
        return false;
      }
    } catch (e) {
      _setError('Une erreur inattendue s\'est produite');
      _setStatus(AuthStatus.unauthenticated);
      return false;
    }
  }

  /// Logout user (mock implementation)
  Future<void> logout() async {
    _setStatus(AuthStatus.loading);

    try {
      await Future.delayed(const Duration(milliseconds: 300));
    } catch (e) {
      debugPrint('Logout error: \$e');
    } finally {
      _user = null;
      _setStatus(AuthStatus.unauthenticated);
    }
  }

  /// Update user profile (mock implementation)
  Future<bool> updateProfile({
    String? nom,
    String? prenom,
    String? email,
    String? telephone,
    String? genre,
    String? age,
  }) async {
    if (_user == null) return false;

    _clearError();

    try {
      await Future.delayed(const Duration(milliseconds: 500));

      _user = User(
        id: _user!.id,
        nom: nom ?? _user!.nom,
        prenom: prenom ?? _user!.prenom,
        email: email ?? _user!.email,
        telephone: telephone ?? _user!.telephone,
        genre: genre ?? _user!.genre,
        age: age ?? _user!.age,
        createdAt: _user!.createdAt,
        updatedAt: DateTime.now().toIso8601String(),
      );

      notifyListeners();
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    }
  }

  /// Refresh user data (mock implementation)
  Future<void> refreshUser() async {
    if (_status != AuthStatus.authenticated) return;

    try {
      await Future.delayed(const Duration(milliseconds: 300));
      // In mock implementation, user data doesn't change
      notifyListeners();
    } catch (e) {
      debugPrint('Refresh user error: \$e');
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
}