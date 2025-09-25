import 'package:flutter/material.dart';
import '../services/analytics_service.dart';

class AnalyticsProvider with ChangeNotifier {
  final AnalyticsService _analyticsService = AnalyticsService();

  Map<String, dynamic> _userAnalytics = {};
  bool _isLoading = false;
  String? _errorMessage;

  Map<String, dynamic> get userAnalytics => _userAnalytics;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? error) {
    _errorMessage = error;
    notifyListeners();
  }

  /// Load user analytics
  Future<void> loadUserAnalytics(int userId) async {
    try {
      _setLoading(true);
      _setError(null);

      final analytics = await _analyticsService.getUserAnalytics(userId);
      _userAnalytics = analytics;
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  /// Track video progress
  Future<bool> trackVideoProgress({
    required int userId,
    required int videoId,
    required int currentTime,
    required int totalTime,
    required bool completed,
  }) async {
    return await _analyticsService.trackVideoProgress(
      userId: userId,
      videoId: videoId,
      currentTime: currentTime,
      totalTime: totalTime,
      completed: completed,
    );
  }

  /// Track course completion
  Future<bool> trackCourseCompletion({
    required int userId,
    required int courseId,
    required double completionPercentage,
  }) async {
    return await _analyticsService.trackCourseCompletion(
      userId: userId,
      courseId: courseId,
      completionPercentage: completionPercentage,
    );
  }

  /// Track session start
  void trackSessionStart(int userId) {
    _analyticsService.trackSessionStart(userId);
  }

  /// Track session end
  void trackSessionEnd(int userId, int sessionDuration) {
    _analyticsService.trackSessionEnd(userId, sessionDuration);
  }

  void clearError() {
    _setError(null);
  }

  void reset() {
    _userAnalytics = {};
    _isLoading = false;
    _errorMessage = null;
    notifyListeners();
  }
}