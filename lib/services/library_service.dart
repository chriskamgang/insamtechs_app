import 'api_service.dart';

class LibraryService {
  final ApiService _apiService = ApiService();

  /// Récupérer le contenu de la bibliothèque
  Future<Map<String, dynamic>> getLibraryContent() async {
    try {
      // Try to get more categories by adding pagination parameters
      final response = await _apiService.get('/bibliotheque?per_page=100');
      return response.data;
    } catch (e) {
      // Fallback to original endpoint if pagination fails
      try {
        final response = await _apiService.get('/bibliotheque');
        return response.data;
      } catch (e2) {
        throw Exception('Erreur lors du chargement de la bibliothèque: $e');
      }
    }
  }

  /// Récupérer les livres par catégorie
  Future<List<dynamic>> getBooksByCategory(String categorySlug) async {
    try {
      final response = await _apiService.get('/livres_by_category/$categorySlug');

      // Handle the API response structure which may have pagination
      final livresData = response.data['livres'];
      if (livresData is Map<String, dynamic> && livresData['data'] is List) {
        return livresData['data'] as List<dynamic>;
      } else if (livresData is List<dynamic>) {
        return livresData;
      }

      return [];
    } catch (e) {
      throw Exception('Erreur lors du chargement des livres: $e');
    }
  }

  /// Récupérer les filières d'étude
  Future<List<dynamic>> getStudyFields() async {
    try {
      final response = await _apiService.get('/filieres');

      // Handle the API response structure: {'filieres': {'current_page': 1, 'data': [...]}}
      final filieresData = response.data['filieres'];
      if (filieresData is Map<String, dynamic> && filieresData['data'] is List) {
        return filieresData['data'] as List<dynamic>;
      } else if (filieresData is List<dynamic>) {
        return filieresData;
      }

      return [];
    } catch (e) {
      throw Exception('Erreur lors du chargement des filières: $e');
    }
  }

  /// Récupérer les fascicules par catégorie
  Future<List<dynamic>> getFasciculesByCategory(String categorySlug) async {
    try {
      final response = await _apiService.get('/fascicules_categorie/$categorySlug');

      // Handle the API response structure which may have pagination
      final fasciculesData = response.data['fascicules'];
      if (fasciculesData is Map<String, dynamic> && fasciculesData['data'] is List) {
        return fasciculesData['data'] as List<dynamic>;
      } else if (fasciculesData is List<dynamic>) {
        return fasciculesData;
      }

      return [];
    } catch (e) {
      throw Exception('Erreur lors du chargement des fascicules: $e');
    }
  }
}