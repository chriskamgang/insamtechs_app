import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/library_provider.dart';
import '../utils/translation_helper.dart';

class DigitalLibraryScreen extends StatefulWidget {
  const DigitalLibraryScreen({super.key});

  @override
  State<DigitalLibraryScreen> createState() => _DigitalLibraryScreenState();
}

class _DigitalLibraryScreenState extends State<DigitalLibraryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadLibraryData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadLibraryData() async {
    final libraryProvider = context.read<LibraryProvider>();
    await libraryProvider.refreshLibrary();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bibliothèque numérique'),
        backgroundColor: const Color(0xFF1E3A8A),
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white.withValues(alpha: 0.7),
          indicatorColor: Colors.white,
          tabs: const [
            Tab(
              icon: Icon(Icons.book),
              text: 'Livres',
            ),
            Tab(
              icon: Icon(Icons.school),
              text: 'Fascicules',
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadLibraryData,
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildBooksTab(),
          _buildFasciculesTab(),
        ],
      ),
    );
  }

  Widget _buildBooksTab() {
    return Consumer<LibraryProvider>(
      builder: (context, libraryProvider, child) {
        return Column(
          children: [
            // Barre de recherche
            _buildSearchBar(),

            // Contenu principal
            Expanded(
              child: _buildBooksContent(libraryProvider),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFasciculesTab() {
    return Consumer<LibraryProvider>(
      builder: (context, libraryProvider, child) {
        return Column(
          children: [
            // Barre de recherche
            _buildSearchBar(),

            // Contenu principal
            Expanded(
              child: _buildFasciculesContent(libraryProvider),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSearchBar() {
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
          hintText: 'Rechercher...',
          prefixIcon: const Icon(Icons.search, color: Colors.grey),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, color: Colors.grey),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {});
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        ),
        onChanged: (value) {
          setState(() {});
        },
      ),
    );
  }

  Widget _buildBooksContent(LibraryProvider libraryProvider) {
    if (libraryProvider.isLoadingLibrary) {
      return const Center(child: CircularProgressIndicator());
    }

    if (libraryProvider.hasLibraryError) {
      return _buildErrorWidget(
        libraryProvider.libraryError!,
        () => libraryProvider.loadLibraryContent(),
      );
    }

    final libraryContent = libraryProvider.libraryContent;
    if (libraryContent == null) {
      return _buildEmptyWidget('Aucune donnée de bibliothèque disponible');
    }

    // Gérer la structure de l'API: {'categories': {'current_page': 1, 'data': [...]}}
    List<dynamic> categories = [];
    if (libraryContent['categories'] is Map<String, dynamic>) {
      categories = (libraryContent['categories'] as Map<String, dynamic>)['data'] as List<dynamic>? ?? [];
    } else if (libraryContent['categories'] is List<dynamic>) {
      categories = libraryContent['categories'] as List<dynamic>;
    }

    if (categories.isEmpty) {
      return _buildEmptyWidget('Aucune catégorie de livres disponible');
    }

    return RefreshIndicator(
      onRefresh: _loadLibraryData,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          return _buildBookCategoryCard(category);
        },
      ),
    );
  }

  Widget _buildFasciculesContent(LibraryProvider libraryProvider) {
    if (libraryProvider.isLoadingStudyFields) {
      return const Center(child: CircularProgressIndicator());
    }

    if (libraryProvider.hasStudyFieldsError) {
      return _buildErrorWidget(
        libraryProvider.studyFieldsError!,
        () => libraryProvider.loadStudyFields(),
      );
    }

    final studyFields = libraryProvider.studyFields;

    if (studyFields.isEmpty) {
      return _buildEmptyWidget('Aucune filière d\'étude disponible');
    }

    return RefreshIndicator(
      onRefresh: _loadLibraryData,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: studyFields.length,
        itemBuilder: (context, index) {
          final studyField = studyFields[index];
          return _buildStudyFieldCard(studyField);
        },
      ),
    );
  }

  Widget _buildBookCategoryCard(Map<String, dynamic> category) {
    final title = TranslationHelper.getTranslatedText(
      category['intitule'],
      defaultText: 'Catégorie',
    );
    final description = TranslationHelper.getTranslatedText(
      category['description'],
      defaultText: '',
    );
    final formations = category['formations'] as List<dynamic>? ?? [];
    final booksCount = formations.length;
    final slug = category['slug'] ?? '';
    final imageUrl = category['image'] ?? category['img'] ?? '';

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          Navigator.pushNamed(
            context,
            '/books-category',
            arguments: {
              'slug': slug,
              'title': title,
            },
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Image ou icône
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withValues(alpha: 0.2),
                      spreadRadius: 1,
                      blurRadius: 4,
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: _buildCategoryImage(imageUrl, slug),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    if (description.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 8),
                    Text(
                      '$booksCount livre${booksCount > 1 ? 's' : ''}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[500],
                        fontWeight: FontWeight.w500,
                      ),
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

  Widget _buildStudyFieldCard(Map<String, dynamic> studyField) {
    final title = TranslationHelper.getTranslatedText(
      studyField['intitule'] ?? studyField['nom'],
      defaultText: 'Filière',
    );
    final description = TranslationHelper.getTranslatedText(
      studyField['description'],
      defaultText: '',
    );
    final fasciculesCount = studyField['fascicules_count'] ?? 0;
    final slug = studyField['slug'] ?? '';

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          Navigator.pushNamed(
            context,
            '/fascicules-category',
            arguments: {
              'slug': slug,
              'title': title,
            },
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.school,
                  size: 30,
                  color: Color(0xFF3B82F6),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    if (description.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 8),
                    Text(
                      '$fasciculesCount fascicule${fasciculesCount > 1 ? 's' : ''}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[500],
                        fontWeight: FontWeight.w500,
                      ),
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

  Widget _buildEmptyWidget(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.library_books_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Aucun contenu disponible',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryImage(String imageUrl, String slug) {
    // Images de catégories par défaut
    final categoryImages = {
      'mathematiques': 'https://images.unsplash.com/photo-1509228468518-180dd4864904?w=400',
      'physique': 'https://images.unsplash.com/photo-1636466497217-26a8cbeaf0aa?w=400',
      'chimie': 'https://images.unsplash.com/photo-1603126857599-f6e157fa2fe6?w=400',
      'informatique': 'https://images.unsplash.com/photo-1517077304055-6e89abbf09b0?w=400',
      'litterature': 'https://images.unsplash.com/photo-1481627834876-b7833e8f5570?w=400',
      'social-actions': 'https://images.unsplash.com/photo-1559027615-cd4628902d4a?w=400',
      'sciences': 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=400',
      'technologie': 'https://images.unsplash.com/photo-1518709268805-4e9042af2176?w=400',
    };

    // Essayer d'utiliser l'image de l'API d'abord, puis l'image par défaut basée sur le slug
    final finalImageUrl = imageUrl.isNotEmpty
        ? imageUrl
        : _findDefaultImageForSlug(slug, categoryImages);

    if (finalImageUrl.isNotEmpty) {
      return Image.network(
        finalImageUrl,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            color: Colors.grey[200],
            child: Center(
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                    : null,
                strokeWidth: 2,
                color: const Color(0xFF1E3A8A),
              ),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          // Si l'image de l'API échoue, essayer une image par défaut
          if (imageUrl.isNotEmpty) {
            final defaultImage = _findDefaultImageForSlug(slug, categoryImages);
            if (defaultImage.isNotEmpty && defaultImage != finalImageUrl) {
              return Image.network(
                defaultImage,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return _buildDefaultCategoryIcon();
                },
              );
            }
          }
          return _buildDefaultCategoryIcon();
        },
      );
    }

    return _buildDefaultCategoryIcon();
  }

  String _findDefaultImageForSlug(String slug, Map<String, String> categoryImages) {
    // Essayer le slug exact d'abord
    if (categoryImages.containsKey(slug.toLowerCase())) {
      return categoryImages[slug.toLowerCase()]!;
    }

    // Essayer de trouver une correspondance partielle
    final slugLower = slug.toLowerCase();
    for (final entry in categoryImages.entries) {
      if (slugLower.contains(entry.key) || entry.key.contains(slugLower)) {
        return entry.value;
      }
    }

    // Retourner une image par défaut générique
    return categoryImages['sciences'] ?? '';
  }

  Widget _buildDefaultCategoryIcon() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF1E3A8A).withValues(alpha: 0.8),
            const Color(0xFF3B82F6),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Center(
        child: Icon(
          Icons.book,
          size: 40,
          color: Colors.white,
        ),
      ),
    );
  }
}