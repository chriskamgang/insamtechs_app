import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../data/mock_data.dart';
import '../models/course.dart';

class VideoProvider with ChangeNotifier {

  // État des catégories vidéo
  List<CourseCategory> _videoCategories = [];
  List<CourseCategory> _allVideoCategories = [];
  Map<String, dynamic>? _currentCategory;
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
  Map<String, dynamic>? get currentCategory => _currentCategory;
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

  /// Charger les catégories vidéo
  Future<void> loadVideoCategories({int? perPage}) async {
    _setLoadingCategories(true);
    _clearCategoriesError();

    try {
      await Future.delayed(const Duration(milliseconds: 300));

      final categories = MockData.getMockCategories();
      _videoCategories = categories.take(perPage ?? categories.length).toList();
      _allVideoCategories = categories;

      notifyListeners();
    } catch (e) {
      _setCategoriesError('Impossible de charger les catégories: \${e.toString()}');
    } finally {
      _setLoadingCategories(false);
    }
  }

  /// Charger une catégorie spécifique
  Future<void> loadCategoryBySlug(String slug) async {
    _setLoadingCategories(true);
    _clearCategoriesError();

    try {
      await Future.delayed(const Duration(milliseconds: 300));

      final categories = MockData.getMockCategories();
      final category = categories.firstWhere(
        (cat) => cat.slug == slug,
        orElse: () => categories.first,
      );
      _currentCategory = {
        'id': category.id,
        'intitule': category.intitule,
        'slug': category.slug,
        'type': category.type,
        'date': category.date,
      };
      notifyListeners();
    } catch (e) {
      _setCategoriesError('Impossible de charger la catégorie: \${e.toString()}');
    } finally {
      _setLoadingCategories(false);
    }
  }

  /// Charger le contenu utilisateur
  Future<void> loadUserContent(int userId) async {
    _setLoadingUserContent(true);
    _clearUserContentError();

    try {
      await Future.delayed(const Duration(milliseconds: 300));

      // Mock user formations - just return first few courses
      final courses = MockData.getMockCourses();
      _userFormations = courses.take(3).toList();
      _userExams = []; // Mock empty exams

      notifyListeners();
    } catch (e) {
      _setUserContentError('Impossible de charger le contenu utilisateur: \${e.toString()}');
    } finally {
      _setLoadingUserContent(false);
    }
  }

  /// Sauvegarder le progrès d'une vidéo (mock implementation)
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
      await Future.delayed(const Duration(milliseconds: 200));

      // Mettre à jour l'état local
      _videoProgress[videoId] = progress;
      _watchedDurations[videoId] = watchedDuration;

      // Marquer comme terminé si le progrès est de 90% ou plus
      if (progress >= 0.9) {
        _completedVideos.add(videoId);
      }

      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Erreur lors de la sauvegarde du progrès: \$e');
      return false;
    } finally {
      _isTrackingProgress = false;
      notifyListeners();
    }
  }

  /// Marquer une vidéo comme terminée (mock implementation)
  Future<bool> markVideoAsCompleted({
    required int userId,
    required int videoId,
  }) async {
    try {
      await Future.delayed(const Duration(milliseconds: 200));

      _completedVideos.add(videoId);
      _videoProgress[videoId] = 1.0;

      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Erreur lors du marquage comme terminé: \$e');
      return false;
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

  /// Rechercher des vidéos
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
      await Future.delayed(const Duration(milliseconds: 300));

      final results = MockData.searchCourses(query);
      _searchResults = results.take(limit ?? results.length).toList();
      _lastSearchQuery = query;

      notifyListeners();
    } catch (e) {
      _setSearchError('Erreur lors de la recherche: \${e.toString()}');
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

  /// Préparer une vidéo pour la lecture hors ligne (mock implementation)
  Future<bool> prepareVideoForOffline({
    required int videoId,
    required String videoUrl,
  }) async {
    _setDownloading(true);
    _clearDownloadError();

    try {
      await Future.delayed(const Duration(seconds: 2)); // Simulate download

      _offlineVideos[videoId] = {
        'id': videoId,
        'url': videoUrl,
        'downloaded_at': DateTime.now().toIso8601String(),
        'size_mb': 25.5, // Mock size
      };

      notifyListeners();
      return true;
    } catch (e) {
      _setDownloadError('Erreur lors de la préparation: \${e.toString()}');
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