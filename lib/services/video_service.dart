import 'api_service.dart';

class VideoService {
  static final VideoService _instance = VideoService._internal();
  factory VideoService() => _instance;
  VideoService._internal();

  final ApiService _apiService = ApiService();

  /// Récupérer toutes les catégories de vidéothèque
  Future<Map<String, dynamic>> getVideoCategories({int? perPage}) async {
    try {
      final Map<String, dynamic> queryParams = {};
      if (perPage != null) {
        queryParams['per_page'] = perPage.toString();
      }

      final response = await _apiService.get(
        '/videotheque',
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );

      return response.data;
    } catch (e) {
      print('Erreur lors de la récupération des catégories vidéo: $e');
      throw Exception('Impossible de récupérer les catégories vidéo');
    }
  }

  /// Récupérer une catégorie spécifique par slug
  Future<Map<String, dynamic>> getCategoryBySlug(String slug) async {
    try {
      final response = await _apiService.get('/videotheque/$slug');
      return response.data;
    } catch (e) {
      print('Erreur lors de la récupération de la catégorie: $e');
      throw Exception('Impossible de récupérer la catégorie');
    }
  }

  /// Récupérer les formations d'un utilisateur avec vidéos
  Future<List<dynamic>> getUserFormations(int userId) async {
    try {
      final response = await _apiService.get('/videotheque/user/$userId');
      return List<dynamic>.from(response.data);
    } catch (e) {
      print('Erreur lors de la récupération des formations utilisateur: $e');
      throw Exception('Impossible de récupérer les formations utilisateur');
    }
  }

  /// Récupérer les examens vidéothèque d'un utilisateur
  Future<List<dynamic>> getUserVideothequeExams(int userId) async {
    try {
      final response = await _apiService.get('/videotheque_exam/$userId');
      return List<dynamic>.from(response.data);
    } catch (e) {
      print('Erreur lors de la récupération des examens vidéothèque: $e');
      throw Exception('Impossible de récupérer les examens vidéothèque');
    }
  }

  /// Enregistrer le progrès de lecture d'une vidéo
  Future<Map<String, dynamic>> saveVideoProgress({
    required int userId,
    required int videoId,
    required double progress,
    required Duration watchedDuration,
    required Duration totalDuration,
  }) async {
    try {
      final response = await _apiService.post(
        '/video/progress',
        data: {
          'user_id': userId,
          'video_id': videoId,
          'progress': progress,
          'watched_duration': watchedDuration.inSeconds,
          'total_duration': totalDuration.inSeconds,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );

      return response.data;
    } catch (e) {
      print('Erreur lors de la sauvegarde du progrès vidéo: $e');
      throw Exception('Impossible de sauvegarder le progrès vidéo');
    }
  }

  /// Récupérer le progrès de lecture d'une vidéo
  Future<Map<String, dynamic>?> getVideoProgress({
    required int userId,
    required int videoId,
  }) async {
    try {
      final response = await _apiService.get('/video/progress/$userId/$videoId');
      return response.data;
    } catch (e) {
      print('Erreur lors de la récupération du progrès vidéo: $e');
      return null;
    }
  }

  /// Marquer une vidéo comme terminée
  Future<Map<String, dynamic>> markVideoAsCompleted({
    required int userId,
    required int videoId,
  }) async {
    try {
      final response = await _apiService.post(
        '/video/complete',
        data: {
          'user_id': userId,
          'video_id': videoId,
          'completed_at': DateTime.now().toIso8601String(),
        },
      );

      return response.data;
    } catch (e) {
      print('Erreur lors du marquage de la vidéo comme terminée: $e');
      throw Exception('Impossible de marquer la vidéo comme terminée');
    }
  }

  /// Rechercher des vidéos par mots-clés
  Future<List<dynamic>> searchVideos({
    required String query,
    int? categoryId,
    int? limit,
  }) async {
    try {
      final Map<String, dynamic> queryParams = {
        'q': query,
      };

      if (categoryId != null) {
        queryParams['category_id'] = categoryId.toString();
      }

      if (limit != null) {
        queryParams['limit'] = limit.toString();
      }

      final response = await _apiService.get(
        '/videos/search',
        queryParameters: queryParams,
      );

      return List<dynamic>.from(response.data);
    } catch (e) {
      print('Erreur lors de la recherche de vidéos: $e');
      throw Exception('Impossible de rechercher les vidéos');
    }
  }

  /// Télécharger une vidéo pour la lecture hors ligne (métadonnées seulement)
  Future<Map<String, dynamic>> prepareVideoForOffline({
    required int videoId,
    required String videoUrl,
  }) async {
    try {
      // Cette méthode prépare les métadonnées pour le téléchargement offline
      // Le téléchargement réel serait géré par un service de téléchargement séparé
      return {
        'video_id': videoId,
        'video_url': videoUrl,
        'download_prepared': true,
        'prepared_at': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      print('Erreur lors de la préparation du téléchargement: $e');
      throw Exception('Impossible de préparer le téléchargement');
    }
  }
}