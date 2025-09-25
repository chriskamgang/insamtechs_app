import 'package:flutter/foundation.dart';

class VideoCacheService {
  static final VideoCacheService _instance = VideoCacheService._internal();
  factory VideoCacheService() => _instance;
  VideoCacheService._internal();

  // Cache pour les métadonnées des vidéos
  final Map<String, Map<String, dynamic>> _videoMetadataCache = {};

  // Cache pour les données de progression
  final Map<String, Map<String, dynamic>> _progressCache = {};

  // Cache pour les informations de qualité vidéo
  final Map<String, List<Map<String, dynamic>>> _qualityCache = {};

  // Cache pour les chapitres et leur contenu
  final Map<String, List<Map<String, dynamic>>> _chaptersCache = {};

  // Gestion de la taille du cache
  static const int maxCacheSize = 100; // Limite du nombre d'éléments en cache
  final List<String> _accessOrder = []; // Pour LRU (Least Recently Used)

  /// Mettre en cache les métadonnées d'une vidéo
  void cacheVideoMetadata(String videoId, Map<String, dynamic> metadata) {
    _ensureCacheLimit();
    _videoMetadataCache[videoId] = Map<String, dynamic>.from(metadata);
    _updateAccessOrder(videoId);
  }

  /// Récupérer les métadonnées d'une vidéo depuis le cache
  Map<String, dynamic>? getVideoMetadata(String videoId) {
    if (_videoMetadataCache.containsKey(videoId)) {
      _updateAccessOrder(videoId);
      return Map<String, dynamic>.from(_videoMetadataCache[videoId]!);
    }
    return null;
  }

  /// Mettre en cache le progrès de lecture d'une vidéo
  void cacheVideoProgress({
    required String videoId,
    required double progress,
    required Duration watchedDuration,
    required Duration totalDuration,
    required DateTime lastWatched,
  }) {
    _progressCache[videoId] = {
      'progress': progress,
      'watched_duration': watchedDuration.inSeconds,
      'total_duration': totalDuration.inSeconds,
      'last_watched': lastWatched.toIso8601String(),
      'cached_at': DateTime.now().toIso8601String(),
    };
    _updateAccessOrder(videoId);
  }

  /// Récupérer le progrès de lecture d'une vidéo
  Map<String, dynamic>? getVideoProgress(String videoId) {
    if (_progressCache.containsKey(videoId)) {
      _updateAccessOrder(videoId);
      return Map<String, dynamic>.from(_progressCache[videoId]!);
    }
    return null;
  }

  /// Mettre en cache les qualités disponibles pour une vidéo
  void cacheVideoQualities(String videoId, List<Map<String, dynamic>> qualities) {
    _ensureCacheLimit();
    _qualityCache[videoId] = List<Map<String, dynamic>>.from(qualities);
    _updateAccessOrder(videoId);
  }

  /// Récupérer les qualités disponibles pour une vidéo
  List<Map<String, dynamic>>? getVideoQualities(String videoId) {
    if (_qualityCache.containsKey(videoId)) {
      _updateAccessOrder(videoId);
      return List<Map<String, dynamic>>.from(_qualityCache[videoId]!);
    }
    return null;
  }

  /// Mettre en cache les chapitres d'un cours
  void cacheCourseChapters(String courseId, List<Map<String, dynamic>> chapters) {
    _ensureCacheLimit();
    _chaptersCache[courseId] = List<Map<String, dynamic>>.from(chapters);
    _updateAccessOrder(courseId);
  }

  /// Récupérer les chapitres d'un cours
  List<Map<String, dynamic>>? getCourseChapters(String courseId) {
    if (_chaptersCache.containsKey(courseId)) {
      _updateAccessOrder(courseId);
      return List<Map<String, dynamic>>.from(_chaptersCache[courseId]!);
    }
    return null;
  }

  /// Vérifier si une vidéo est en cache
  bool isVideoCached(String videoId) {
    return _videoMetadataCache.containsKey(videoId);
  }

  /// Vérifier si le progrès d'une vidéo est en cache
  bool isProgressCached(String videoId) {
    return _progressCache.containsKey(videoId);
  }

  /// Obtenir la taille actuelle du cache
  int getCacheSize() {
    return _videoMetadataCache.length +
           _progressCache.length +
           _qualityCache.length +
           _chaptersCache.length;
  }

  /// Obtenir des statistiques de cache
  Map<String, dynamic> getCacheStats() {
    return {
      'video_metadata_count': _videoMetadataCache.length,
      'progress_count': _progressCache.length,
      'quality_count': _qualityCache.length,
      'chapters_count': _chaptersCache.length,
      'total_items': getCacheSize(),
      'max_cache_size': maxCacheSize,
      'cache_hit_order': List<String>.from(_accessOrder),
    };
  }

  /// Effacer le cache d'une vidéo spécifique
  void clearVideoCache(String videoId) {
    _videoMetadataCache.remove(videoId);
    _progressCache.remove(videoId);
    _qualityCache.remove(videoId);
    _accessOrder.remove(videoId);
  }

  /// Effacer le cache d'un cours spécifique
  void clearCourseCache(String courseId) {
    _chaptersCache.remove(courseId);
    _accessOrder.remove(courseId);
  }

  /// Effacer tout le cache
  void clearAllCache() {
    _videoMetadataCache.clear();
    _progressCache.clear();
    _qualityCache.clear();
    _chaptersCache.clear();
    _accessOrder.clear();
  }

  /// Effacer le cache expiré (plus de 24h)
  void clearExpiredCache() {
    final now = DateTime.now();
    final expiredKeys = <String>[];

    // Vérifier les métadonnées expirées
    _videoMetadataCache.forEach((key, value) {
      if (value['cached_at'] != null) {
        final cachedAt = DateTime.parse(value['cached_at']);
        if (now.difference(cachedAt).inHours > 24) {
          expiredKeys.add(key);
        }
      }
    });

    // Vérifier le progrès expiré (garde plus longtemps - 7 jours)
    _progressCache.forEach((key, value) {
      if (value['cached_at'] != null) {
        final cachedAt = DateTime.parse(value['cached_at']);
        if (now.difference(cachedAt).inDays > 7) {
          expiredKeys.add(key);
        }
      }
    });

    // Supprimer les éléments expirés
    for (final key in expiredKeys) {
      clearVideoCache(key);
    }
  }

  /// Précharger les données d'un cours pour optimiser les performances
  Future<void> preloadCourseData({
    required String courseId,
    required List<Map<String, dynamic>> chapters,
    required Map<String, dynamic> courseMetadata,
  }) async {
    // Mettre en cache les métadonnées du cours
    cacheVideoMetadata(courseId, courseMetadata);

    // Mettre en cache les chapitres
    cacheCourseChapters(courseId, chapters);

    // Précharger les métadonnées des vidéos du cours
    for (final chapter in chapters) {
      final videos = chapter['videos'] as List<dynamic>? ?? [];
      for (final video in videos) {
        final videoId = video['id']?.toString() ?? '';
        if (videoId.isNotEmpty) {
          cacheVideoMetadata(videoId, Map<String, dynamic>.from(video));
        }
      }
    }
  }

  /// Récupérer les vidéos récemment regardées (basé sur le cache de progrès)
  List<Map<String, dynamic>> getRecentlyWatchedVideos({int limit = 10}) {
    final recentVideos = <Map<String, dynamic>>[];

    final sortedEntries = _progressCache.entries.toList()
      ..sort((a, b) {
        final aTime = DateTime.parse(a.value['last_watched']);
        final bTime = DateTime.parse(b.value['last_watched']);
        return bTime.compareTo(aTime); // Plus récent en premier
      });

    for (final entry in sortedEntries.take(limit)) {
      final videoId = entry.key;
      final progressData = entry.value;
      final metadata = getVideoMetadata(videoId);

      if (metadata != null) {
        recentVideos.add({
          'video_id': videoId,
          'metadata': metadata,
          'progress': progressData,
        });
      }
    }

    return recentVideos;
  }

  /// Méthodes privées pour la gestion du cache

  void _ensureCacheLimit() {
    while (getCacheSize() >= maxCacheSize && _accessOrder.isNotEmpty) {
      final oldestKey = _accessOrder.removeAt(0);
      _videoMetadataCache.remove(oldestKey);
      _progressCache.remove(oldestKey);
      _qualityCache.remove(oldestKey);
      _chaptersCache.remove(oldestKey);
    }
  }

  void _updateAccessOrder(String key) {
    _accessOrder.remove(key);
    _accessOrder.add(key);
  }

  /// Optimiser la mémoire en compressant les données si nécessaire
  void optimizeMemoryUsage() {
    // Effacer le cache expiré
    clearExpiredCache();

    // Si on dépasse encore la limite, effacer les moins utilisés
    while (getCacheSize() > maxCacheSize * 0.8 && _accessOrder.isNotEmpty) {
      final oldestKey = _accessOrder.removeAt(0);
      clearVideoCache(oldestKey);
    }
  }

  /// Debug: Afficher les informations de cache
  void debugPrintCacheInfo() {
    if (kDebugMode) {
      final stats = getCacheStats();
      print('=== Video Cache Stats ===');
      print('Video metadata: ${stats['video_metadata_count']}');
      print('Progress entries: ${stats['progress_count']}');
      print('Quality entries: ${stats['quality_count']}');
      print('Chapter entries: ${stats['chapters_count']}');
      print('Total items: ${stats['total_items']}/${stats['max_cache_size']}');
      print('Recent access: ${stats['cache_hit_order'].take(5).toList()}');
    }
  }
}