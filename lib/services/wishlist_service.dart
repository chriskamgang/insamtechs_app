import 'api_service.dart';

class WishlistService {
  static final WishlistService _instance = WishlistService._internal();
  factory WishlistService() => _instance;
  WishlistService._internal();

  final ApiService _apiService = ApiService();

  /// Récupérer la wishlist d'un utilisateur
  Future<List<dynamic>> getUserWishlist(int userId) async {
    try {
      final response = await _apiService.get('/wishlist/$userId');
      final data = response.data;

      if (data['error'] == false && data['datas'] != null) {
        return List<dynamic>.from(data['datas']);
      }
      return [];
    } catch (e) {
      print('Erreur lors de la récupération de la wishlist: $e');
      throw Exception('Impossible de récupérer la wishlist');
    }
  }

  /// Ajouter une formation à la wishlist
  Future<Map<String, dynamic>> addToWishlist({
    required int userId,
    required int formationId,
    String language = 'fr',
  }) async {
    try {
      final response = await _apiService.post(
        '/wishlist/add',
        data: {
          'user_id': userId,
          'formation_id': formationId,
          'language': language,
        },
      );

      return response.data;
    } catch (e) {
      print('Erreur lors de l\'ajout à la wishlist: $e');
      throw Exception('Impossible d\'ajouter à la wishlist');
    }
  }

  /// Retirer une formation de la wishlist
  Future<Map<String, dynamic>> removeFromWishlist({
    required int userId,
    required int formationId,
  }) async {
    try {
      final response = await _apiService.post(
        '/wishlist/remove',
        data: {
          'user_id': userId,
          'formation_id': formationId,
        },
      );

      return response.data;
    } catch (e) {
      print('Erreur lors de la suppression de la wishlist: $e');
      throw Exception('Impossible de retirer de la wishlist');
    }
  }

  /// Vérifier si une formation est dans la wishlist
  Future<bool> isInWishlist({
    required int userId,
    required int formationId,
  }) async {
    try {
      final wishlist = await getUserWishlist(userId);
      return wishlist.any((item) => item['formation_id'] == formationId);
    } catch (e) {
      print('Erreur lors de la vérification de la wishlist: $e');
      return false;
    }
  }
}