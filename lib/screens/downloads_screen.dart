import 'package:flutter/material.dart';
import '../services/offline_download_service.dart';

class DownloadsScreen extends StatefulWidget {
  const DownloadsScreen({super.key});

  @override
  State<DownloadsScreen> createState() => _DownloadsScreenState();
}

class _DownloadsScreenState extends State<DownloadsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final OfflineDownloadService _downloadService = OfflineDownloadService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadDownloads();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadDownloads() {
    // Nettoyer les téléchargements expirés
    _downloadService.cleanExpiredDownloads();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text(
          'Mes téléchargements',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.black,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Colors.red,
          tabs: const [
            Tab(text: 'Tout'),
            Tab(text: 'Vidéos'),
            Tab(text: 'Documents'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.storage, color: Colors.white),
            onPressed: _showStorageInfo,
          ),
          IconButton(
            icon: const Icon(Icons.delete_sweep, color: Colors.white),
            onPressed: _showCleanupDialog,
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildAllDownloads(),
          _buildVideoDownloads(),
          _buildDocumentDownloads(),
        ],
      ),
    );
  }

  Widget _buildAllDownloads() {
    final allDownloads = _downloadService.downloads.values.toList()
      ..sort((a, b) => b.downloadedAt.compareTo(a.downloadedAt));

    if (allDownloads.isEmpty) {
      return _buildEmptyState(
        'Aucun téléchargement',
        'Téléchargez des vidéos et documents pour les regarder hors ligne',
        Icons.download_outlined,
      );
    }

    return _buildDownloadsList(allDownloads);
  }

  Widget _buildVideoDownloads() {
    final videoDownloads = _downloadService.getDownloadsByType(DownloadType.video);

    if (videoDownloads.isEmpty) {
      return _buildEmptyState(
        'Aucune vidéo téléchargée',
        'Téléchargez des cours pour les regarder sans connexion',
        Icons.video_library_outlined,
      );
    }

    return _buildDownloadsList(videoDownloads);
  }

  Widget _buildDocumentDownloads() {
    final documentDownloads = _downloadService.getDownloadsByType(DownloadType.pdf);

    if (documentDownloads.isEmpty) {
      return _buildEmptyState(
        'Aucun document téléchargé',
        'Téléchargez des PDFs et fascicules pour les lire hors ligne',
        Icons.description_outlined,
      );
    }

    return _buildDownloadsList(documentDownloads);
  }

  Widget _buildDownloadsList(List<DownloadItem> downloads) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: downloads.length,
      itemBuilder: (context, index) {
        final download = downloads[index];
        return _buildDownloadCard(download);
      },
    );
  }

  Widget _buildDownloadCard(DownloadItem download) {
    final progress = _downloadService.downloadProgress[download.id] ?? 0.0;
    final isDownloading = progress > 0.0 && !download.isCompleted;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(8),
      ),
      child: InkWell(
        onTap: download.isCompleted ? () => _playContent(download) : null,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Thumbnail
              Container(
                width: 80,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.grey[800],
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Stack(
                  children: [
                    Center(
                      child: Icon(
                        download.type == DownloadType.video
                            ? Icons.play_circle_outline
                            : Icons.description,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                    if (isDownloading)
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.7),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Center(
                            child: CircularProgressIndicator(
                              value: progress,
                              valueColor: const AlwaysStoppedAnimation<Color>(Colors.red),
                              strokeWidth: 3,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              const SizedBox(width: 12),

              // Informations
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      download.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          download.type == DownloadType.video
                              ? Icons.videocam
                              : Icons.description,
                          color: Colors.grey,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          download.type == DownloadType.video ? 'Vidéo' : 'Document',
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(width: 12),
                        if (download.quality.isNotEmpty) ...[
                          Text(
                            download.quality.toUpperCase(),
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 12),
                        ],
                        Text(
                          _formatFileSize(download.size),
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    if (isDownloading) ...[
                      Text(
                        'Téléchargement... ${(progress * 100).round()}%',
                        style: const TextStyle(
                          color: Colors.red,
                          fontSize: 12,
                        ),
                      ),
                    ] else ...[
                      Text(
                        'Téléchargé le ${_formatDate(download.downloadedAt)}',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Actions
              Column(
                children: [
                  if (download.isCompleted)
                    IconButton(
                      onPressed: () => _playContent(download),
                      icon: Icon(
                        download.type == DownloadType.video
                            ? Icons.play_arrow
                            : Icons.visibility,
                        color: Colors.white,
                      ),
                    ),
                  IconButton(
                    onPressed: () => _showDeleteDialog(download),
                    icon: const Icon(
                      Icons.delete,
                      color: Colors.grey,
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

  Widget _buildEmptyState(String title, String subtitle, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 80,
            color: Colors.grey[600],
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              Navigator.pushNamed(context, '/video-library');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text('Parcourir le contenu'),
          ),
        ],
      ),
    );
  }

  void _playContent(DownloadItem download) {
    if (download.type == DownloadType.video) {
      Navigator.pushNamed(
        context,
        '/enhanced-video-player',
        arguments: {
          'video': {
            'id': download.id,
            'intitule': {'fr': download.title},
            'url': download.localPath, // Utilise le chemin local
          },
          'title': download.title,
          'isOffline': true,
        },
      );
    } else {
      Navigator.pushNamed(
        context,
        '/pdf-viewer',
        arguments: {
          'url': download.localPath, // Utilise le chemin local
          'title': download.title,
          'isOffline': true,
        },
      );
    }
  }

  void _showDeleteDialog(DownloadItem download) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text(
          'Supprimer le téléchargement',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'Voulez-vous supprimer "${download.title}" de vos téléchargements ?',
          style: const TextStyle(color: Colors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _downloadService.removeDownload(download.id);
              setState(() {});
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${download.title} supprimé'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  void _showStorageInfo() {
    final stats = _downloadService.getDownloadStats();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text(
          'Stockage',
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStorageRow('Espace utilisé', '${stats['storage_used_mb']} MB'),
            _buildStorageRow('Espace total', '${stats['max_storage_mb']} MB'),
            const SizedBox(height: 16),
            _buildStorageRow('Vidéos', '${stats['videos_count']}'),
            _buildStorageRow('Documents', '${stats['pdfs_count']}'),
            _buildStorageRow('Total téléchargements', '${stats['total_downloads']}/${stats['max_downloads']}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildStorageRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.grey),
          ),
          Text(
            value,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  void _showCleanupDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text(
          'Nettoyer les téléchargements',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Supprimer tous les téléchargements expirés (plus de 30 jours) ?',
          style: TextStyle(color: Colors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _downloadService.cleanExpiredDownloads();
              setState(() {});
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Nettoyage terminé'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Nettoyer'),
          ),
        ],
      ),
    );
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Aujourd\'hui';
    } else if (difference.inDays == 1) {
      return 'Hier';
    } else if (difference.inDays < 7) {
      return 'Il y a ${difference.inDays} jours';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}