import '../models/user.dart';
import '../config/api_config.dart';
import 'api_service.dart';

class UserService {
  static final UserService _instance = UserService._internal();
  factory UserService() => _instance;
  UserService._internal();

  final ApiService _apiService = ApiService();

  /// Update user profile
  Future<Map<String, dynamic>> updateProfile({
    required int userId,
    required String name,
    required String surname,
    required String tel,
    required String email,
    String? password,
  }) async {
    try {
      final response = await _apiService.post(
        ApiConfig.updateProfileEndpoint,
        data: {
          'user_id': userId,
          'name': name,
          'surname': surname,
          'tel': tel,
          'email': email,
          if (password != null && password.isNotEmpty) 'password': password,
        },
      );

      return response.data;
    } catch (e) {
      throw UserException('Erreur lors de la mise à jour du profil: ${e.toString()}');
    }
  }

  /// Get current user profile
  Future<User> getCurrentUserProfile(int userId) async {
    try {
      // Pour l'instant, on utilise l'endpoint des commandes qui retourne l'utilisateur avec ses données
      final response = await _apiService.get('/user/$userId');
      return User.fromJson(response.data);
    } catch (e) {
      throw UserException('Erreur lors du chargement du profil: ${e.toString()}');
    }
  }

  /// Upload profile image
  Future<Map<String, dynamic>> uploadProfileImage({
    required int userId,
    required String imagePath,
  }) async {
    try {
      // TODO: Implémenter l'upload d'image quand l'endpoint sera disponible
      throw UnimplementedError('Upload d\'image pas encore implémenté');
    } catch (e) {
      throw UserException('Erreur lors de l\'upload de l\'image: ${e.toString()}');
    }
  }
}

/// Custom exception for user-related errors
class UserException implements Exception {
  final String message;

  UserException(this.message);

  @override
  String toString() => message;
}