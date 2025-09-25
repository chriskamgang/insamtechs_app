import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';

class OfflineDownloadService {
  static final OfflineDownloadService _instance = OfflineDownloadService._internal();
  factory OfflineDownloadService() => _instance;
  OfflineDownloadService._internal();

  // Cache sécurisé pour les contenus téléchargés
  final Map<String, DownloadItem> _downloads = {};
  final Map<String, double> _downloadProgress = {};

  // Limites de stockage (comme Netflix)
  static const int maxDownloadSizeInMB = 2048; // 2GB max
  static const int maxDownloadsPerUser = 50;
  static const int maxDaysOffline = 30; // Expire après 30 jours

  // Getters
  Map<String, DownloadItem> get downloads => Map.unmodifiable(_downloads);
  Map<String, double> get downloadProgress => Map.unmodifiable(_downloadProgress);

  /// Télécharger une vidéo de cours pour lecture offline
  Future<bool> downloadCourseVideo({
    required String videoId,
    required String title,
    required String videoUrl,
    required String quality,
    Function(double)? onProgress,
  }) async {
    try {
      // Vérifier les limites
      if (!_canDownload()) {
        throw Exception('Limite de téléchargements atteinte');
      }

      // Générer un nom de fichier sécurisé
      final fileName = _generateSecureFileName(videoId, 'video');
      final filePath = await _getSecureFilePath(fileName);

      // Créer l'élément de téléchargement
      final downloadItem = DownloadItem(
        id: videoId,
        title: title,
        type: DownloadType.video,
        originalUrl: videoUrl,
        localPath: filePath,
        quality: quality,
        downloadedAt: DateTime.now(),
        size: 0,
        isEncrypted: true,
      );

      _downloads[videoId] = downloadItem;
      _downloadProgress[videoId] = 0.0;

      // Simuler le téléchargement avec chiffrement
      await _downloadWithEncryption(
        url: videoUrl,
        filePath: filePath,
        videoId: videoId,
        onProgress: (progress) {
          _downloadProgress[videoId] = progress;
          onProgress?.call(progress);
        },
      );

      // Marquer comme terminé
      downloadItem.size = await _getFileSize(filePath);
      downloadItem.isCompleted = true;
      _downloadProgress.remove(videoId);

      return true;
    } catch (e) {
      _downloads.remove(videoId);
      _downloadProgress.remove(videoId);
      debugPrint('Erreur téléchargement vidéo: $e');
      return false;
    }
  }

  /// Télécharger un PDF pour lecture offline
  Future<bool> downloadPDF({
    required String pdfId,
    required String title,
    required String pdfUrl,
    Function(double)? onProgress,
  }) async {
    try {
      if (!_canDownload()) {
        throw Exception('Limite de téléchargements atteinte');
      }

      final fileName = _generateSecureFileName(pdfId, 'pdf');
      final filePath = await _getSecureFilePath(fileName);

      final downloadItem = DownloadItem(
        id: pdfId,
        title: title,
        type: DownloadType.pdf,
        originalUrl: pdfUrl,
        localPath: filePath,
        quality: 'original',
        downloadedAt: DateTime.now(),
        size: 0,
        isEncrypted: true,
      );

      _downloads[pdfId] = downloadItem;
      _downloadProgress[pdfId] = 0.0;

      await _downloadWithEncryption(
        url: pdfUrl,
        filePath: filePath,
        videoId: pdfId,
        onProgress: (progress) {
          _downloadProgress[pdfId] = progress;
          onProgress?.call(progress);
        },
      );

      downloadItem.size = await _getFileSize(filePath);
      downloadItem.isCompleted = true;
      _downloadProgress.remove(pdfId);

      return true;
    } catch (e) {
      _downloads.remove(pdfId);
      _downloadProgress.remove(pdfId);
      debugPrint('Erreur téléchargement PDF: $e');
      return false;
    }
  }

  /// Vérifier si un contenu est téléchargé
  bool isDownloaded(String contentId) {
    return _downloads.containsKey(contentId) &&
           _downloads[contentId]!.isCompleted;
  }

  /// Obtenir le chemin local sécurisé d'un contenu
  String? getLocalPath(String contentId) {
    if (isDownloaded(contentId)) {
      return _downloads[contentId]!.localPath;
    }
    return null;
  }

  /// Supprimer un téléchargement
  Future<bool> removeDownload(String contentId) async {
    try {
      final download = _downloads[contentId];
      if (download != null) {
        // Supprimer le fichier
        final file = File(download.localPath);
        if (await file.exists()) {
          await file.delete();
        }
        _downloads.remove(contentId);
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Erreur suppression téléchargement: $e');
      return false;
    }
  }

  /// Nettoyer les téléchargements expirés
  Future<void> cleanExpiredDownloads() async {
    final now = DateTime.now();
    final expiredKeys = <String>[];

    for (final entry in _downloads.entries) {
      final daysSinceDownload = now.difference(entry.value.downloadedAt).inDays;
      if (daysSinceDownload > maxDaysOffline) {
        expiredKeys.add(entry.key);
      }
    }

    for (final key in expiredKeys) {
      await removeDownload(key);
    }
  }

  /// Obtenir l'espace de stockage utilisé
  Future<int> getUsedStorageInMB() async {
    int totalSize = 0;
    for (final download in _downloads.values) {
      totalSize += download.size;
    }
    return (totalSize / (1024 * 1024)).round();
  }

  /// Obtenir les statistiques de téléchargements
  Map<String, dynamic> getDownloadStats() {
    final videos = _downloads.values.where((d) => d.type == DownloadType.video).length;
    final pdfs = _downloads.values.where((d) => d.type == DownloadType.pdf).length;

    return {
      'total_downloads': _downloads.length,
      'videos_count': videos,
      'pdfs_count': pdfs,
      'storage_used_mb': getUsedStorageInMB(),
      'max_storage_mb': maxDownloadSizeInMB,
      'max_downloads': maxDownloadsPerUser,
    };
  }

  /// Lister tous les téléchargements par type
  List<DownloadItem> getDownloadsByType(DownloadType type) {
    return _downloads.values
        .where((download) => download.type == type && download.isCompleted)
        .toList()
      ..sort((a, b) => b.downloadedAt.compareTo(a.downloadedAt));
  }

  // Méthodes privées

  bool _canDownload() {
    return _downloads.length < maxDownloadsPerUser;
  }

  String _generateSecureFileName(String contentId, String type) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final hash = contentId.hashCode.toString();
    return '${type}_${timestamp}_${hash.substring(0, 8)}.secure';
  }

  Future<String> _getSecureFilePath(String fileName) async {
    // Utilise le répertoire de documents de l'application (privé)
    final directory = Directory('/data/data/com.insam.lms/app_flutter/offline');
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }
    return '${directory.path}/$fileName';
  }

  Future<void> _downloadWithEncryption({
    required String url,
    required String filePath,
    required String videoId,
    required Function(double) onProgress,
  }) async {
    // Simulation d'un téléchargement avec chiffrement
    // En réalité, ici on téléchargerait le fichier et on le chiffrerait

    for (int i = 0; i <= 100; i += 5) {
      await Future.delayed(const Duration(milliseconds: 100));
      onProgress(i / 100.0);
    }

    // Créer un fichier simulé chiffré
    final file = File(filePath);
    final fakeEncryptedData = utf8.encode('ENCRYPTED_CONTENT_$videoId');
    await file.writeAsBytes(fakeEncryptedData);
  }

  Future<int> _getFileSize(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        return await file.length();
      }
      return 0;
    } catch (e) {
      return 0;
    }
  }
}

// Modèles de données

enum DownloadType {
  video,
  pdf,
}

class DownloadItem {
  final String id;
  final String title;
  final DownloadType type;
  final String originalUrl;
  final String localPath;
  final String quality;
  final DateTime downloadedAt;
  int size;
  bool isCompleted;
  final bool isEncrypted;

  DownloadItem({
    required this.id,
    required this.title,
    required this.type,
    required this.originalUrl,
    required this.localPath,
    required this.quality,
    required this.downloadedAt,
    required this.size,
    this.isCompleted = false,
    this.isEncrypted = true,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'type': type.toString(),
      'originalUrl': originalUrl,
      'localPath': localPath,
      'quality': quality,
      'downloadedAt': downloadedAt.toIso8601String(),
      'size': size,
      'isCompleted': isCompleted,
      'isEncrypted': isEncrypted,
    };
  }
}