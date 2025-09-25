import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:dio/dio.dart';

class CacheService {
  static const String _cachePrefix = 'insam_cache_';
  static const String _imagePrefix = 'insam_img_';
  static const String _videoPrefix = 'insam_video_';
  static const Duration _defaultCacheDuration = Duration(hours: 24);
  static const Duration _imageCacheDuration = Duration(days: 7);
  static const Duration _videoCacheDuration = Duration(days: 3);

  static late SharedPreferences _prefs;
  static late Directory _cacheDirectory;
  static late Directory _imageDirectory;
  static late Directory _videoDirectory;

  static Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    _cacheDirectory = await getTemporaryDirectory();

    _imageDirectory = Directory('${_cacheDirectory.path}/images');
    _videoDirectory = Directory('${_cacheDirectory.path}/videos');

    await _imageDirectory.create(recursive: true);
    await _videoDirectory.create(recursive: true);

    // Nettoyage automatique au démarrage
    await _cleanExpiredCache();
  }

  // ==================== DATA CACHING ====================

  static Future<void> cacheData(String key, Map<String, dynamic> data, {Duration? duration}) async {
    final cacheData = {
      'data': data,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'duration': (duration ?? _defaultCacheDuration).inMilliseconds,
    };

    await _prefs.setString('$_cachePrefix$key', jsonEncode(cacheData));
  }

  static Future<Map<String, dynamic>?> getCachedData(String key) async {
    final cachedString = _prefs.getString('$_cachePrefix$key');
    if (cachedString == null) return null;

    try {
      final cacheData = jsonDecode(cachedString) as Map<String, dynamic>;
      final timestamp = cacheData['timestamp'] as int;
      final duration = cacheData['duration'] as int;
      final expiry = DateTime.fromMillisecondsSinceEpoch(timestamp + duration);

      if (DateTime.now().isAfter(expiry)) {
        await removeCachedData(key);
        return null;
      }

      return cacheData['data'] as Map<String, dynamic>;
    } catch (e) {
      debugPrint('Erreur lors de la lecture du cache: $e');
      await removeCachedData(key);
      return null;
    }
  }

  static Future<void> removeCachedData(String key) async {
    await _prefs.remove('$_cachePrefix$key');
  }

  // ==================== IMAGE CACHING ====================

  static Future<String?> cacheImage(String url) async {
    try {
      final fileName = _generateFileName(url, 'jpg');
      final filePath = '${_imageDirectory.path}/$fileName';
      final file = File(filePath);

      // Vérifier si l'image existe déjà
      if (await file.exists()) {
        final stats = await file.stat();
        final age = DateTime.now().difference(stats.modified);

        if (age < _imageCacheDuration) {
          return filePath;
        }
      }

      // Télécharger l'image
      final dio = Dio();
      await dio.download(url, filePath);

      // Enregistrer les métadonnées
      await _saveImageMetadata(fileName, url);

      return filePath;
    } catch (e) {
      debugPrint('Erreur lors du cache de l\'image: $e');
      return null;
    }
  }

  static Future<String?> getCachedImagePath(String url) async {
    final fileName = _generateFileName(url, 'jpg');
    final filePath = '${_imageDirectory.path}/$fileName';
    final file = File(filePath);

    if (await file.exists()) {
      final stats = await file.stat();
      final age = DateTime.now().difference(stats.modified);

      if (age < _imageCacheDuration) {
        return filePath;
      } else {
        await file.delete();
        await _removeImageMetadata(fileName);
      }
    }

    return null;
  }

  static Future<void> _saveImageMetadata(String fileName, String url) async {
    final metadata = {
      'url': url,
      'fileName': fileName,
      'cachedAt': DateTime.now().toIso8601String(),
    };
    await _prefs.setString('$_imagePrefix$fileName', jsonEncode(metadata));
  }

  static Future<void> _removeImageMetadata(String fileName) async {
    await _prefs.remove('$_imagePrefix$fileName');
  }

  // ==================== VIDEO CACHING ====================

  static Future<String?> cacheVideo(String url) async {
    try {
      final fileName = _generateFileName(url, 'mp4');
      final filePath = '${_videoDirectory.path}/$fileName';
      final file = File(filePath);

      // Vérifier si la vidéo existe déjà
      if (await file.exists()) {
        final stats = await file.stat();
        final age = DateTime.now().difference(stats.modified);

        if (age < _videoCacheDuration) {
          return filePath;
        }
      }

      // Télécharger la vidéo (avec progress si nécessaire)
      final dio = Dio();
      await dio.download(
        url,
        filePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            final progress = (received / total * 100).toStringAsFixed(1);
            debugPrint('Téléchargement vidéo: $progress%');
          }
        },
      );

      // Enregistrer les métadonnées
      await _saveVideoMetadata(fileName, url);

      return filePath;
    } catch (e) {
      debugPrint('Erreur lors du cache de la vidéo: $e');
      return null;
    }
  }

  static Future<String?> getCachedVideoPath(String url) async {
    final fileName = _generateFileName(url, 'mp4');
    final filePath = '${_videoDirectory.path}/$fileName';
    final file = File(filePath);

    if (await file.exists()) {
      final stats = await file.stat();
      final age = DateTime.now().difference(stats.modified);

      if (age < _videoCacheDuration) {
        return filePath;
      } else {
        await file.delete();
        await _removeVideoMetadata(fileName);
      }
    }

    return null;
  }

  static Future<void> _saveVideoMetadata(String fileName, String url) async {
    final metadata = {
      'url': url,
      'fileName': fileName,
      'cachedAt': DateTime.now().toIso8601String(),
    };
    await _prefs.setString('$_videoPrefix$fileName', jsonEncode(metadata));
  }

  static Future<void> _removeVideoMetadata(String fileName) async {
    await _prefs.remove('$_videoPrefix$fileName');
  }

  // ==================== BACKGROUND SYNC ====================

  static Future<void> syncInBackground() async {
    try {
      // Synchroniser les données critiques en arrière-plan
      await _syncUserData();
      await _syncCourses();
      await _syncMessages();

      debugPrint('Synchronisation en arrière-plan terminée');
    } catch (e) {
      debugPrint('Erreur lors de la synchronisation: $e');
    }
  }

  static Future<void> _syncUserData() async {
    // Synchroniser les données utilisateur si elles sont anciennes
    const key = 'user_profile';
    final cachedData = await getCachedData(key);

    if (cachedData == null) {
      // Récupérer les données fraîches si pas de cache
      // TODO: Implémenter l'appel API
      debugPrint('Synchronisation profil utilisateur nécessaire');
    }
  }

  static Future<void> _syncCourses() async {
    // Synchroniser la liste des cours
    const key = 'courses_list';
    final cachedData = await getCachedData(key);

    if (cachedData == null) {
      // TODO: Implémenter l'appel API
      debugPrint('Synchronisation cours nécessaire');
    }
  }

  static Future<void> _syncMessages() async {
    // Synchroniser les messages récents
    const key = 'recent_messages';
    final cachedData = await getCachedData(key);

    if (cachedData == null) {
      // TODO: Implémenter l'appel API
      debugPrint('Synchronisation messages nécessaire');
    }
  }

  // ==================== CACHE MANAGEMENT ====================

  static Future<void> _cleanExpiredCache() async {
    // Nettoyer les données expirées
    final keys = _prefs.getKeys();
    final dataKeys = keys.where((key) => key.startsWith(_cachePrefix));

    for (final key in dataKeys) {
      await getCachedData(key.substring(_cachePrefix.length));
    }

    // Nettoyer les images expirées
    await _cleanExpiredImages();

    // Nettoyer les vidéos expirées
    await _cleanExpiredVideos();
  }

  static Future<void> _cleanExpiredImages() async {
    final files = await _imageDirectory.list().toList();

    for (final file in files) {
      if (file is File) {
        final stats = await file.stat();
        final age = DateTime.now().difference(stats.modified);

        if (age > _imageCacheDuration) {
          await file.delete();
          final fileName = file.path.split('/').last;
          await _removeImageMetadata(fileName);
        }
      }
    }
  }

  static Future<void> _cleanExpiredVideos() async {
    final files = await _videoDirectory.list().toList();

    for (final file in files) {
      if (file is File) {
        final stats = await file.stat();
        final age = DateTime.now().difference(stats.modified);

        if (age > _videoCacheDuration) {
          await file.delete();
          final fileName = file.path.split('/').last;
          await _removeVideoMetadata(fileName);
        }
      }
    }
  }

  static Future<void> clearAllCache() async {
    // Supprimer toutes les données en cache
    final keys = _prefs.getKeys();
    final cacheKeys = keys.where((key) =>
        key.startsWith(_cachePrefix) ||
        key.startsWith(_imagePrefix) ||
        key.startsWith(_videoPrefix)
    );

    for (final key in cacheKeys) {
      await _prefs.remove(key);
    }

    // Supprimer tous les fichiers
    if (await _imageDirectory.exists()) {
      await _imageDirectory.delete(recursive: true);
      await _imageDirectory.create(recursive: true);
    }

    if (await _videoDirectory.exists()) {
      await _videoDirectory.delete(recursive: true);
      await _videoDirectory.create(recursive: true);
    }
  }

  static Future<Map<String, dynamic>> getCacheStats() async {
    final keys = _prefs.getKeys();
    final dataCache = keys.where((key) => key.startsWith(_cachePrefix)).length;
    final imageCache = keys.where((key) => key.startsWith(_imagePrefix)).length;
    final videoCache = keys.where((key) => key.startsWith(_videoPrefix)).length;

    // Calculer la taille des fichiers
    int imageSize = 0;
    int videoSize = 0;

    if (await _imageDirectory.exists()) {
      final imageFiles = await _imageDirectory.list().toList();
      for (final file in imageFiles) {
        if (file is File) {
          final stats = await file.stat();
          imageSize += stats.size;
        }
      }
    }

    if (await _videoDirectory.exists()) {
      final videoFiles = await _videoDirectory.list().toList();
      for (final file in videoFiles) {
        if (file is File) {
          final stats = await file.stat();
          videoSize += stats.size;
        }
      }
    }

    return {
      'dataCacheCount': dataCache,
      'imageCacheCount': imageCache,
      'videoCacheCount': videoCache,
      'imageSizeMB': (imageSize / (1024 * 1024)).toStringAsFixed(2),
      'videoSizeMB': (videoSize / (1024 * 1024)).toStringAsFixed(2),
      'totalSizeMB': ((imageSize + videoSize) / (1024 * 1024)).toStringAsFixed(2),
    };
  }

  // ==================== UTILITIES ====================

  static String _generateFileName(String url, String extension) {
    return '${url.hashCode.abs()}.$extension';
  }

  static Future<bool> isOnline() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  // ==================== SMART INVALIDATION ====================

  static Future<void> invalidateUserCache() async {
    await removeCachedData('user_profile');
    await removeCachedData('user_courses');
    await removeCachedData('user_progress');
  }

  static Future<void> invalidateCourseCache(String courseId) async {
    await removeCachedData('course_$courseId');
    await removeCachedData('course_modules_$courseId');
    await removeCachedData('course_progress_$courseId');
  }

  static Future<void> invalidateMessageCache() async {
    await removeCachedData('conversations');
    await removeCachedData('recent_messages');
  }
}