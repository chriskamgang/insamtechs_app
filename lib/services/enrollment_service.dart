import '../models/enrollment.dart';
import '../config/api_config.dart';
import 'api_service.dart';

class EnrollmentService {
  static final EnrollmentService _instance = EnrollmentService._internal();
  factory EnrollmentService() => _instance;
  EnrollmentService._internal();

  final ApiService _apiService = ApiService();

  /// Enroll in a course
  Future<Map<String, dynamic>> enrollInCourse({
    required int formationId,
    required int userId,
  }) async {
    try {
      // L'API backend attend user_id et formation_id
      final response = await _apiService.post(
        ApiConfig.commanderFormationEndpoint,
        data: {
          'user_id': userId,
          'formation_id': formationId,
        },
      );

      return response.data;
    } catch (e) {
      throw EnrollmentException('Erreur lors de l\'inscription: ${e.toString()}');
    }
  }

  /// Get user's enrollments
  Future<List<dynamic>> getUserEnrollments(int userId) async {
    try {
      // Utiliser l'endpoint backend mes_formations/{user_id}
      final response = await _apiService.get(
        '${ApiConfig.mesFormationsEndpoint}/$userId',
      );

      return response.data ?? [];
    } catch (e) {
      // En cas d'erreur, retourner une liste vide
      return [];
    }
  }

  /// Check if user is enrolled in a course
  Future<bool> isEnrolledInCourse(int formationId, int userId) async {
    try {
      // Utiliser l'endpoint backend get_commande/{formationId}/{userId}
      final response = await _apiService.get(
        '${ApiConfig.getCommandeEndpoint}/$formationId/$userId',
      );

      // Si on a une réponse avec une commande, l'utilisateur est inscrit
      return response.data != null && response.data['commande'] != null;
    } catch (e) {
      // Si erreur ou pas de commande, l'utilisateur n'est pas inscrit
      return false;
    }
  }

  /// Get enrollment details for a specific course
  Future<Map<String, dynamic>?> getCourseEnrollment(int formationId, int userId) async {
    try {
      final response = await _apiService.get(
        '${ApiConfig.getCommandeEndpoint}/$formationId/$userId',
      );
      return response.data;
    } catch (e) {
      return null;
    }
  }

  /// Confirm payment for an enrollment
  Future<EnrollmentResponse> confirmPayment({
    required String orderId,
    required String paymentId,
    required String paymentStatus,
    required double amount,
    required String paymentMethod,
    String? transactionId,
  }) async {
    try {
      final paymentConfirmation = PaymentConfirmation(
        orderId: orderId,
        paymentId: paymentId,
        paymentStatus: paymentStatus,
        amount: amount,
        paymentMethod: paymentMethod,
        transactionId: transactionId,
      );

      final response = await _apiService.post(
        ApiConfig.paymentConfirmationEndpoint,
        data: paymentConfirmation.toJson(),
      );

      return EnrollmentResponse.fromJson(response.data);
    } catch (e) {
      throw EnrollmentException('Erreur lors de la confirmation de paiement: ${e.toString()}');
    }
  }

  /// Update course progress
  Future<bool> updateCourseProgress({
    required int enrollmentId,
    required double progress,
    int? lastWatchedVideo,
    List<int>? completedVideos,
  }) async {
    try {
      final response = await _apiService.post(
        '${ApiConfig.updateProgressEndpoint}/$enrollmentId',
        data: {
          'progress': progress,
          'last_watched_video': lastWatchedVideo,
          'completed_videos': completedVideos,
        },
      );

      return response.data['success'] ?? false;
    } catch (e) {
      throw EnrollmentException('Erreur lors de la mise à jour de la progression: ${e.toString()}');
    }
  }

  /// Cancel enrollment
  Future<bool> cancelEnrollment(int enrollmentId) async {
    try {
      final response = await _apiService.post(
        '${ApiConfig.cancelEnrollmentEndpoint}/$enrollmentId',
      );

      return response.data['success'] ?? false;
    } catch (e) {
      throw EnrollmentException('Erreur lors de l\'annulation: ${e.toString()}');
    }
  }

  /// Get enrollment statistics
  Future<Map<String, dynamic>> getEnrollmentStats(int userId) async {
    try {
      final response = await _apiService.get(
        '${ApiConfig.enrollmentStatsEndpoint}/$userId',
      );

      return response.data;
    } catch (e) {
      throw EnrollmentException('Erreur lors du chargement des statistiques: ${e.toString()}');
    }
  }
}

/// Custom exception for enrollment-related errors
class EnrollmentException implements Exception {
  final String message;

  EnrollmentException(this.message);

  @override
  String toString() => message;
}