import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/video_cache_service.dart';
import '../providers/video_provider.dart';
import '../utils/translation_helper.dart';

class VideoHistoryScreen extends StatefulWidget {
  const VideoHistoryScreen({super.key});

  @override
  State<VideoHistoryScreen> createState() => _VideoHistoryScreenState();
}

class _VideoHistoryScreenState extends State<VideoHistoryScreen> {
  final VideoCacheService _cacheService = VideoCacheService();
  List<Map<String, dynamic>> _recentVideos = [];
  Map<String, dynamic> _cacheStats = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    setState(() {
      _recentVideos = _cacheService.getRecentlyWatchedVideos(limit: 20);
      _cacheStats = _cacheService.getCacheStats();
    });
  }

  void _clearCache() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Vider le cache'),
        content: const Text(
          'Êtes-vous sûr de vouloir vider le cache ? '
          'Cela supprimera toutes les données de progression locale.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              _cacheService.clearAllCache();
              Navigator.pop(context);
              _loadData();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Cache vidé avec succès'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Vider'),
          ),
        ],
      ),
    );
  }

  void _optimizeCache() {
    _cacheService.optimizeMemoryUsage();
    _loadData();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Cache optimisé'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Historique vidéo'),
        backgroundColor: const Color(0xFF1E3A8A),
        foregroundColor: Colors.white,
        actions: [
          PopupMenuButton(
            icon: const Icon(Icons.more_vert),
            itemBuilder: (context) => [
              PopupMenuItem(
                child: const ListTile(
                  leading: Icon(Icons.refresh),
                  title: Text('Actualiser'),
                  contentPadding: EdgeInsets.zero,
                ),
                onTap: () {
                  Future.delayed(Duration.zero, () => _loadData());
                },
              ),
              PopupMenuItem(
                child: const ListTile(
                  leading: Icon(Icons.cleaning_services),
                  title: Text('Optimiser'),
                  contentPadding: EdgeInsets.zero,
                ),
                onTap: () {
                  Future.delayed(Duration.zero, () => _optimizeCache());
                },
              ),
              PopupMenuItem(
                child: const ListTile(
                  leading: Icon(Icons.delete_sweep),
                  title: Text('Vider cache'),
                  contentPadding: EdgeInsets.zero,
                ),
                onTap: () {
                  Future.delayed(Duration.zero, () => _clearCache());
                },
              ),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          _loadData();
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Statistiques du cache
              _buildCacheStatsCard(),

              const SizedBox(height: 20),

              // Vidéos récemment regardées
              _buildRecentVideosSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCacheStatsCard() {
    final totalItems = _cacheStats['total_items'] ?? 0;
    final maxItems = _cacheStats['max_cache_size'] ?? 100;
    final cacheUsagePercent = totalItems / maxItems;

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF1E3A8A),
              const Color(0xFF3B82F6),
            ],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.memory,
                  color: Colors.white,
                  size: 28,
                ),
                const SizedBox(width: 12),
                const Text(
                  'Statistiques du cache',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Utilisation du cache
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Utilisation',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$totalItems / $maxItems éléments',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                CircularProgressIndicator(
                  value: cacheUsagePercent,
                  backgroundColor: Colors.white.withValues(alpha: 0.3),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    cacheUsagePercent > 0.8 ? Colors.orange : Colors.white,
                  ),
                  strokeWidth: 6,
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Détails du cache
            Row(
              children: [
                Expanded(
                  child: _buildCacheStatItem(
                    'Métadonnées',
                    '${_cacheStats['video_metadata_count'] ?? 0}',
                    Icons.video_library,
                  ),
                ),
                Expanded(
                  child: _buildCacheStatItem(
                    'Progrès',
                    '${_cacheStats['progress_count'] ?? 0}',
                    Icons.play_circle,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildCacheStatItem(
                    'Qualités',
                    '${_cacheStats['quality_count'] ?? 0}',
                    Icons.hd,
                  ),
                ),
                Expanded(
                  child: _buildCacheStatItem(
                    'Chapitres',
                    '${_cacheStats['chapters_count'] ?? 0}',
                    Icons.list,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCacheStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(
          icon,
          color: Colors.white.withValues(alpha: 0.8),
          size: 24,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.7),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildRecentVideosSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.history,
              color: Color(0xFF1E3A8A),
              size: 24,
            ),
            const SizedBox(width: 8),
            const Text(
              'Récemment regardées',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E3A8A),
              ),
            ),
            const Spacer(),
            Text(
              '${_recentVideos.length} vidéos',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        if (_recentVideos.isEmpty)
          _buildEmptyState()
        else
          ..._recentVideos.map((video) => _buildRecentVideoCard(video)).toList(),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Icon(
            Icons.video_camera_back_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Aucune vidéo récente',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Commencez à regarder des vidéos pour voir votre historique',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentVideoCard(Map<String, dynamic> video) {
    final metadata = video['metadata'] as Map<String, dynamic>;
    final progressData = video['progress'] as Map<String, dynamic>;

    final title = TranslationHelper.getTranslatedText(
      metadata['intitule'],
      defaultText: 'Vidéo sans titre',
    );
    final progress = (progressData['progress'] as double) * 100;
    final lastWatched = DateTime.parse(progressData['last_watched']);
    final watchedDuration = Duration(seconds: progressData['watched_duration']);
    final totalDuration = Duration(seconds: progressData['total_duration']);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          Navigator.pushNamed(
            context,
            '/video-player',
            arguments: {
              'video': metadata,
              'title': title,
            },
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Thumbnail simulé
                  Container(
                    width: 80,
                    height: 60,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E3A8A).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Stack(
                      children: [
                        const Center(
                          child: Icon(
                            Icons.play_circle_outline,
                            size: 32,
                            color: Color(0xFF1E3A8A),
                          ),
                        ),
                        if (progress > 0)
                          Positioned(
                            bottom: 4,
                            left: 4,
                            right: 4,
                            child: LinearProgressIndicator(
                              value: progress / 100,
                              backgroundColor: Colors.white.withValues(alpha: 0.8),
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                Color(0xFF1E3A8A),
                              ),
                              minHeight: 3,
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Informations de la vidéo
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${progress.round()}% regardée',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${_formatDuration(watchedDuration)} / ${_formatDuration(totalDuration)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Temps depuis dernière lecture
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 16,
                        color: Colors.grey[500],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatRelativeTime(lastWatched),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Actions rapides
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        _cacheService.clearVideoCache(video['video_id']);
                        _loadData();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Cache supprimé pour "$title"'),
                            backgroundColor: Colors.orange,
                          ),
                        );
                      },
                      icon: const Icon(Icons.delete_outline, size: 16),
                      label: const Text('Supprimer'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pushNamed(
                          context,
                          '/video-player',
                          arguments: {
                            'video': metadata,
                            'title': title,
                          },
                        );
                      },
                      icon: const Icon(Icons.play_arrow, size: 16),
                      label: const Text('Reprendre'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E3A8A),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
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
      return '$hours:${twoDigits(minutes)}:${twoDigits(seconds)}';
    } else {
      return '$minutes:${twoDigits(seconds)}';
    }
  }

  String _formatRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return 'Il y a ${difference.inDays}j';
    } else if (difference.inHours > 0) {
      return 'Il y a ${difference.inHours}h';
    } else if (difference.inMinutes > 0) {
      return 'Il y a ${difference.inMinutes}min';
    } else {
      return 'À l\'instant';
    }
  }
}