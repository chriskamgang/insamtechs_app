import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:provider/provider.dart';
import '../providers/video_provider.dart';
import '../providers/auth_provider.dart';

class GoogleDriveVideoPlayer extends StatefulWidget {
  final dynamic video;
  final String title;

  const GoogleDriveVideoPlayer({
    super.key,
    required this.video,
    required this.title,
  });

  @override
  State<GoogleDriveVideoPlayer> createState() => _GoogleDriveVideoPlayerState();
}

class _GoogleDriveVideoPlayerState extends State<GoogleDriveVideoPlayer> {
  late final WebViewController _controller;
  bool _isLoading = true;
  String? _errorMessage;

  // Références sauvegardées pour éviter les erreurs dans dispose()
  AuthProvider? _authProvider;
  VideoProvider? _videoProvider;

  @override
  void initState() {
    super.initState();

    // Sauvegarder les références aux providers pour éviter les erreurs dans dispose()
    _authProvider = context.read<AuthProvider>();
    _videoProvider = context.read<VideoProvider>();

    // Extraire l'URL de la vidéo Google Drive
    String? videoUrl = _extractGoogleDriveVideoUrl();

    if (videoUrl == null) {
      setState(() {
        _errorMessage = 'Impossible d\'extraire l\'URL de la vidéo';
        _isLoading = false;
      });
      return;
    }

    // Initialiser le contrôleur WebView
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            // Mise à jour de la progression de chargement
          },
          onPageStarted: (String url) {
            setState(() {
              _isLoading = true;
            });
          },
          onPageFinished: (String url) {
            setState(() {
              _isLoading = false;
            });
          },
          onWebResourceError: (WebResourceError error) {
            setState(() {
              _errorMessage = 'Erreur de chargement: ${error.description}';
              _isLoading = false;
            });
          },
        ),
      )
      ..loadRequest(Uri.parse(videoUrl));

    // Charger la progression de la vidéo
    _loadVideoProgress();
  }

  String _extractGoogleDriveVideoUrl() {
    // Obtenir l'URL originale de la vidéo
    // Le widget.video peut être soit une Map soit un objet Video
    String? originalUrl;

    if (widget.video is Map<String, dynamic>) {
      // Si c'est une Map, utiliser l'indexation
      originalUrl = widget.video['lien'] as String?;
    } else {
      // Si c'est un objet Video, accéder à la propriété url
      originalUrl = widget.video.url;
    }

    if (originalUrl == null) {
      return 'about:blank'; // URL vide si aucune vidéo n'est disponible
    }

    // Vérifier si c'est une URL Google Drive
    if (originalUrl.contains('drive.google.com')) {
      // Convertir l'URL Google Drive en URL de prévisualisation
      // Extrait l'ID de la vidéo de l'URL Google Drive
      RegExp regExp = RegExp(r'/file/d/([a-zA-Z0-9_-]+)|id=([a-zA-Z0-9_-]+)');
      Match? match = regExp.firstMatch(originalUrl);

      String? fileId = match?.group(1) ?? match?.group(2);

      if (fileId != null) {
        // Construire l'URL de prévisualisation pour la vidéo
        // Cette URL permet d'afficher la vidéo dans un iframe
        return 'https://drive.google.com/file/d/$fileId/preview';
      }
    } else if (originalUrl.contains('youtu.be') || originalUrl.contains('youtube.com')) {
      // Pour les vidéos YouTube, on utilise directement l'URL
      return originalUrl;
    }

    // Si ce n'est pas une URL Google Drive ou YouTube, on retourne l'URL originale
    return originalUrl;
  }

  Future<void> _loadVideoProgress() async {
    if (_authProvider?.isAuthenticated == true && _authProvider?.user?.id != null) {
      final videoId = _getVideoId();
      final progress = _videoProvider?.getVideoProgress(videoId);

      // Charger la progression si nécessaire
      print('Progression chargée pour la vidéo $videoId: ${progress != null ? progress * 100 : 0}%');
    }
  }

  Future<void> _saveProgress() async {
    if (_authProvider?.isAuthenticated == true && _authProvider?.user?.id != null) {
      final videoId = _getVideoId();
      // Pour le moment, on sauvegarde une progression de 0
      // Pour une vraie progression, il faudrait interagir avec le lecteur vidéo dans le WebView
      await _videoProvider?.saveVideoProgress(
        userId: _authProvider!.user!.id!,
        videoId: videoId,
        progress: 0.0,
        watchedDuration: Duration.zero,
        totalDuration: Duration.zero,
      );
    }
  }

  // Méthode utilitaire pour obtenir l'ID de la vidéo
  int _getVideoId() {
    if (widget.video is Map<String, dynamic>) {
      return widget.video['id'] as int? ?? 0;
    } else {
      return widget.video.id ?? 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: const Color(0xFF1E3A8A),
        foregroundColor: Colors.white,
      ),
      backgroundColor: Colors.black,
      body: SafeArea(
        child: _buildVideoContent(),
      ),
    );
  }

  Widget _buildVideoContent() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1E3A8A)),
            ),
            SizedBox(height: 16),
            Text(
              'Chargement de la vidéo...',
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error,
                color: Colors.red,
                size: 64,
              ),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.white, fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _errorMessage = null;
                    _isLoading = true;
                  });

                  // Recharger l'URL
                  String? videoUrl = _extractGoogleDriveVideoUrl();
                  if (videoUrl != null) {
                    _controller.loadRequest(Uri.parse(videoUrl));
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E3A8A),
                  foregroundColor: Colors.white,
                ),
                child: const Text('Réessayer'),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        // WebView pour afficher la vidéo
        Expanded(
          child: WebViewWidget(controller: _controller),
        ),
        // Afficher les informations de la vidéo
        Container(
          color: Colors.white,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Consumer<VideoProvider>(
                builder: (context, videoProvider, child) {
                  final videoId = _getVideoId();
                  final progress = videoProvider.getVideoProgress(videoId);
                  final isCompleted = videoProvider.isVideoCompleted(videoId);

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Progression: ${(progress * 100).round()}%',
                        style: const TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: progress,
                        backgroundColor: Colors.grey[300],
                        valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF1E3A8A)),
                      ),
                      const SizedBox(height: 8),
                      if (isCompleted)
                        const Text(
                          '✓ Terminé',
                          style: TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    // Sauvegarder la progression avant de quitter
    // Utiliser les références sauvegardées au lieu du contexte
    if (_authProvider?.isAuthenticated == true && _authProvider?.user?.id != null) {
      final videoId = _getVideoId();
      // Sauvegarder la progression de manière asynchrone sans attendre
      _videoProvider?.saveVideoProgress(
        userId: _authProvider!.user!.id!,
        videoId: videoId,
        progress: 0.0,
        watchedDuration: Duration.zero,
        totalDuration: Duration.zero,
      ).then((_) {
        // Ne rien faire après la sauvegarde
      }).catchError((error) {
        // Gérer les erreurs silencieusement
        print('Erreur lors de la sauvegarde de la progression: $error');
      });
    }
    super.dispose();
  }
}