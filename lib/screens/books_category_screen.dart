import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/library_provider.dart';
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
    _loadBooks();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadBooks() async {
    final libraryProvider = context.read<LibraryProvider>();
    await libraryProvider.loadBooksByCategory(widget.slug);
    _updateFilteredBooks();
  }

  void _updateFilteredBooks() {
    final libraryProvider = context.read<LibraryProvider>();
    _filteredBooks = libraryProvider.searchBooks(_searchController.text);
    setState(() {});
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
    if (libraryProvider.isLoadingBooks) {
      return const Center(child: CircularProgressIndicator());
    }

    if (libraryProvider.hasBooksError) {
      return _buildErrorWidget(
        libraryProvider.booksError!,
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

  Widget _buildBookCard(Map<String, dynamic> book) {
    final title = TranslationHelper.getTranslatedText(
      book['intitule'] ?? book['titre'] ?? book['nom'],
      defaultText: 'Livre sans titre',
    );
    final author = TranslationHelper.getTranslatedText(
      book['auteur'] ?? book['author'] ?? book['ecrivain'],
      defaultText: 'Auteur inconnu',
    );
    final description = TranslationHelper.getTranslatedText(
      book['description'],
      defaultText: '',
    );
    final pages = book['pages'] ?? book['nombre_pages'] ?? book['page_count'] ?? 0;
    final pdfUrl = book['lien'] ?? book['pdf_url'] ?? '';
    final coverUrl = book['cover_url'] ?? book['img'] ?? '';

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
                        if (pages > 0) ...[
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
                          if (pdfUrl.isNotEmpty) const SizedBox(width: 16),
                        ],
                        if (pdfUrl.isNotEmpty) ...[
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
                      color: pdfUrl.isNotEmpty ? const Color(0xFF1E3A8A) : Colors.grey,
                    ),
                  ),
                  IconButton(
                    onPressed: pdfUrl.isNotEmpty
                        ? () => _downloadPDF(book['id']?.toString() ?? '', title, pdfUrl)
                        : null,
                    icon: Icon(
                      _downloadService.isDownloaded(book['id']?.toString() ?? '')
                          ? Icons.download_done
                          : (_downloadProgress[book['id']?.toString() ?? ''] != null
                              ? Icons.downloading
                              : Icons.download),
                      color: _downloadService.isDownloaded(book['id']?.toString() ?? '')
                          ? Colors.green
                          : (pdfUrl.isNotEmpty ? const Color(0xFF1E3A8A) : Colors.grey),
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