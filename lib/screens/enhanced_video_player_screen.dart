import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/video_provider.dart';
import '../providers/auth_provider.dart';
import '../services/video_cache_service.dart';
import '../utils/translation_helper.dart';

class EnhancedVideoPlayerScreen extends StatefulWidget {
  final dynamic video;
  final String title;

  const EnhancedVideoPlayerScreen({
    super.key,
    required this.video,
    required this.title,
  });

  @override
  State<EnhancedVideoPlayerScreen> createState() => _EnhancedVideoPlayerScreenState();
}

class _EnhancedVideoPlayerScreenState extends State<EnhancedVideoPlayerScreen> {
  final VideoCacheService _cacheService = VideoCacheService();

  bool _isPlaying = false;
  bool _showControls = true;
  bool _isBuffering = false;
  double _currentPosition = 0.0;
  double _totalDuration = 100.0;
  double _bufferProgress = 0.0;

  // Contrôles avancés
  bool _isFullscreen = false;
  double _playbackSpeed = 1.0;
  double _volume = 1.0;
  String _selectedQuality = 'Auto';
  bool _showSettings = false;

  // Qualités disponibles
  final List<Map<String, String>> _availableQualities = [
    {'label': 'Auto', 'value': 'auto'},
    {'label': '720p HD', 'value': '720p'},
    {'label': '480p', 'value': '480p'},
    {'label': '360p', 'value': '360p'},
    {'label': '240p', 'value': '240p'},
  ];

  // Performance monitoring
  int _bufferCount = 0;
  DateTime? _playStartTime;
  Duration _totalPlayTime = Duration.zero;

  // Provider references saved to avoid accessing context after dispose
  AuthProvider? _authProvider;
  VideoProvider? _videoProvider;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Save provider references for use in dispose
    _authProvider = context.read<AuthProvider>();
    _videoProvider = context.read<VideoProvider>();
  }


  Future<void> _initializePlayer() async {
    await _loadVideoFromCache();
    await _loadVideoProgress();
    _preloadVideoData();
  }

  Future<void> _loadVideoFromCache() async {
    final videoId = widget.video.id.toString();

    // Essayer de charger depuis le cache
    final cachedData = _cacheService.getVideoMetadata(videoId);
    if (cachedData != null) {
      print('Vidéo chargée depuis le cache');

      // Charger les qualités disponibles depuis le cache
      final qualities = _cacheService.getVideoQualities(videoId);
      if (qualities != null) {
        // Mettre à jour les qualités disponibles
        setState(() {
          // Les qualités seraient mises à jour ici
        });
      }
    } else {
      // Mettre en cache les données actuelles
      _cacheService.cacheVideoMetadata(videoId, widget.video.toJson());

      // Simuler les qualités disponibles pour cette vidéo
      _cacheService.cacheVideoQualities(videoId, [
        {'label': 'Auto', 'value': 'auto', 'bandwidth': '0'},
        {'label': '720p HD', 'value': '720p', 'bandwidth': '2000000'},
        {'label': '480p', 'value': '480p', 'bandwidth': '1000000'},
        {'label': '360p', 'value': '360p', 'bandwidth': '500000'},
      ]);
    }
  }

  Future<void> _loadVideoProgress() async {
    // Use saved references or read from context if still building
    final authProvider = _authProvider ?? (mounted ? context.read<AuthProvider>() : null);
    final videoProvider = _videoProvider ?? (mounted ? context.read<VideoProvider>() : null);

    if (authProvider == null || videoProvider == null) return;

    final videoId = widget.video.id.toString();

    if (authProvider.isAuthenticated && authProvider.user?.id != null) {
      // Essayer de charger depuis le cache local
      final cachedProgress = _cacheService.getVideoProgress(videoId);
      if (cachedProgress != null && mounted) {
        setState(() {
          _currentPosition = (cachedProgress['progress'] as double) * _totalDuration;
        });
      }

      // Charger aussi depuis le provider
      final progress = videoProvider.getVideoProgress(widget.video.id);
      if (mounted) {
        setState(() {
          _currentPosition = progress * _totalDuration;
        });
      }
    }
  }

  void _preloadVideoData() async {
    // Simuler le préchargement des données
    setState(() {
      _isBuffering = true;
    });

    // Simuler le buffering
    for (int i = 0; i <= 20; i++) {
      await Future.delayed(const Duration(milliseconds: 100));
      if (mounted) {
        setState(() {
          _bufferProgress = i * 5.0; // Buffer jusqu'à 20% de la vidéo
        });
      }
    }

    setState(() {
      _isBuffering = false;
    });
  }

  Future<void> _saveProgress() async {
    // Check if widget is still mounted and providers are available
    if (!mounted || _authProvider == null || _videoProvider == null) return;

    final videoId = widget.video.id.toString();

    if (_authProvider!.isAuthenticated && _authProvider!.user?.id != null) {
      final progress = _currentPosition / _totalDuration;

      // Sauvegarder dans le cache local
      _cacheService.cacheVideoProgress(
        videoId: videoId,
        progress: progress,
        watchedDuration: Duration(seconds: _currentPosition.round()),
        totalDuration: Duration(seconds: _totalDuration.round()),
        lastWatched: DateTime.now(),
      );

      // Sauvegarder via le provider (API)
      await _videoProvider!.saveVideoProgress(
        userId: _authProvider!.user!.id!,
        videoId: int.parse(videoId),
        progress: progress,
        watchedDuration: Duration(seconds: _currentPosition.round()),
        totalDuration: Duration(seconds: _totalDuration.round()),
      );
    }
  }

  void _togglePlayPause() {
    setState(() {
      _isPlaying = !_isPlaying;
    });

    if (_isPlaying) {
      _playStartTime = DateTime.now();
      _startProgressSimulation();
    } else {
      if (_playStartTime != null) {
        _totalPlayTime += DateTime.now().difference(_playStartTime!);
      }
    }
  }

  void _startProgressSimulation() async {
    if (_isPlaying && _currentPosition < _totalDuration) {
      // Simuler un buffering occasionnel
      if (_currentPosition > _bufferProgress && _bufferProgress < _totalDuration) {
        setState(() {
          _isBuffering = true;
        });
        _bufferCount++;

        await Future.delayed(Duration(milliseconds: 200 + (_bufferCount * 100)));

        setState(() {
          _isBuffering = false;
          _bufferProgress += 10; // Buffer 10 secondes de plus
        });
      }

      await Future.delayed(Duration(milliseconds: (1000 / _playbackSpeed).round()));

      if (mounted && _isPlaying) {
        setState(() {
          _currentPosition += _playbackSpeed;
          if (_currentPosition >= _totalDuration) {
            _currentPosition = _totalDuration;
            _isPlaying = false;
            _saveProgress();
          }
        });

        if (_isPlaying) {
          _startProgressSimulation();
        }
      }
    }
  }

  void _seekTo(double position) {
    setState(() {
      _currentPosition = position;

      // Si on cherche au-delà du buffer, déclencher un nouveau buffering
      if (position > _bufferProgress) {
        _isBuffering = true;
        _preloadVideoData();
      }
    });
    _saveProgress();
  }

  void _changeQuality(String quality) {
    setState(() {
      _selectedQuality = quality;
      _isBuffering = true;
    });

    // Simuler le changement de qualité
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _isBuffering = false;
        });
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Qualité changée: $quality'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Widget _buildQualitySelector() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            child: const Text(
              'Qualité vidéo',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ..._availableQualities.map((quality) {
            final isSelected = quality['value'] == _selectedQuality.toLowerCase();
            return ListTile(
              title: Text(
                quality['label']!,
                style: TextStyle(
                  color: isSelected ? const Color(0xFF1E3A8A) : Colors.white,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
              trailing: isSelected
                  ? const Icon(Icons.check, color: Color(0xFF1E3A8A))
                  : null,
              onTap: () {
                _changeQuality(quality['label']!);
                setState(() {
                  _showSettings = false;
                });
              },
            );
          }).toList(),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _isFullscreen ? null : AppBar(
        title: Text(widget.title),
        backgroundColor: const Color(0xFF1E3A8A),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              _showVideoInfo();
            },
          ),
        ],
      ),
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // Lecteur vidéo
            Expanded(
              flex: _isFullscreen ? 1 : 3,
              child: _buildVideoPlayer(),
            ),

            // Informations et contrôles détaillés
            if (!_isFullscreen) ...[
              Expanded(
                flex: 2,
                child: _buildVideoInfo(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildVideoPlayer() {
    return Container(
      width: double.infinity,
      color: Colors.black,
      child: Stack(
        children: [
          // Zone vidéo principale
          Center(
            child: Container(
              width: double.infinity,
              height: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.grey[800]!,
                    Colors.grey[900]!,
                  ],
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_isBuffering) ...[
                    const CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1E3A8A)),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Chargement...',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 16,
                      ),
                    ),
                  ] else ...[
                    Icon(
                      _isPlaying ? Icons.pause_circle_filled : Icons.play_circle_outline,
                      size: 80,
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Lecteur vidéo - $_selectedQuality',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${_formatDuration(Duration(seconds: _currentPosition.round()))} / ${_formatDuration(Duration(seconds: _totalDuration.round()))}',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.6),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          // Indicateur de buffer
          if (_bufferProgress > 0)
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'Buffer: ${(_bufferProgress / _totalDuration * 100).round()}%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                  ),
                ),
              ),
            ),

          // Sélecteur de qualité overlay
          if (_showSettings)
            Positioned(
              top: 50,
              right: 16,
              child: _buildQualitySelector(),
            ),

          // Contrôles overlay
          if (_showControls && !_isBuffering)
            Positioned.fill(
              child: _buildControlsOverlay(),
            ),

          // Tap to toggle controls
          Positioned.fill(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _showControls = !_showControls;
                  _showSettings = false;
                });
              },
              child: Container(color: Colors.transparent),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlsOverlay() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withValues(alpha: 0.4),
            Colors.transparent,
            Colors.black.withValues(alpha: 0.6),
          ],
        ),
      ),
      child: Column(
        children: [
          // Contrôles du haut
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                if (_isFullscreen)
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                const Spacer(),
                // Bouton qualité
                IconButton(
                  icon: const Icon(Icons.hd, color: Colors.white),
                  onPressed: () {
                    setState(() {
                      _showSettings = !_showSettings;
                    });
                  },
                ),
                // Bouton vitesse
                PopupMenuButton<double>(
                  icon: const Icon(Icons.speed, color: Colors.white),
                  onSelected: (speed) {
                    setState(() {
                      _playbackSpeed = speed;
                    });
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: 0.5, child: Text('0.5x')),
                    const PopupMenuItem(value: 0.75, child: Text('0.75x')),
                    const PopupMenuItem(value: 1.0, child: Text('1x')),
                    const PopupMenuItem(value: 1.25, child: Text('1.25x')),
                    const PopupMenuItem(value: 1.5, child: Text('1.5x')),
                    const PopupMenuItem(value: 2.0, child: Text('2x')),
                  ],
                ),
                // Bouton plein écran
                IconButton(
                  icon: Icon(
                    _isFullscreen ? Icons.fullscreen_exit : Icons.fullscreen,
                    color: Colors.white,
                  ),
                  onPressed: () {
                    setState(() {
                      _isFullscreen = !_isFullscreen;
                    });
                  },
                ),
              ],
            ),
          ),

          const Spacer(),

          // Contrôles de lecture centrés
          Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.replay_10, color: Colors.white, size: 32),
                  onPressed: () {
                    _seekTo((_currentPosition - 10).clamp(0, _totalDuration));
                  },
                ),
                const SizedBox(width: 24),
                IconButton(
                  icon: Icon(
                    _isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
                    color: Colors.white,
                    size: 64,
                  ),
                  onPressed: _togglePlayPause,
                ),
                const SizedBox(width: 24),
                IconButton(
                  icon: const Icon(Icons.forward_10, color: Colors.white, size: 32),
                  onPressed: () {
                    _seekTo((_currentPosition + 10).clamp(0, _totalDuration));
                  },
                ),
              ],
            ),
          ),

          const Spacer(),

          // Barre de progression et contrôles du bas
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Barre de progression avec buffer
                Row(
                  children: [
                    Text(
                      _formatDuration(Duration(seconds: _currentPosition.round())),
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Stack(
                        children: [
                          // Barre de buffer
                          SliderTheme(
                            data: SliderTheme.of(context).copyWith(
                              thumbShape: SliderComponentShape.noThumb,
                              trackHeight: 3,
                            ),
                            child: Slider(
                              value: _bufferProgress,
                              max: _totalDuration,
                              onChanged: null,
                              activeColor: Colors.white.withValues(alpha: 0.4),
                              inactiveColor: Colors.white.withValues(alpha: 0.1),
                            ),
                          ),
                          // Barre de progression
                          SliderTheme(
                            data: SliderTheme.of(context).copyWith(
                              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                              trackHeight: 3,
                            ),
                            child: Slider(
                              value: _currentPosition,
                              max: _totalDuration,
                              onChanged: _seekTo,
                              activeColor: const Color(0xFF1E3A8A),
                              inactiveColor: Colors.transparent,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _formatDuration(Duration(seconds: _totalDuration.round())),
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ],
                ),

                // Informations de lecture
                Row(
                  children: [
                    Icon(
                      Icons.hd,
                      color: Colors.white.withValues(alpha: 0.8),
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _selectedQuality,
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                    const SizedBox(width: 16),
                    Icon(
                      Icons.speed,
                      color: Colors.white.withValues(alpha: 0.8),
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${_playbackSpeed}x',
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                    const Spacer(),
                    Consumer<VideoProvider>(
                      builder: (context, videoProvider, child) {
                        final videoId = widget.video.id;
                        final progress = videoProvider.getVideoProgress(videoId);
                        final isCompleted = videoProvider.isVideoCompleted(videoId);

                        return Row(
                          children: [
                            Icon(
                              isCompleted ? Icons.check_circle : Icons.circle_outlined,
                              color: isCompleted ? Colors.green : Colors.white.withValues(alpha: 0.6),
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              isCompleted ? 'Terminé' : '${(progress * 100).round()}%',
                              style: const TextStyle(color: Colors.white, fontSize: 12),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoInfo() {
    return Container(
      color: Colors.white,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),

            // Statistiques de performance
            _buildPerformanceCard(),

            const SizedBox(height: 16),

            // Actions
            _buildActionsCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildPerformanceCard() {
    final bufferPercentage = (_bufferProgress / _totalDuration * 100).round();

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Performance de lecture',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1E3A8A),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem('Qualité', _selectedQuality, Icons.hd),
                ),
                Expanded(
                  child: _buildStatItem('Buffer', '$bufferPercentage%', Icons.cloud_download),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem('Vitesse', '${_playbackSpeed}x', Icons.speed),
                ),
                Expanded(
                  child: _buildStatItem('Interruptions', '$_bufferCount', Icons.pause_circle_outline),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Consumer<VideoProvider>(
              builder: (context, videoProvider, child) {
                final videoId = widget.video.id;
                final progress = videoProvider.getVideoProgress(videoId);

                return Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Progression totale',
                          style: TextStyle(fontSize: 14, color: Colors.grey),
                        ),
                        Text(
                          '${(progress * 100).round()}%',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1E3A8A),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: progress,
                      backgroundColor: Colors.grey[300],
                      valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF1E3A8A)),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: const Color(0xFF1E3A8A), size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E3A8A),
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildActionsCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Actions',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1E3A8A),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      _cacheService.debugPrintCacheInfo();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Informations de cache affichées dans la console'),
                          backgroundColor: Colors.blue,
                        ),
                      );
                    },
                    icon: const Icon(Icons.info),
                    label: const Text('Cache Info'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final authProvider = context.read<AuthProvider>();
                      final videoProvider = context.read<VideoProvider>();

                      if (authProvider.isAuthenticated && authProvider.user?.id != null) {
                        final videoId = widget.video.id;
                        final success = await videoProvider.markVideoAsCompleted(
                          userId: authProvider.user!.id!,
                          videoId: videoId,
                        );

                        if (success && context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Vidéo marquée comme terminée'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      }
                    },
                    icon: const Icon(Icons.check),
                    label: const Text('Marquer terminé'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E3A8A),
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showVideoInfo() {
    final cacheStats = _cacheService.getCacheStats();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Informations vidéo'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Titre: ${widget.title}'),
              const SizedBox(height: 8),
              Text('Qualité: $_selectedQuality'),
              Text('Vitesse: ${_playbackSpeed}x'),
              Text('Interruptions: $_bufferCount'),
              const SizedBox(height: 16),
              const Text('Cache:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('Métadonnées: ${cacheStats['video_metadata_count']}'),
              Text('Progrès: ${cacheStats['progress_count']}'),
              Text('Total: ${cacheStats['total_items']}/${cacheStats['max_cache_size']}'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '$hours:${twoDigits(minutes)}:${twoDigits(seconds)}';
    } else {
      return '$minutes:${twoDigits(seconds)}';
    }
  }

  @override
  void dispose() {
    _saveProgress();

    // Optimiser le cache lors de la fermeture
    _cacheService.optimizeMemoryUsage();

    super.dispose();
  }
}