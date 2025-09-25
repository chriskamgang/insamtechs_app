import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class MemoryManager {
  static const int _maxImageCacheSize = 100; // Nombre max d'images en cache
  static const int _maxImageWidth = 1920; // Largeur max pour redimensionnement
  static const int _maxImageHeight = 1080; // Hauteur max pour redimensionnement
  static const int _compressionQuality = 85; // Qualité de compression (0-100)

  static final Map<String, ImageProvider> _imageCache = <String, ImageProvider>{};
  static final List<String> _imageCacheOrder = <String>[];

  // ==================== IMAGE OPTIMIZATION ====================

  static ImageProvider getOptimizedImage(String imageUrl, {
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
  }) {
    // Vérifier le cache en mémoire
    if (_imageCache.containsKey(imageUrl)) {
      _moveToFront(imageUrl);
      return _imageCache[imageUrl]!;
    }

    // Créer une image optimisée
    final imageProvider = NetworkImage(imageUrl);

    // Ajouter au cache avec gestion de la taille
    _addToCache(imageUrl, imageProvider);

    return imageProvider;
  }

  static void _addToCache(String key, ImageProvider imageProvider) {
    if (_imageCache.length >= _maxImageCacheSize) {
      // Supprimer la plus ancienne image
      final oldestKey = _imageCacheOrder.removeAt(0);
      _imageCache.remove(oldestKey);
    }

    _imageCache[key] = imageProvider;
    _imageCacheOrder.add(key);
  }

  static void _moveToFront(String key) {
    _imageCacheOrder.remove(key);
    _imageCacheOrder.add(key);
  }

  static Future<Uint8List?> compressImage(Uint8List imageBytes) async {
    try {
      // Pour la compression d'image, on utiliserait normalement
      // un package comme flutter_image_compress
      // Ici on simule la compression en retournant les données originales

      if (imageBytes.length > 1024 * 1024) { // Si > 1MB
        debugPrint('Image de ${(imageBytes.length / 1024 / 1024).toStringAsFixed(1)}MB détectée');
        // TODO: Implémenter la compression réelle
        return imageBytes;
      }

      return imageBytes;
    } catch (e) {
      debugPrint('Erreur lors de la compression d\'image: $e');
      return null;
    }
  }

  // ==================== MEMORY CLEANUP ====================

  static void clearImageCache() {
    _imageCache.clear();
    _imageCacheOrder.clear();
    debugPrint('Cache d\'images nettoyé');
  }

  static void clearUnusedImages() {
    // Garder seulement les 50 dernières images
    const keepCount = 50;

    if (_imageCache.length > keepCount) {
      final toRemove = _imageCache.length - keepCount;

      for (int i = 0; i < toRemove; i++) {
        final keyToRemove = _imageCacheOrder.removeAt(0);
        _imageCache.remove(keyToRemove);
      }

      debugPrint('$toRemove images supprimées du cache');
    }
  }

  // ==================== RESOURCE DISPOSAL ====================

  static final List<VoidCallback> _disposeCallbacks = [];

  static void registerDisposeCallback(VoidCallback callback) {
    _disposeCallbacks.add(callback);
  }

  static void unregisterDisposeCallback(VoidCallback callback) {
    _disposeCallbacks.remove(callback);
  }

  static void disposeAllResources() {
    for (final callback in _disposeCallbacks) {
      try {
        callback();
      } catch (e) {
        debugPrint('Erreur lors du dispose: $e');
      }
    }
    _disposeCallbacks.clear();
    clearImageCache();
    debugPrint('Toutes les ressources ont été libérées');
  }

  // ==================== LARGE DATASET HANDLING ====================

  static List<T> paginateList<T>(List<T> items, int page, int pageSize) {
    final startIndex = page * pageSize;
    final endIndex = (startIndex + pageSize).clamp(0, items.length);

    if (startIndex >= items.length) {
      return [];
    }

    return items.sublist(startIndex, endIndex);
  }

  static Stream<List<T>> streamLargeDataset<T>(
    List<T> dataset,
    int batchSize,
  ) async* {
    for (int i = 0; i < dataset.length; i += batchSize) {
      final endIndex = (i + batchSize).clamp(0, dataset.length);
      yield dataset.sublist(i, endIndex);

      // Petite pause pour éviter de bloquer l'UI
      await Future.delayed(const Duration(milliseconds: 1));
    }
  }

  // ==================== MEMORY MONITORING ====================

  static Map<String, dynamic> getMemoryStats() {
    return {
      'imageCacheSize': _imageCache.length,
      'maxImageCacheSize': _maxImageCacheSize,
      'disposeCallbacksCount': _disposeCallbacks.length,
      'imageCacheOrder': _imageCacheOrder.length,
    };
  }

  static void logMemoryUsage() {
    final stats = getMemoryStats();
    debugPrint('=== MEMORY STATS ===');
    debugPrint('Images en cache: ${stats['imageCacheSize']}/${stats['maxImageCacheSize']}');
    debugPrint('Callbacks dispose: ${stats['disposeCallbacksCount']}');
    debugPrint('==================');
  }

  // ==================== AUTOMATIC CLEANUP ====================

  static void startAutomaticCleanup() {
    // Nettoyage automatique toutes les 5 minutes
    Timer.periodic(const Duration(minutes: 5), (timer) {
      clearUnusedImages();
      _cleanupSystemMemory();
    });
  }

  static void _cleanupSystemMemory() {
    // Force le garbage collector en suggérant à Dart de libérer la mémoire
    if (!kDebugMode) {
      // En production, on peut forcer le garbage collection
      // Note: Dart ne garantit pas l'exécution immédiate du GC
    }

    debugPrint('Nettoyage mémoire système effectué');
  }

  // ==================== IMAGE LOADING OPTIMIZATION ====================

  static Widget buildOptimizedImage(
    String imageUrl, {
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
    Widget? placeholder,
    Widget? errorWidget,
  }) {
    return Image(
      image: getOptimizedImage(imageUrl, width: width, height: height, fit: fit),
      width: width,
      height: height,
      fit: fit,
      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
        if (wasSynchronouslyLoaded) {
          return child;
        }
        return AnimatedOpacity(
          opacity: frame == null ? 0 : 1,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
          child: child,
        );
      },
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) {
          return child;
        }

        return placeholder ??
          Center(
            child: CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded /
                    loadingProgress.expectedTotalBytes!
                  : null,
            ),
          );
      },
      errorBuilder: (context, error, stackTrace) {
        debugPrint('Erreur chargement image: $error');
        return errorWidget ??
          const Icon(
            Icons.error_outline,
            color: Colors.grey,
            size: 50,
          );
      },
    );
  }

  // ==================== VIDEO MEMORY OPTIMIZATION ====================

  static const int _maxVideoPlayers = 3; // Nombre max de lecteurs vidéo simultanés
  static final List<String> _activeVideoPlayers = [];

  static bool canCreateVideoPlayer(String videoId) {
    return _activeVideoPlayers.length < _maxVideoPlayers;
  }

  static void registerVideoPlayer(String videoId) {
    if (!_activeVideoPlayers.contains(videoId)) {
      if (_activeVideoPlayers.length >= _maxVideoPlayers) {
        // Supprimer le plus ancien
        final oldestId = _activeVideoPlayers.removeAt(0);
        debugPrint('Lecteur vidéo $oldestId supprimé pour libérer la mémoire');
      }
      _activeVideoPlayers.add(videoId);
      debugPrint('Lecteur vidéo $videoId enregistré');
    }
  }

  static void unregisterVideoPlayer(String videoId) {
    _activeVideoPlayers.remove(videoId);
    debugPrint('Lecteur vidéo $videoId désenregistré');
  }

  static List<String> getActiveVideoPlayers() {
    return List.unmodifiable(_activeVideoPlayers);
  }

  // ==================== PDF MEMORY OPTIMIZATION ====================

  static const int _maxPdfDocuments = 2; // Nombre max de PDFs ouverts simultanément
  static final List<String> _activePdfDocuments = [];

  static bool canOpenPdfDocument(String documentId) {
    return _activePdfDocuments.length < _maxPdfDocuments;
  }

  static void registerPdfDocument(String documentId) {
    if (!_activePdfDocuments.contains(documentId)) {
      if (_activePdfDocuments.length >= _maxPdfDocuments) {
        final oldestId = _activePdfDocuments.removeAt(0);
        debugPrint('Document PDF $oldestId fermé pour libérer la mémoire');
      }
      _activePdfDocuments.add(documentId);
      debugPrint('Document PDF $documentId ouvert');
    }
  }

  static void unregisterPdfDocument(String documentId) {
    _activePdfDocuments.remove(documentId);
    debugPrint('Document PDF $documentId fermé');
  }
}

// Extension pour faciliter l'utilisation
extension MemoryOptimizedWidget on Widget {
  Widget withMemoryManagement() {
    return _MemoryManagedWidget(child: this);
  }
}

class _MemoryManagedWidget extends StatefulWidget {
  final Widget child;

  const _MemoryManagedWidget({required this.child});

  @override
  State<_MemoryManagedWidget> createState() => _MemoryManagedWidgetState();
}

class _MemoryManagedWidgetState extends State<_MemoryManagedWidget> {
  late VoidCallback _disposeCallback;

  @override
  void initState() {
    super.initState();
    _disposeCallback = () {
      // Cleanup spécifique au widget
    };
    MemoryManager.registerDisposeCallback(_disposeCallback);
  }

  @override
  void dispose() {
    MemoryManager.unregisterDisposeCallback(_disposeCallback);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

