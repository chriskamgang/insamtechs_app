import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/library_provider.dart';
import '../models/library_category.dart';
import '../models/fascicule_filiere.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    final provider = Provider.of<LibraryProvider>(context, listen: false);
    await provider.loadLibraryCategories();
    await provider.loadFilieres();
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
          'Bibliothèque numérique',
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
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _loadData();
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
                      libraryProvider.errorMessage ?? 'Impossible de charger les données',
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
                      _loadData();
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

          return TabBarView(
            controller: _tabController,
            children: [
              // Livres Tab - Show categories
              _buildCategoriesTab(libraryProvider.libraryCategories, screenWidth, screenHeight),

              // Fascicules Tab - Show filieres
              _buildFilieresTab(libraryProvider.filieres, screenWidth, screenHeight),
            ],
          );
        },
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildCategoriesTab(List<LibraryCategory> categories, double screenWidth, double screenHeight) {
    if (categories.isEmpty) {
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
              'Aucune catégorie trouvée',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _loadData(),
      child: ListView.builder(
        padding: EdgeInsets.all(screenWidth * 0.04),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          return _buildCategoryCard(category, screenWidth);
        },
      ),
    );
  }

  Widget _buildFilieresTab(List<FasciculeFiliere> filieres, double screenWidth, double screenHeight) {
    if (filieres.isEmpty) {
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
              'Aucune filière trouvée',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _loadData(),
      child: ListView.builder(
        padding: EdgeInsets.all(screenWidth * 0.04),
        itemCount: filieres.length,
        itemBuilder: (context, index) {
          final filiere = filieres[index];
          return _buildFiliereCard(filiere, screenWidth);
        },
      ),
    );
  }

  Widget _buildCategoryCard(LibraryCategory category, double screenWidth) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          Navigator.pushNamed(
            context,
            '/books-category',
            arguments: {
              'slug': category.slug,
              'title': category.nom,
            },
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Category Image or Icon
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.blue[50],
                ),
                child: (category.imageUrl != null)
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          category.imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(
                              Icons.menu_book,
                              size: 40,
                              color: Colors.blue[300],
                            );
                          },
                        ),
                      )
                    : Icon(
                        Icons.menu_book,
                        size: 40,
                        color: Colors.blue[300],
                      ),
              ),
              const SizedBox(width: 16),
              // Category Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category.nom,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${category.itemCount} ${category.itemCount > 1 ? "livres" : "livre"}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              // Arrow Icon
              Icon(
                Icons.chevron_right,
                color: Colors.grey[400],
                size: 28,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFiliereCard(FasciculeFiliere filiere, double screenWidth) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          // Navigate to fascicule list by filiere
          Navigator.pushNamed(
            context,
            '/fascicules-series',
            arguments: {
              'slug': filiere.slug,
              'title': filiere.intitule,
            },
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Filiere Image or Icon
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.blue[50],
                ),
                child: (filiere.imageUrl != null)
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          filiere.imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(
                              Icons.school,
                              size: 40,
                              color: Colors.blue[300],
                            );
                          },
                        ),
                      )
                    : Icon(
                        Icons.school,
                        size: 40,
                        color: Colors.blue[300],
                      ),
              ),
              const SizedBox(width: 16),
              // Filiere Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      filiere.intitule,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${filiere.fasciculesCount} ${filiere.fasciculesCount > 1 ? "fascicules" : "fascicule"}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              // Arrow Icon
              Icon(
                Icons.chevron_right,
                color: Colors.grey[400],
                size: 28,
              ),
            ],
          ),
        ),
      ),
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
          _buildNavItem(Icons.person, 'Profil', 4),
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
      case '/profile':
        currentIndex = 4;
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
    super.dispose();
  }
}
