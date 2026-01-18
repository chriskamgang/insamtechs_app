import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import '../models/course.dart';
import '../services/wishlist_service.dart';

class WishlistProvider with ChangeNotifier {
  final WishlistService _wishlistService = WishlistService();

  List<Course> _wishlistItems = [];
  final Set<int> _wishlistFormationIds = {};
  bool _isLoading = false;
  String? _errorMessage;
  bool _isDisposed = false;

  // Getters
  List<Course> get wishlistItems => List.unmodifiable(_wishlistItems);
  Set<int> get wishlistFormationIds => Set.unmodifiable(_wishlistFormationIds);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasError => _errorMessage != null;
  int get wishlistCount => _wishlistFormationIds.length;

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  /// Vérifier si une formation est dans la wishlist
  bool isInWishlist(int formationId) {
    return _wishlistFormationIds.contains(formationId);
  }

  /// Charger la wishlist de l'utilisateur avec API réelle
  Future<void> loadUserWishlist(int userId) async {
    _setLoading(true);
    _clearError();

    try {
      final wishlistData = await _wishlistService.getUserWishlist(userId);

      // Parser les données JSON en objets Course
      _wishlistItems = wishlistData
          .map((item) => Course.fromJson(item as Map<String, dynamic>))
          .toList();

      // Mettre à jour les IDs
      _wishlistFormationIds.clear();
      _wishlistFormationIds.addAll(_wishlistItems.map((course) => course.id));

      if (!_isDisposed) {
        notifyListeners();
      }
    } catch (e) {
      _setError('Impossible de charger la wishlist: ${e.toString()}');
    } finally {
      if (!_isDisposed) {
        _setLoading(false);
      }
    }
  }

  /// Ajouter une formation à la wishlist avec API réelle
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
      final response = await _wishlistService.addToWishlist(
        userId: userId,
        formationId: formationId,
      );

      // Vérifier le succès dans la réponse
      final success = response['error'] == false || response['success'] == true;

      if (success) {
        // Ajouter à la liste locale
        _wishlistFormationIds.add(formationId);

        // Recharger la wishlist pour obtenir les détails complets
        await loadUserWishlist(userId);
      }

      return success;
    } catch (e) {
      _setError('Impossible d\'ajouter à la wishlist: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Retirer une formation de la wishlist avec API réelle
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
      final response = await _wishlistService.removeFromWishlist(
        userId: userId,
        formationId: formationId,
      );

      // Vérifier le succès dans la réponse
      final success = response['error'] == false || response['success'] == true;

      if (success) {
        // Retirer de la liste locale
        _wishlistFormationIds.remove(formationId);
        _wishlistItems.removeWhere((course) => course.id == formationId);
        notifyListeners();
      }

      return success;
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
    _wishlistItems.clear();
    _wishlistFormationIds.clear();
    _clearError();
    notifyListeners();
  }

  // Méthodes privées pour la gestion d'état
  void _setLoading(bool loading) {
    _isLoading = loading;
    if (!_isDisposed) {
      notifyListeners();
    }
  }

  void _setError(String error) {
    _errorMessage = error;
    if (!_isDisposed) {
      notifyListeners();
    }
  }

  void _clearError() {
    _errorMessage = null;
  }
}
