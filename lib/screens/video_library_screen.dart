import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/video_provider.dart';
import '../providers/auth_provider.dart';
import '../utils/translation_helper.dart';

class VideoLibraryScreen extends StatefulWidget {
  const VideoLibraryScreen({super.key});

  @override
  State<VideoLibraryScreen> createState() => _VideoLibraryScreenState();
}

class _VideoLibraryScreenState extends State<VideoLibraryScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadVideoLibrary();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadVideoLibrary() async {
    final videoProvider = context.read<VideoProvider>();
    await videoProvider.loadVideoCategories(perPage: 20);
  }

  void _performSearch(String query) {
    final videoProvider = context.read<VideoProvider>();
    if (query.trim().isNotEmpty) {
      videoProvider.searchVideos(query: query, limit: 50);
    } else {
      videoProvider.clearSearchResults();
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Vidéothèque'),
        backgroundColor: const Color(0xFF1E3A8A),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadVideoLibrary,
          ),
        ],
      ),
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Consumer<VideoProvider>(
          builder: (context, videoProvider, child) {
            return RefreshIndicator(
              onRefresh: _loadVideoLibrary,
              child: Column(
                children: [
                  // Barre de recherche
                  _buildSearchBar(screenWidth),

                  // Contenu principal
                  Expanded(
                    child: _buildMainContent(videoProvider, screenWidth, screenHeight),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSearchBar(double screenWidth) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 5,
            spreadRadius: 1,
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Rechercher des vidéos...',
          prefixIcon: const Icon(Icons.search, color: Colors.grey),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, color: Colors.grey),
                  onPressed: () {
                    _searchController.clear();
                    _performSearch('');
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        ),
        onChanged: _performSearch,
        onSubmitted: _performSearch,
      ),
    );
  }

  Widget _buildMainContent(VideoProvider videoProvider, double screenWidth, double screenHeight) {
    // Si recherche active, afficher les résultats
    if (videoProvider.lastSearchQuery.isNotEmpty) {
      return _buildSearchResults(videoProvider, screenWidth);
    }

    // Sinon, afficher les catégories
    if (videoProvider.isLoadingCategories) {
      return const Center(child: CircularProgressIndicator());
    }

    if (videoProvider.hasCategoriesError) {
      return _buildErrorWidget(videoProvider.categoriesError!, _loadVideoLibrary);
    }

    if (videoProvider.videoCategories.isEmpty) {
      return _buildEmptyWidget();
    }

    return _buildCategoriesGrid(videoProvider, screenWidth, screenHeight);
  }

  Widget _buildSearchResults(VideoProvider videoProvider, double screenWidth) {
    if (videoProvider.isSearching) {
      return const Center(child: CircularProgressIndicator());
    }

    if (videoProvider.hasSearchError) {
      return _buildErrorWidget(videoProvider.searchError!, () {
        _performSearch(videoProvider.lastSearchQuery);
      });
    }

    if (videoProvider.searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Aucun résultat trouvé',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Essayez avec d\'autres mots-clés',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: videoProvider.searchResults.length,
      itemBuilder: (context, index) {
        final video = videoProvider.searchResults[index];
        return _buildVideoCard(video, screenWidth);
      },
    );
  }

  Widget _buildCategoriesGrid(VideoProvider videoProvider, double screenWidth, double screenHeight) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.8,
      ),
      itemCount: videoProvider.videoCategories.length,
      itemBuilder: (context, index) {
        final category = videoProvider.videoCategories[index];
        return _buildCategoryCard(category, screenWidth);
      },
    );
  }

  Widget _buildCategoryCard(dynamic category, double screenWidth) {
    final title = TranslationHelper.getTranslatedText(category['intitule'], defaultText: 'Catégorie');
    final formationsCount = category['formations']?.length ?? 0;
    final slug = category['slug'] ?? '';

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: () {
          Navigator.pushNamed(
            context,
            '/video-category',
            arguments: {
              'slug': slug,
              'title': title,
            },
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
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
              Icon(
                Icons.video_library,
                size: 40,
                color: Colors.white,
              ),
              const SizedBox(height: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '$formationsCount formation${formationsCount > 1 ? 's' : ''}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(
                    Icons.play_circle_outline,
                    color: Colors.white.withValues(alpha: 0.8),
                    size: 20,
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.white.withValues(alpha: 0.8),
                    size: 16,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVideoCard(dynamic video, double screenWidth) {
    final title = TranslationHelper.getTranslatedText(video['intitule'], defaultText: 'Vidéo');
    final videoId = video['id'] ?? 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          Navigator.pushNamed(
            context,
            '/video-player',
            arguments: {
              'video': video,
              'title': title,
            },
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 80,
                height: 60,
                decoration: BoxDecoration(
                  color: const Color(0xFF1E3A8A).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.play_circle_outline,
                  size: 32,
                  color: const Color(0xFF1E3A8A),
                ),
              ),
              const SizedBox(width: 12),
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
                    Consumer<VideoProvider>(
                      builder: (context, videoProvider, child) {
                        final progress = videoProvider.getVideoProgress(videoId);
                        final isCompleted = videoProvider.isVideoCompleted(videoId);

                        return Row(
                          children: [
                            Icon(
                              isCompleted ? Icons.check_circle : Icons.play_circle,
                              size: 16,
                              color: isCompleted ? Colors.green : Colors.grey[600],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              isCompleted
                                  ? 'Terminé'
                                  : progress > 0
                                      ? 'En cours (${(progress * 100).round()}%)'
                                      : 'Non démarré',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: Colors.grey[400],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorWidget(String errorMessage, VoidCallback onRetry) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Erreur de chargement',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              errorMessage,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Réessayer'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E3A8A),
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.video_library_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Aucune vidéo disponible',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Les vidéos seront bientôt disponibles',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }
}