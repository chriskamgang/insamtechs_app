import 'package:flutter/foundation.dart';
import '../data/mock_data.dart';
import '../models/course.dart';

class WishlistProvider with ChangeNotifier {
  final Set<int> _wishlistFormationIds = {};
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  List<Course> get wishlistItems {
    final allCourses = MockData.getMockCourses();
    return allCourses.where((course) => _wishlistFormationIds.contains(course.id)).toList();
  }

  Set<int> get wishlistFormationIds => Set.unmodifiable(_wishlistFormationIds);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasError => _errorMessage != null;
  int get wishlistCount => _wishlistFormationIds.length;

  /// Vérifier si une formation est dans la wishlist
  bool isInWishlist(int formationId) {
    return _wishlistFormationIds.contains(formationId);
  }

  /// Charger la wishlist de l'utilisateur (mock implementation)
  Future<void> loadUserWishlist(int userId) async {
    _setLoading(true);
    _clearError();

    try {
      await Future.delayed(const Duration(milliseconds: 300));

      // Mock: Load some random courses as wishlist
      _wishlistFormationIds.clear();
      _wishlistFormationIds.addAll([1, 3, 5]); // Mock wishlist with courses 1, 3, and 5

      notifyListeners();
    } catch (e) {
      _setError('Impossible de charger la wishlist: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  /// Ajouter une formation à la wishlist (mock implementation)
  Future<bool> addToWishlist({
    required int userId,
    required int formationId,
    String language = 'fr',
  }) async {
    if (_wishlistFormationIds.contains(formationId)) {
      return true; // Déjà dans la wishlist
    }

    _setLoading(true);
    _clearError();

    try {
      await Future.delayed(const Duration(milliseconds: 300));

      // Ajouter à la liste locale
      _wishlistFormationIds.add(formationId);
      notifyListeners();

      return true;
    } catch (e) {
      _setError('Impossible d\'ajouter à la wishlist: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Retirer une formation de la wishlist (mock implementation)
  Future<bool> removeFromWishlist({
    required int userId,
    required int formationId,
  }) async {
    if (!_wishlistFormationIds.contains(formationId)) {
      return true; // Pas dans la wishlist
    }

    _setLoading(true);
    _clearError();

    try {
      await Future.delayed(const Duration(milliseconds: 300));

      // Retirer de la liste locale
      _wishlistFormationIds.remove(formationId);
      notifyListeners();

      return true;
    } catch (e) {
      _setError('Impossible de retirer de la wishlist: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Basculer le statut wishlist d'une formation
  Future<bool> toggleWishlist({
    required int userId,
    required int formationId,
    String language = 'fr',
  }) async {
    if (isInWishlist(formationId)) {
      return await removeFromWishlist(
        userId: userId,
        formationId: formationId,
      );
    } else {
      return await addToWishlist(
        userId: userId,
        formationId: formationId,
        language: language,
      );
    }
  }

  /// Actualiser la wishlist
  Future<void> refreshWishlist(int userId) async {
    await loadUserWishlist(userId);
  }

  /// Vider la wishlist (lors de la déconnexion)
  void clearWishlist() {
    _wishlistFormationIds.clear();
    _clearError();
    notifyListeners();
  }

  // Méthodes privées pour la gestion d'état
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }
}