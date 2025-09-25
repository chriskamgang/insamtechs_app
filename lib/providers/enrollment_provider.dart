import 'package:flutter/material.dart';
import '../models/enrollment.dart';
import '../services/enrollment_service.dart';

class EnrollmentProvider with ChangeNotifier {
  final EnrollmentService _enrollmentService = EnrollmentService();

  List<dynamic> _userEnrollments = [];
  bool _isLoading = false;
  String? _errorMessage;
  Map<String, dynamic>? _enrollmentStats;

  List<dynamic> get userEnrollments => _userEnrollments;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  Map<String, dynamic>? get enrollmentStats => _enrollmentStats;

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? error) {
    _errorMessage = error;
    notifyListeners();
  }

  Future<Map<String, dynamic>> enrollInCourse({
    required int formationId,
    required int userId,
  }) async {
    try {
      _setLoading(true);
      _setError(null);

      final response = await _enrollmentService.enrollInCourse(
        formationId: formationId,
        userId: userId,
      );

      // Rafraîchir la liste des inscriptions
      await refreshUserEnrollments(userId);

      return response;
    } catch (e) {
      _setError(e.toString());
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> refreshUserEnrollments([int? userId]) async {
    if (userId == null) return;

    try {
      _setLoading(true);
      _setError(null);

      final userEnrollments = await _enrollmentService.getUserEnrollments(userId);
      _userEnrollments = userEnrollments;
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> isEnrolledInCourse(int formationId, int userId) async {
    try {
      return await _enrollmentService.isEnrolledInCourse(formationId, userId);
    } catch (e) {
      _setError(e.toString());
      return false;
    }
  }

  Future<Map<String, dynamic>?> getCourseEnrollment(int formationId, int userId) async {
    try {
      return await _enrollmentService.getCourseEnrollment(formationId, userId);
    } catch (e) {
      _setError(e.toString());
      return null;
    }
  }

  Future<EnrollmentResponse> confirmPayment({
    required String orderId,
    required String paymentId,
    required String paymentStatus,
    required double amount,
    required String paymentMethod,
    String? transactionId,
  }) async {
    try {
      _setLoading(true);
      _setError(null);

      final response = await _enrollmentService.confirmPayment(
        orderId: orderId,
        paymentId: paymentId,
        paymentStatus: paymentStatus,
        amount: amount,
        paymentMethod: paymentMethod,
        transactionId: transactionId,
      );

      await refreshUserEnrollments();

      return response;
    } catch (e) {
      _setError(e.toString());
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> updateCourseProgress({
    required int enrollmentId,
    required double progress,
    int? lastWatchedVideo,
    List<int>? completedVideos,
  }) async {
    try {
      _setLoading(true);
      _setError(null);

      final success = await _enrollmentService.updateCourseProgress(
        enrollmentId: enrollmentId,
        progress: progress,
        lastWatchedVideo: lastWatchedVideo,
        completedVideos: completedVideos,
      );

      if (success) {
        // Rafraîchir la liste des inscriptions
        notifyListeners();
      }

      return success;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> cancelEnrollment(int enrollmentId) async {
    try {
      _setLoading(true);
      _setError(null);

      final success = await _enrollmentService.cancelEnrollment(enrollmentId);

      if (success) {
        _userEnrollments.removeWhere((enrollment) => enrollment['id'] == enrollmentId);
        notifyListeners();
      }

      return success;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadEnrollmentStats(int userId) async {
    try {
      _setLoading(true);
      _setError(null);

      _enrollmentStats = await _enrollmentService.getEnrollmentStats(userId);
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  void clearError() {
    _setError(null);
  }

  void reset() {
    _userEnrollments = [];
    _enrollmentStats = null;
    _isLoading = false;
    _errorMessage = null;
    notifyListeners();
  }
}