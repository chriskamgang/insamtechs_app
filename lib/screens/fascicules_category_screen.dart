import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/library_provider.dart';
import '../utils/translation_helper.dart';

class FasciculesCategoryScreen extends StatefulWidget {
  final String slug;
  final String title;

  const FasciculesCategoryScreen({
    super.key,
    required this.slug,
    required this.title,
  });

  @override
  State<FasciculesCategoryScreen> createState() => _FasciculesCategoryScreenState();
}

class _FasciculesCategoryScreenState extends State<FasciculesCategoryScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _filteredFascicules = [];

  @override
  void initState() {
    super.initState();
    _loadFascicules();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadFascicules() async {
    final libraryProvider = context.read<LibraryProvider>();
    await libraryProvider.loadFasciculesByCategory(widget.slug);
    _updateFilteredFascicules();
  }

  void _updateFilteredFascicules() {
    final libraryProvider = context.read<LibraryProvider>();
    _filteredFascicules = libraryProvider.searchFascicules(_searchController.text);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: const Color(0xFF3B82F6),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadFascicules,
          ),
        ],
      ),
      body: Consumer<LibraryProvider>(
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
      ),
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
          hintText: 'Rechercher des fascicules...',
          prefixIcon: const Icon(Icons.search, color: Colors.grey),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, color: Colors.grey),
                  onPressed: () {
                    _searchController.clear();
                    _updateFilteredFascicules();
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        ),
        onChanged: (value) {
          _updateFilteredFascicules();
        },
      ),
    );
  }

  Widget _buildFasciculesContent(LibraryProvider libraryProvider) {
    if (libraryProvider.isLoadingFascicules) {
      return const Center(child: CircularProgressIndicator());
    }

    if (libraryProvider.hasFasciculesError) {
      return _buildErrorWidget(
        libraryProvider.fasciculesError!,
        _loadFascicules,
      );
    }

    if (_filteredFascicules.isEmpty) {
      if (_searchController.text.isNotEmpty) {
        return _buildEmptyWidget('Aucun fascicule trouvé pour "${_searchController.text}"');
      } else {
        return _buildEmptyWidget('Aucun fascicule disponible dans cette filière');
      }
    }

    return RefreshIndicator(
      onRefresh: _loadFascicules,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _filteredFascicules.length,
        itemBuilder: (context, index) {
          final fascicule = _filteredFascicules[index];
          return _buildFasciculeCard(fascicule);
        },
      ),
    );
  }

  Widget _buildFasciculeCard(Map<String, dynamic> fascicule) {
    final title = TranslationHelper.getTranslatedText(
      fascicule['titre'],
      defaultText: 'Fascicule sans titre',
    );
    final description = TranslationHelper.getTranslatedText(
      fascicule['description'],
      defaultText: '',
    );
    final level = TranslationHelper.getTranslatedText(
      fascicule['niveau'],
      defaultText: '',
    );
    final semester = TranslationHelper.getTranslatedText(
      fascicule['semestre'],
      defaultText: '',
    );
    final pages = fascicule['pages'] ?? 0;
    final pdfUrl = fascicule['pdf_url'] ?? fascicule['lien'] ?? '';
    final downloadCount = fascicule['download_count'] ?? 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          if (pdfUrl.isNotEmpty) {
            Navigator.pushNamed(
              context,
              '/pdf-viewer',
              arguments: {
                'url': pdfUrl,
                'title': title,
              },
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('PDF non disponible pour ce fascicule'),
                backgroundColor: Colors.orange,
              ),
            );
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // En-tête avec titre et badges
              Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (pdfUrl.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.red[200]!),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.picture_as_pdf,
                            size: 14,
                            color: Colors.red[600],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'PDF',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.red[600],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 12),

              // Badges niveau et semestre
              Row(
                children: [
                  if (level.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        level,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF3B82F6),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  if (level.isNotEmpty && semester.isNotEmpty)
                    const SizedBox(width: 8),
                  if (semester.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        semester,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.green[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                ],
              ),

              if (description.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    height: 1.4,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],

              const SizedBox(height: 16),

              // Statistiques et actions
              Row(
                children: [
                  // Statistiques
                  Row(
                    children: [
                      Icon(
                        Icons.article,
                        size: 16,
                        color: Colors.grey[500],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$pages pages',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[500],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Icon(
                        Icons.download,
                        size: 16,
                        color: Colors.grey[500],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$downloadCount téléchargements',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),

                  const Spacer(),

                  // Actions
                  Row(
                    children: [
                      IconButton(
                        onPressed: pdfUrl.isNotEmpty
                            ? () {
                                Navigator.pushNamed(
                                  context,
                                  '/pdf-viewer',
                                  arguments: {
                                    'url': pdfUrl,
                                    'title': title,
                                  },
                                );
                              }
                            : null,
                        icon: Icon(
                          Icons.visibility,
                          color: pdfUrl.isNotEmpty ? const Color(0xFF3B82F6) : Colors.grey,
                          size: 20,
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          // TODO: Télécharger le fascicule
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Téléchargement de "$title" commencé'),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        },
                        icon: Icon(
                          Icons.download,
                          color: Colors.grey[600],
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                ],
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
              backgroundColor: const Color(0xFF3B82F6),
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
            Icons.school_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Aucun fascicule trouvé',
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
}