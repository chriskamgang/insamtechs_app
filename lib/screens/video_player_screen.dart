import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/video_provider.dart';
import '../providers/auth_provider.dart';
import '../utils/translation_helper.dart';

class VideoPlayerScreen extends StatefulWidget {
  final dynamic video;
  final String title;

  const VideoPlayerScreen({
    super.key,
    required this.video,
    required this.title,
  });

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  bool _isPlaying = false;
  bool _showControls = true;
  double _currentPosition = 0.0;
  double _totalDuration = 100.0; // Pour simulation

  // Pour les contrôles
  bool _isFullscreen = false;
  double _playbackSpeed = 1.0;
  double _volume = 1.0;

  @override
  void initState() {
    super.initState();
    _loadVideoProgress();
  }

  Future<void> _loadVideoProgress() async {
    final authProvider = context.read<AuthProvider>();
    final videoProvider = context.read<VideoProvider>();

    if (authProvider.isAuthenticated && authProvider.user?.id != null) {
      final videoId = widget.video['id'] ?? 0;
      final progress = videoProvider.getVideoProgress(videoId);
      setState(() {
        _currentPosition = progress * _totalDuration;
      });
    }
  }

  Future<void> _saveProgress() async {
    final authProvider = context.read<AuthProvider>();
    final videoProvider = context.read<VideoProvider>();

    if (authProvider.isAuthenticated && authProvider.user?.id != null) {
      final videoId = widget.video['id'] ?? 0;
      final progress = _currentPosition / _totalDuration;

      await videoProvider.saveVideoProgress(
        userId: authProvider.user!.id!,
        videoId: videoId,
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
      _startProgressSimulation();
    }
  }

  void _startProgressSimulation() {
    // Simulation simple du progrès
    if (_isPlaying && _currentPosition < _totalDuration) {
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted && _isPlaying) {
          setState(() {
            _currentPosition += 1;
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
      });
    }
  }

  void _seekTo(double position) {
    setState(() {
      _currentPosition = position;
    });
    _saveProgress();
  }

  void _toggleFullscreen() {
    setState(() {
      _isFullscreen = !_isFullscreen;
    });
  }

  void _changePlaybackSpeed(double speed) {
    setState(() {
      _playbackSpeed = speed;
    });
  }

  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _isFullscreen ? null : AppBar(
        title: Text(widget.title),
        backgroundColor: const Color(0xFF1E3A8A),
        foregroundColor: Colors.white,
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

            // Contrôles et informations
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
          // Zone vidéo simulée
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
                  Icon(
                    _isPlaying ? Icons.play_circle_filled : Icons.play_circle_outline,
                    size: 80,
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Lecteur vidéo simulé',
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
              ),
            ),
          ),

          // Contrôles overlay
          if (_showControls)
            Positioned.fill(
              child: _buildControlsOverlay(),
            ),

          // Tap to toggle controls
          Positioned.fill(
            child: GestureDetector(
              onTap: _toggleControls,
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
            Colors.black.withValues(alpha: 0.3),
            Colors.transparent,
            Colors.black.withValues(alpha: 0.5),
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
                PopupMenuButton<double>(
                  icon: const Icon(Icons.speed, color: Colors.white),
                  onSelected: _changePlaybackSpeed,
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: 0.5, child: Text('0.5x')),
                    const PopupMenuItem(value: 0.75, child: Text('0.75x')),
                    const PopupMenuItem(value: 1.0, child: Text('1x')),
                    const PopupMenuItem(value: 1.25, child: Text('1.25x')),
                    const PopupMenuItem(value: 1.5, child: Text('1.5x')),
                    const PopupMenuItem(value: 2.0, child: Text('2x')),
                  ],
                ),
                IconButton(
                  icon: Icon(
                    _isFullscreen ? Icons.fullscreen_exit : Icons.fullscreen,
                    color: Colors.white,
                  ),
                  onPressed: _toggleFullscreen,
                ),
              ],
            ),
          ),

          const Spacer(),

          // Contrôles de lecture
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
                // Barre de progression
                Row(
                  children: [
                    Text(
                      _formatDuration(Duration(seconds: _currentPosition.round())),
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                          trackHeight: 3,
                        ),
                        child: Slider(
                          value: _currentPosition,
                          max: _totalDuration,
                          onChanged: _seekTo,
                          activeColor: const Color(0xFF1E3A8A),
                          inactiveColor: Colors.white.withValues(alpha: 0.3),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _formatDuration(Duration(seconds: _totalDuration.round())),
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ],
                ),

                // Vitesse de lecture
                Row(
                  children: [
                    const Icon(Icons.speed, color: Colors.white, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      '${_playbackSpeed}x',
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                    const Spacer(),
                    Consumer<VideoProvider>(
                      builder: (context, videoProvider, child) {
                        final videoId = widget.video['id'] ?? 0;
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

            // Informations sur la vidéo
            _buildInfoCard(),

            const SizedBox(height: 16),

            // Actions
            _buildActionsCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Informations',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1E3A8A),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.access_time, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Text(
                  'Durée: ${_formatDuration(Duration(seconds: _totalDuration.round()))}',
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Consumer<VideoProvider>(
              builder: (context, videoProvider, child) {
                final videoId = widget.video['id'] ?? 0;
                final progress = videoProvider.getVideoProgress(videoId);

                return Column(
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.play_circle, size: 16, color: Colors.grey),
                        const SizedBox(width: 8),
                        Text(
                          'Progression: ${(progress * 100).round()}%',
                          style: const TextStyle(color: Colors.grey),
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
                      // Implémenter le téléchargement hors ligne
                      final videoProvider = context.read<VideoProvider>();
                      final videoId = widget.video['id'] ?? 0;
                      final videoUrl = widget.video['lien'] ?? '';

                      videoProvider.prepareVideoForOffline(
                        videoId: videoId,
                        videoUrl: videoUrl,
                      );

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Préparation du téléchargement...'),
                          backgroundColor: Colors.blue,
                        ),
                      );
                    },
                    icon: const Icon(Icons.download),
                    label: const Text('Télécharger'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final authProvider = context.read<AuthProvider>();
                      final videoProvider = context.read<VideoProvider>();

                      if (authProvider.isAuthenticated && authProvider.user?.id != null) {
                        final videoId = widget.video['id'] ?? 0;
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

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours}:${twoDigits(minutes)}:${twoDigits(seconds)}';
    } else {
      return '${minutes}:${twoDigits(seconds)}';
    }
  }

  @override
  void dispose() {
    _saveProgress();
    super.dispose();
  }
}