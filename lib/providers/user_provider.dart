import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/user_service.dart';

class UserProvider with ChangeNotifier {
  final UserService _userService = UserService();

  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? error) {
    _errorMessage = error;
    _successMessage = null;
    notifyListeners();
  }

  void _setSuccess(String? message) {
    _successMessage = message;
    _errorMessage = null;
    notifyListeners();
  }

  void clearMessages() {
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
  }

  /// Update user profile
  Future<User?> updateProfile({
    required int userId,
    required String name,
    required String surname,
    required String tel,
    required String email,
    String? password,
  }) async {
    try {
      _setLoading(true);
      clearMessages();

      final response = await _userService.updateProfile(
        userId: userId,
        name: name,
        surname: surname,
        tel: tel,
        email: email,
        password: password,
      );

      // Le backend renvoie toujours 'type': 'error' même en cas de succès
      if (response['message'] != null) {
        if (response['message'].toString().contains('succès')) {
          _setSuccess(response['message']);
          // Retourner l'utilisateur mis à jour
          if (response['user'] != null) {
            return User.fromJson(response['user']);
          }
        } else {
          _setError(response['message']);
        }
      }

      return null;
    } catch (e) {
      _setError(e.toString());
      return null;
    } finally {
      _setLoading(false);
    }
  }

  /// Get user profile
  Future<User?> getUserProfile(int userId) async {
    try {
      _setLoading(true);
      clearMessages();

      final user = await _userService.getCurrentUserProfile(userId);
      return user;
    } catch (e) {
      _setError(e.toString());
      return null;
    } finally {
      _setLoading(false);
    }
  }

  /// Upload profile image
  Future<bool> uploadProfileImage({
    required int userId,
    required String imagePath,
  }) async {
    try {
      _setLoading(true);
      clearMessages();

      final response = await _userService.uploadProfileImage(
        userId: userId,
        imagePath: imagePath,
      );

      if (response['success'] == true) {
        _setSuccess('Image de profil mise à jour avec succès');
        return true;
      } else {
        _setError(response['message'] ?? 'Erreur lors de l\'upload');
        return false;
      }
    } catch (e) {
      if (e is UnimplementedError) {
        _setError('La fonction d\'upload d\'image n\'est pas encore disponible');
      } else {
        _setError(e.toString());
      }
      return false;
    } finally {
      _setLoading(false);
    }
  }
}