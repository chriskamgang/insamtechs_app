import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/library_provider.dart';
import '../models/library_item.dart';
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
    // Use addPostFrameCallback to avoid calling setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadFascicules();
    });
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
    setState(() {
      _filteredFascicules = libraryProvider.libraryItems.where((item) {
        if (_searchController.text.isEmpty) return true;
        return item.title.toLowerCase().contains(_searchController.text.toLowerCase()) ||
               item.author.toLowerCase().contains(_searchController.text.toLowerCase());
      }).toList();
    });
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
    if (libraryProvider.state == LibraryLoadingState.loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (libraryProvider.state == LibraryLoadingState.error) {
      return _buildErrorWidget(
        libraryProvider.errorMessage ?? 'Erreur de chargement',
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

  Widget _buildFasciculeCard(dynamic fascicule) {
    // Convert dynamic to LibraryItem if needed
    final LibraryItem libraryItem;
    if (fascicule is LibraryItem) {
      libraryItem = fascicule;
    } else {
      // If it's a map, create a LibraryItem from it
      libraryItem = LibraryItem(
        id: fascicule['id'] ?? 0,
        titre: fascicule['titre'] ?? fascicule['intitule'] ?? 'Fascicule sans titre',
        description: fascicule['description'] ?? fascicule['descriptif'] ?? '',
        type: fascicule['type'] ?? 'Fascicule',
        auteur: fascicule['auteur'] ?? 'Auteur inconnu',
        lien: fascicule['lien'] ?? fascicule['pdf_url'] ?? fascicule['pdf_link'] ?? fascicule['url'] ?? '',
        image: fascicule['image'] ?? fascicule['img'] ?? '',
        categorie: fascicule['categorie'] ?? fascicule['category'] ?? '',
        annee: fascicule['annee'] ?? fascicule['year'] ?? null,
        slug: fascicule['slug'] ?? '',
        langue: fascicule['langue'] ?? fascicule['language'] ?? '',
        niveau: fascicule['niveau'] ?? '',
        taille: fascicule['taille'] ?? fascicule['size'] ?? null,
        format: fascicule['format'] ?? '',
        motsCles: fascicule['motsCles'] ?? fascicule['keywords'] ?? '',
        estPayant: fascicule['estPayant'] ?? fascicule['isPaid'] ?? false,
        prix: fascicule['prix'] ?? fascicule['price'] ?? '',
        datePublication: fascicule['datePublication'] ?? fascicule['publicationDate'] ?? '',
        nbPages: fascicule['pages'] ?? fascicule['nb_pages'] ?? fascicule['page_count'] ?? fascicule['nombre_pages'] ?? 0,
        editeur: fascicule['editeur'] ?? fascicule['publisher'] ?? '',
        isbn: fascicule['isbn'] ?? '',
        resume: fascicule['resume'] ?? fascicule['summary'] ?? '',
        nbTelechargements: fascicule['download_count'] ?? fascicule['downloads'] ?? fascicule['nb_downloads'] ?? 0,
        nbVues: fascicule['nbVues'] ?? fascicule['viewCount'] ?? 0,
        estDisponible: fascicule['estDisponible'] ?? fascicule['isAvailable'] ?? true,
        dateCreation: fascicule['dateCreation'] ?? fascicule['creationDate'] ?? '',
        dateMiseAJour: fascicule['dateMiseAJour'] ?? fascicule['updateDate'] ?? '',
      );
    }

    final title = TranslationHelper.getTranslatedText(
      libraryItem.title,
      defaultText: 'Fascicule sans titre',
    );
    final description = TranslationHelper.getTranslatedText(
      libraryItem.itemDescription,
      defaultText: '',
    );
    final level = TranslationHelper.getTranslatedText(
      libraryItem.level ?? '',
      defaultText: '',
    );
    final semester = ''; // Assuming semestre is not in the model

    final pages = libraryItem.pageCount;
    final pdfUrl = libraryItem.link ?? '';
    final downloadCount = libraryItem.downloadCount;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          if (pdfUrl != null && pdfUrl.isNotEmpty) {
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
                      title != 'Fascicule sans titre' ? title : 'Fascicule sans titre',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (pdfUrl != null && pdfUrl.isNotEmpty)
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
                      if (pages != null && pages > 0) ...[
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
                      ],
                      if (pages != null && pages > 0 && downloadCount > 0) const SizedBox(width: 16),
                      if (downloadCount > 0) ...[
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
                    ],
                  ),

                  const Spacer(),

                  // Actions
                  Row(
                    children: [
                      IconButton(
                        onPressed: pdfUrl != null && pdfUrl.isNotEmpty
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
                            : () {
                                // Afficher un message quand le PDF n'est pas disponible
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('PDF non disponible pour "$title"'),
                                    backgroundColor: Colors.orange,
                                  ),
                                );
                              },
                        icon: Icon(
                          Icons.visibility,
                          color: pdfUrl != null && pdfUrl.isNotEmpty ? const Color(0xFF3B82F6) : Colors.grey,
                          size: 20,
                        ),
                      ),
                      // Masquer l'icône de téléchargement comme demandé
                      /*
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
                      */
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