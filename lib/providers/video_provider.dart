import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../models/course.dart';
import '../services/video_service.dart';

class VideoProvider with ChangeNotifier {
  final VideoService _videoService = VideoService();

  // État des catégories vidéo
  List<CourseCategory> _videoCategories = [];
  List<CourseCategory> _allVideoCategories = [];
  CourseCategory? _currentCategory;
  bool _isLoadingCategories = false;
  String? _categoriesError;

  // État des vidéos utilisateur
  List<Course> _userFormations = [];
  List<dynamic> _userExams = [];
  bool _isLoadingUserContent = false;
  String? _userContentError;

  // État de lecture vidéo
  Map<int, double> _videoProgress = {}; // videoId -> progress (0.0 à 1.0)
  Map<int, Duration> _watchedDurations = {}; // videoId -> watched duration
  Set<int> _completedVideos = {};
  bool _isTrackingProgress = false;

  // État de recherche
  List<Course> _searchResults = [];
  bool _isSearching = false;
  String? _searchError;
  String _lastSearchQuery = '';

  // État hors ligne
  Map<int, Map<String, dynamic>> _offlineVideos = {}; // videoId -> metadata
  bool _isDownloading = false;
  String? _downloadError;

  // Getters pour les catégories
  List<CourseCategory> get videoCategories => List.unmodifiable(_videoCategories);
  List<CourseCategory> get allVideoCategories => List.unmodifiable(_allVideoCategories);
  CourseCategory? get currentCategory => _currentCategory;
  bool get isLoadingCategories => _isLoadingCategories;
  String? get categoriesError => _categoriesError;
  bool get hasCategoriesError => _categoriesError != null;

  // Getters pour le contenu utilisateur
  List<Course> get userFormations => List.unmodifiable(_userFormations);
  List<dynamic> get userExams => List.unmodifiable(_userExams);
  bool get isLoadingUserContent => _isLoadingUserContent;
  String? get userContentError => _userContentError;
  bool get hasUserContentError => _userContentError != null;

  // Getters pour le progrès vidéo
  Map<int, double> get videoProgress => Map.unmodifiable(_videoProgress);
  Map<int, Duration> get watchedDurations => Map.unmodifiable(_watchedDurations);
  Set<int> get completedVideos => Set.unmodifiable(_completedVideos);
  bool get isTrackingProgress => _isTrackingProgress;

  // Getters pour la recherche
  List<Course> get searchResults => List.unmodifiable(_searchResults);
  bool get isSearching => _isSearching;
  String? get searchError => _searchError;
  bool get hasSearchError => _searchError != null;
  String get lastSearchQuery => _lastSearchQuery;

  // Getters pour hors ligne
  Map<int, Map<String, dynamic>> get offlineVideos => Map.unmodifiable(_offlineVideos);
  bool get isDownloading => _isDownloading;
  String? get downloadError => _downloadError;
  bool get hasDownloadError => _downloadError != null;

  /// Charger les catégories vidéo avec API réelle
  Future<void> loadVideoCategories({int? perPage}) async {
    _setLoadingCategories(true);
    _clearCategoriesError();

    try {
      final response = await _videoService.getVideoCategories(perPage: perPage);

      // Parser les catégories depuis la réponse
      // La réponse peut être structurée comme { "categories": { "current_page": 1, "data": [...] } } ou { "categories": [...] }
      List<dynamic> categoriesData = [];

      if (response['categories'] is Map<String, dynamic>) {
        // Structure avec pagination: { "categories": { "current_page": 1, "data": [...] } }
        final categoriesMap = response['categories'] as Map<String, dynamic>;
        if (categoriesMap['data'] is List) {
          categoriesData = categoriesMap['data'] as List;
        }
      } else if (response['categories'] is List) {
        // Structure directe: { "categories": [...] }
        categoriesData = response['categories'] as List;
      } else if (response['data'] is List) {
        // Structure alternative: { "data": [...] }
        categoriesData = response['data'] as List;
      }

      _videoCategories = categoriesData
          .map((item) => CourseCategory.fromJson(item as Map<String, dynamic>))
          .toList();
      _allVideoCategories = _videoCategories;

      notifyListeners();
    } catch (e) {
      _setCategoriesError('Impossible de charger les catégories: ${e.toString()}');
    } finally {
      _setLoadingCategories(false);
    }
  }

  /// Charger une catégorie spécifique par slug avec API réelle
  Future<void> loadCategoryBySlug(String slug) async {
    _setLoadingCategories(true);
    _clearCategoriesError();

    try {
      final response = await _videoService.getCategoryBySlug(slug);

      // Parser la catégorie depuis la réponse
      final categoryData = response['categorie'] ?? response['data'];
      if (categoryData != null) {
        _currentCategory = CourseCategory.fromJson(categoryData as Map<String, dynamic>);
      }
      notifyListeners();
    } catch (e) {
      _setCategoriesError('Impossible de charger la catégorie: ${e.toString()}');
    } finally {
      _setLoadingCategories(false);
    }
  }

  /// Charger le contenu utilisateur avec API réelle
  Future<void> loadUserContent(int userId) async {
    _setLoadingUserContent(true);
    _clearUserContentError();

    try {
      // Charger les formations utilisateur
      final formationsData = await _videoService.getUserFormations(userId);
      _userFormations = formationsData
          .map((item) => Course.fromJson(item as Map<String, dynamic>))
          .toList();

      // Charger les examens vidéothèque
      final examsData = await _videoService.getUserVideothequeExams(userId);
      _userExams = examsData;

      notifyListeners();
    } catch (e) {
      _setUserContentError('Impossible de charger le contenu utilisateur: ${e.toString()}');
    } finally {
      _setLoadingUserContent(false);
    }
  }

  /// Sauvegarder le progrès d'une vidéo avec synchronisation backend
  Future<bool> saveVideoProgress({
    required int userId,
    required int videoId,
    required double progress,
    required Duration watchedDuration,
    required Duration totalDuration,
  }) async {
    _isTrackingProgress = true;
    notifyListeners();

    try {
      // Sauvegarder sur le backend
      final response = await _videoService.saveVideoProgress(
        userId: userId,
        videoId: videoId,
        progress: progress,
        watchedDuration: watchedDuration,
        totalDuration: totalDuration,
      );

      // Vérifier le succès dans la réponse
      final success = response['success'] == true || response['error'] == false;

      if (success) {
        // Mettre à jour l'état local
        _videoProgress[videoId] = progress;
        _watchedDurations[videoId] = watchedDuration;

        // Marquer comme terminé si le progrès est de 90% ou plus
        if (progress >= 0.9) {
          _completedVideos.add(videoId);
        }

        notifyListeners();
      }

      return success;
    } catch (e) {
      debugPrint('Erreur lors de la sauvegarde du progrès: $e');
      // En cas d'erreur réseau, sauvegarder localement quand même
      _videoProgress[videoId] = progress;
      _watchedDurations[videoId] = watchedDuration;
      notifyListeners();
      return false;
    } finally {
      _isTrackingProgress = false;
      notifyListeners();
    }
  }

  /// Marquer une vidéo comme terminée avec synchronisation backend
  Future<bool> markVideoAsCompleted({
    required int userId,
    required int videoId,
  }) async {
    try {
      final response = await _videoService.markVideoAsCompleted(
        userId: userId,
        videoId: videoId,
      );

      // Vérifier le succès dans la réponse
      final success = response['success'] == true || response['error'] == false;

      if (success) {
        _completedVideos.add(videoId);
        _videoProgress[videoId] = 1.0;
        notifyListeners();
      }

      return success;
    } catch (e) {
      debugPrint('Erreur lors du marquage comme terminé: $e');
      // En cas d'erreur réseau, marquer localement quand même
      _completedVideos.add(videoId);
      _videoProgress[videoId] = 1.0;
      notifyListeners();
      return false;
    }
  }

  /// Charger le progrès d'une vidéo depuis le backend
  Future<void> loadVideoProgress(int userId, int videoId) async {
    try {
      final progressData = await _videoService.getVideoProgress(
        userId: userId,
        videoId: videoId,
      );

      if (progressData != null) {
        _videoProgress[videoId] = progressData['progress'] ?? 0.0;

        if (progressData['watchedDuration'] != null) {
          _watchedDurations[videoId] = Duration(
            seconds: (progressData['watchedDuration'] as num).toInt(),
          );
        }

        if ((progressData['progress'] ?? 0.0) >= 0.9) {
          _completedVideos.add(videoId);
        }

        notifyListeners();
      }
    } catch (e) {
      debugPrint('Erreur lors du chargement du progrès: $e');
    }
  }

  /// Obtenir le progrès d'une vidéo
  double getVideoProgress(int videoId) {
    return _videoProgress[videoId] ?? 0.0;
  }

  /// Vérifier si une vidéo est terminée
  bool isVideoCompleted(int videoId) {
    return _completedVideos.contains(videoId);
  }

  /// Rechercher des vidéos avec API réelle
  Future<void> searchVideos({
    required String query,
    int? categoryId,
    int? limit,
  }) async {
    if (query.trim().isEmpty) {
      _searchResults.clear();
      _lastSearchQuery = '';
      notifyListeners();
      return;
    }

    _setSearching(true);
    _clearSearchError();

    try {
      final resultsData = await _videoService.searchVideos(
        query: query,
        categoryId: categoryId,
        limit: limit,
      );

      // Parser les résultats de recherche
      _searchResults = resultsData
          .map((item) => Course.fromJson(item as Map<String, dynamic>))
          .toList();
      _lastSearchQuery = query;

      notifyListeners();
    } catch (e) {
      _setSearchError('Erreur lors de la recherche: ${e.toString()}');
    } finally {
      _setSearching(false);
    }
  }

  /// Vider les résultats de recherche
  void clearSearchResults() {
    _searchResults.clear();
    _lastSearchQuery = '';
    _clearSearchError();
    notifyListeners();
  }

  /// Préparer une vidéo pour la lecture hors ligne
  Future<bool> prepareVideoForOffline({
    required int videoId,
    required String videoUrl,
  }) async {
    _setDownloading(true);
    _clearDownloadError();

    try {
      final metadata = await _videoService.prepareVideoForOffline(
        videoId: videoId,
        videoUrl: videoUrl,
      );

      // metadata est déjà un Map<String, dynamic>
      _offlineVideos[videoId] = metadata;
      notifyListeners();
      return true;
    } catch (e) {
      _setDownloadError('Erreur lors de la préparation: ${e.toString()}');
      return false;
    } finally {
      _setDownloading(false);
    }
  }

  /// Vérifier si une vidéo est disponible hors ligne
  bool isVideoAvailableOffline(int videoId) {
    return _offlineVideos.containsKey(videoId);
  }

  /// Supprimer une vidéo hors ligne
  void removeOfflineVideo(int videoId) {
    _offlineVideos.remove(videoId);
    notifyListeners();
  }

  /// Actualiser toutes les données
  Future<void> refreshAll({int? userId, int? perPage}) async {
    await loadVideoCategories(perPage: perPage);
    if (userId != null) {
      await loadUserContent(userId);
    }
  }

  /// Vider toutes les données (lors de la déconnexion)
  void clearAllData() {
    _videoCategories.clear();
    _allVideoCategories.clear();
    _currentCategory = null;
    _userFormations.clear();
    _userExams.clear();
    _videoProgress.clear();
    _watchedDurations.clear();
    _completedVideos.clear();
    _searchResults.clear();
    _offlineVideos.clear();

    _clearCategoriesError();
    _clearUserContentError();
    _clearSearchError();
    _clearDownloadError();

    notifyListeners();
  }

  // Méthodes privées pour la gestion d'état
  void _setLoadingCategories(bool loading) {
    _isLoadingCategories = loading;
    notifyListeners();
  }

  void _setCategoriesError(String error) {
    _categoriesError = error;
    notifyListeners();
  }

  void _clearCategoriesError() {
    _categoriesError = null;
  }

  void _setLoadingUserContent(bool loading) {
    _isLoadingUserContent = loading;
    notifyListeners();
  }

  void _setUserContentError(String error) {
    _userContentError = error;
    notifyListeners();
  }

  void _clearUserContentError() {
    _userContentError = null;
  }

  void _setSearching(bool searching) {
    _isSearching = searching;
    notifyListeners();
  }

  void _setSearchError(String error) {
    _searchError = error;
    notifyListeners();
  }

  void _clearSearchError() {
    _searchError = null;
  }

  void _setDownloading(bool downloading) {
    _isDownloading = downloading;
    notifyListeners();
  }

  void _setDownloadError(String error) {
    _downloadError = error;
    notifyListeners();
  }

  void _clearDownloadError() {
    _downloadError = null;
  }
}
