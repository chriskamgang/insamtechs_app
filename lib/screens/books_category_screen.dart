import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/library_provider.dart';
import '../models/library_item.dart';
import '../services/offline_download_service.dart';
import '../utils/translation_helper.dart';

class BooksCategoryScreen extends StatefulWidget {
  final String slug;
  final String title;

  const BooksCategoryScreen({
    super.key,
    required this.slug,
    required this.title,
  });

  @override
  State<BooksCategoryScreen> createState() => _BooksCategoryScreenState();
}

class _BooksCategoryScreenState extends State<BooksCategoryScreen> {
  final TextEditingController _searchController = TextEditingController();
  final OfflineDownloadService _downloadService = OfflineDownloadService();
  List<dynamic> _filteredBooks = [];
  Map<String, double> _downloadProgress = {};

  @override
  void initState() {
    super.initState();
    // Use addPostFrameCallback to avoid calling setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadBooks();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadBooks() async {
    final libraryProvider = context.read<LibraryProvider>();
    await libraryProvider.loadLibraryItemsByCategory(widget.slug);
    _updateFilteredBooks();
  }

  void _updateFilteredBooks() {
    final libraryProvider = context.read<LibraryProvider>();
    setState(() {
      _filteredBooks = libraryProvider.libraryItems.where((item) {
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
        backgroundColor: const Color(0xFF1E3A8A),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadBooks,
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
                child: _buildBooksContent(libraryProvider),
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
          hintText: 'Rechercher des livres...',
          prefixIcon: const Icon(Icons.search, color: Colors.grey),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, color: Colors.grey),
                  onPressed: () {
                    _searchController.clear();
                    _updateFilteredBooks();
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        ),
        onChanged: (value) {
          _updateFilteredBooks();
        },
      ),
    );
  }

  Widget _buildBooksContent(LibraryProvider libraryProvider) {
    if (libraryProvider.state == LibraryLoadingState.loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (libraryProvider.state == LibraryLoadingState.error) {
      return _buildErrorWidget(
        libraryProvider.errorMessage ?? 'Erreur de chargement',
        _loadBooks,
      );
    }

    if (_filteredBooks.isEmpty) {
      if (_searchController.text.isNotEmpty) {
        return _buildEmptyWidget('Aucun livre trouvé pour "${_searchController.text}"');
      } else {
        return _buildEmptyWidget('Aucun livre disponible dans cette catégorie');
      }
    }

    return RefreshIndicator(
      onRefresh: _loadBooks,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _filteredBooks.length,
        itemBuilder: (context, index) {
          final book = _filteredBooks[index];
          return _buildBookCard(book);
        },
      ),
    );
  }

  Widget _buildBookCard(dynamic book) {
    // Convert dynamic to LibraryItem if needed
    final LibraryItem libraryItem;
    if (book is LibraryItem) {
      libraryItem = book;
    } else {
      // If it's a map, create a LibraryItem from it
      libraryItem = LibraryItem(
        id: book['id'] ?? 0,
        titre: book['titre'] ?? book['intitule'] ?? book['nom'] ?? 'Livre sans titre',
        description: book['description'] ?? '',
        type: book['type'] ?? 'Livre',
        auteur: book['auteur'] ?? book['author'] ?? book['ecrivain'] ?? 'Auteur inconnu',
        lien: book['lien'] ?? book['pdf_url'] ?? '',
        image: book['cover_url'] ?? book['img'] ?? '',
        categorie: book['categorie'] ?? book['category'] ?? '',
        annee: book['annee'] ?? book['year'] ?? null,
        slug: book['slug'] ?? '',
        langue: book['langue'] ?? book['language'] ?? '',
        niveau: book['niveau'] ?? book['level'] ?? '',
        taille: book['taille'] ?? book['size'] ?? null,
        format: book['format'] ?? '',
        motsCles: book['motsCles'] ?? book['keywords'] ?? '',
        estPayant: book['estPayant'] ?? book['isPaid'] ?? false,
        prix: book['prix'] ?? book['price'] ?? '',
        datePublication: book['datePublication'] ?? book['publicationDate'] ?? '',
        nbPages: book['pages'] ?? book['nombre_pages'] ?? book['page_count'] ?? 0,
        editeur: book['editeur'] ?? book['publisher'] ?? '',
        isbn: book['isbn'] ?? '',
        resume: book['resume'] ?? book['summary'] ?? '',
        nbTelechargements: book['nbTelechargements'] ?? book['downloadCount'] ?? 0,
        nbVues: book['nbVues'] ?? book['viewCount'] ?? 0,
        estDisponible: book['estDisponible'] ?? book['isAvailable'] ?? true,
        dateCreation: book['dateCreation'] ?? book['creationDate'] ?? '',
        dateMiseAJour: book['dateMiseAJour'] ?? book['updateDate'] ?? '',
      );
    }

    final title = TranslationHelper.getTranslatedText(
      libraryItem.title,
      defaultText: 'Livre sans titre',
    );
    final author = TranslationHelper.getTranslatedText(
      libraryItem.author,
      defaultText: 'Auteur inconnu',
    );
    final description = TranslationHelper.getTranslatedText(
      libraryItem.itemDescription,
      defaultText: '',
    );
    final pages = libraryItem.pageCount;
    final pdfUrl = libraryItem.link ?? '';
    final coverUrl = libraryItem.imageUrl ?? '';

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
                content: Text('PDF non disponible pour ce livre'),
                backgroundColor: Colors.orange,
              ),
            );
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Couverture du livre
              Container(
                width: 80,
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                  image: coverUrl.isNotEmpty
                      ? DecorationImage(
                          image: NetworkImage(coverUrl),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: coverUrl.isEmpty
                    ? const Icon(
                        Icons.book,
                        size: 40,
                        color: Colors.grey,
                      )
                    : null,
              ),
              const SizedBox(width: 16),

              // Informations du livre
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
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Par $author',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    if (description.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        description,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[500],
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 8),
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
                          if (pdfUrl != null && pdfUrl.isNotEmpty) const SizedBox(width: 16),
                        ],
                        if (pdfUrl != null && pdfUrl.isNotEmpty) ...[
                          Icon(
                            Icons.picture_as_pdf,
                            size: 16,
                            color: Colors.red[400],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'PDF',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.red[400],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              // Actions
              Column(
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
                        : null,
                    icon: Icon(
                      Icons.visibility,
                      color: pdfUrl != null && pdfUrl.isNotEmpty ? const Color(0xFF1E3A8A) : Colors.grey,
                    ),
                  ),
                  IconButton(
                    onPressed: pdfUrl != null && pdfUrl.isNotEmpty
                        ? () => _downloadPDF(libraryItem.id.toString(), title, pdfUrl!)
                        : null,
                    icon: Icon(
                      _downloadService.isDownloaded(libraryItem.id.toString())
                          ? Icons.download_done
                          : (_downloadProgress[libraryItem.id.toString()] != null
                              ? Icons.downloading
                              : Icons.download),
                      color: _downloadService.isDownloaded(libraryItem.id.toString())
                          ? Colors.green
                          : (pdfUrl != null && pdfUrl.isNotEmpty ? const Color(0xFF1E3A8A) : Colors.grey),
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
            Icons.book_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Aucun livre trouvé',
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

  Future<void> _downloadPDF(String bookId, String title, String pdfUrl) async {
    if (_downloadService.isDownloaded(bookId)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$title est déjà téléchargé'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _downloadProgress[bookId] = 0.0;
    });

    final success = await _downloadService.downloadPDF(
      pdfId: bookId,
      title: title,
      pdfUrl: pdfUrl,
      onProgress: (progress) {
        setState(() {
          _downloadProgress[bookId] = progress;
        });
      },
    );

    setState(() {
      _downloadProgress.remove(bookId);
    });

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$title téléchargé avec succès'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du téléchargement de $title'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}