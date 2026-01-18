import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/library_provider.dart';
import '../models/library_item.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> with TickerProviderStateMixin {
  int _selectedIndex = 2;
  late TabController _tabController;
  String _selectedCategory = 'Toutes';
  String _selectedType = 'Tous';
  String _searchQuery = '';
  TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialData();
    });
  }

  Future<void> _loadInitialData() async {
    Provider.of<LibraryProvider>(context, listen: false).loadTypes(); // Load filieres for types
    await _refreshLibraryItems();
  }

  Future<void> _refreshLibraryItems() async {
    await Provider.of<LibraryProvider>(context, listen: false).loadLibraryItems(
      category: _selectedCategory == 'Toutes' ? null : _selectedCategory,
      type: _selectedType == 'Tous' ? null : _selectedType,
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E3A8A),
        foregroundColor: Colors.white,
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Color(0xFF1E3A8A),
          statusBarIconBrightness: Brightness.light,
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Text(
          'Bibliothèque Numérique',
          style: TextStyle(
            fontSize: screenWidth * 0.055,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: false,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white.withValues(alpha: 0.7),
          indicatorColor: Colors.white,
          tabs: const [
            Tab(
              icon: Icon(Icons.menu_book),
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
            icon: const Icon(Icons.search),
            onPressed: () {
              _showSearchDialog(screenWidth);
            },
          ),
        ],
      ),
      body: Consumer<LibraryProvider>(
        builder: (context, libraryProvider, child) {
          if (libraryProvider.state == LibraryLoadingState.loading) {
            return const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF1E3A8A),
              ),
            );
          }

          if (libraryProvider.state == LibraryLoadingState.error) {
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
                      libraryProvider.errorMessage ?? 'Impossible de charger les documents',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[500],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () {
                      _refreshLibraryItems();
                    },
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

          // Use library items (books and fascicles)
          final allItems = libraryProvider.libraryItems;

          // Separate books and fascicules based on type
          final books = allItems.where((item) {
            final type = item.type.toLowerCase();
            final title = item.title.toLowerCase();
            return type.contains('livre') ||
                   type.contains('manuel') ||
                   type.contains('texte') ||
                   type.contains('encyclopedie') ||
                   type.contains('grammaire') ||
                   type.contains('dictionnaire') ||
                   type.contains('roman') ||
                   type.contains('biographie') ||
                   type.contains('memoire') ||
                   type.contains('these') ||
                   (!type.contains('fascicule') &&
                    !type.contains('exercice') &&
                    !type.contains('corrigé') &&
                    !type.contains('epreuve') &&
                    !type.contains('concours') &&
                    !type.contains('examen') &&
                    !type.contains('devoir') &&
                    !type.contains('td') &&
                    !type.contains('tp') &&
                    !title.contains('fascicule') &&
                    !title.contains('exercice') &&
                    !title.contains('corrigé') &&
                    !title.contains('epreuve') &&
                    !title.contains('concours') &&
                    !title.contains('examen') &&
                    !title.contains('devoir') &&
                    !title.contains('td') &&
                    !title.contains('tp'));
          }).toList();

          final fascicules = allItems.where((item) {
            final type = item.type.toLowerCase();
            final title = item.title.toLowerCase();
            // Look for indicators of fascicules/exercises in the type or title
            return type.contains('fascicule') ||
                   type.contains('exercice') ||
                   type.contains('corrigé') ||
                   type.contains('epreuve') ||
                   type.contains('concours') ||
                   type.contains('examen') ||
                   type.contains('devoir') ||
                   type.contains('td') || // Travaux dirigés
                   type.contains('tp') || // Travaux pratiques
                   title.contains('fascicule') ||
                   title.contains('exercice') ||
                   title.contains('corrigé') ||
                   title.contains('epreuve') ||
                   title.contains('concours') ||
                   title.contains('examen') ||
                   title.contains('devoir') ||
                   title.contains('td') ||
                   title.contains('tp');
          }).toList();

          return TabBarView(
            controller: _tabController,
            children: [
              // Books Tab
              _buildLibraryTab(books, 'Aucun livre disponible', screenWidth, screenHeight),

              // Fascicules Tab
              _buildLibraryTab(fascicules, 'Aucun fascicule disponible', screenWidth, screenHeight),
            ],
          );
        },
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildLibraryTab(List<LibraryItem> items, String emptyMessage, double screenWidth, double screenHeight) {
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.menu_book_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Aucun document trouvé',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              emptyMessage,
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

    return RefreshIndicator(
      onRefresh: () => _refreshLibraryItems(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
          child: Column(
            children: [
              SizedBox(height: screenHeight * 0.02),


              SizedBox(height: screenHeight * 0.02),

              // Library Items Grid
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.8,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
                  return _buildLibraryItemCard(item, screenWidth);
                },
              ),

              SizedBox(height: screenHeight * 0.02),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLibraryItemCard(LibraryItem item, double screenWidth) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          // Navigate to PDF viewer with the document link
          if (item.link != null && item.link!.isNotEmpty) {
            Navigator.pushNamed(
              context,
              '/pdf-viewer',
              arguments: {
                'url': item.link!,
                'title': item.title,
              },
            );
          } else {
            // Show error if no link is available
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Lien du document indisponible'),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          height: 200, // Fixed height to prevent overflow
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Document Image
              Expanded(
                flex: 3,
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                    color: Colors.grey[200],
                    image: (item.imageUrl?.isNotEmpty ?? false)
                        ? DecorationImage(
                            image: NetworkImage(item.imageUrl!),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: (item.imageUrl?.isEmpty ?? true)
                      ? const Center(
                          child: Icon(
                            Icons.menu_book,
                            size: 40,
                            color: Colors.grey,
                          ),
                        )
                      : null,
                ),
              ),

              // Document Details
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              item.title,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              item.author,
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[600],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            item.type.toLowerCase().contains('fascicule')
                              ? Icons.article
                              : Icons.book,
                            size: 14,
                            color: Colors.blue[600],
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              item.itemType,
                              style: const TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            item.isPaid ? '${item.price}€' : 'Gratuit',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E3A8A),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSearchDialog(double screenWidth) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Rechercher un document'),
          content: TextField(
            controller: _searchController,
            decoration: const InputDecoration(
              hintText: 'Entrez votre recherche...',
              prefixIcon: Icon(Icons.search),
            ),
            onSubmitted: (value) {
              setState(() {
                _searchQuery = value;
              });
              _refreshLibraryItems();
              Navigator.of(context).pop();
            },
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Annuler'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _searchQuery = _searchController.text;
                });
                _refreshLibraryItems();
                Navigator.of(context).pop();
              },
              child: const Text('Rechercher'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.3),
            spreadRadius: 1,
            blurRadius: 10,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(Icons.home, 'Accueil', 0),
          _buildNavItem(Icons.school, 'Cours', 1),
          _buildNavItem(Icons.menu_book, 'Bibliothèque', 2),
          _buildNavItem(Icons.message, 'Messages', 3),
          _buildNavItem(Icons.notifications, 'Notifications', 4),
          _buildNavItem(Icons.person, 'Profil', 5),
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    // Determine selected index based on current route
    int currentIndex = 0;
    String currentRoute = ModalRoute.of(context)?.settings.name ?? '';

    switch(currentRoute) {
      case '/home':
        currentIndex = 0;
        break;
      case '/courses':
        currentIndex = 1;
        break;
      case '/library':
        currentIndex = 2;
        break;
      case '/messages':
        currentIndex = 3;
        break;
      case '/notifications':
        currentIndex = 4;
        break;
      case '/profile':
        currentIndex = 5;
        break;
    }

    final isSelected = currentIndex == index;
    return GestureDetector(
      onTap: () {
        switch (index) {
          case 0:
            Navigator.pushReplacementNamed(context, '/home');
            break;
          case 1:
            Navigator.pushReplacementNamed(context, '/courses');
            break;
          case 2:
            Navigator.pushReplacementNamed(context, '/library');
            break;
          case 3:
            Navigator.pushReplacementNamed(context, '/messages');
            break;
          case 4:
            Navigator.pushReplacementNamed(context, '/notifications');
            break;
          case 5:
            Navigator.pushReplacementNamed(context, '/profile');
            break;
        }
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: isSelected ? const Color(0xFF1E3A8A) : Colors.grey,
            size: 24,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? const Color(0xFF1E3A8A) : Colors.grey,
              fontSize: 10,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }
}