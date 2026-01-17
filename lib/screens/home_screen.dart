import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/course_provider.dart';
import '../providers/exam_provider.dart';
import '../providers/library_provider.dart';
import '../models/course.dart';
import '../models/library_item.dart';
import '../models/advertisement.dart';
import '../services/advertisement_service.dart';
import 'advertisement_detail_screen.dart';
import 'dart:async';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  int _currentAdIndex = 0;
  late PageController _pageController;
  Timer? _adTimer;
  List<Advertisement> _advertisements = [];
  bool _adsLoading = true;
  final AdvertisementService _advertisementService = AdvertisementService();

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    // Charger les catégories, livres, épreuves et publicités dès que l'écran est construit
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<CourseProvider>(context, listen: false).loadCategories();
      // Charger les livres de la bibliothèque (limité aux 5 premiers)
      Provider.of<LibraryProvider>(context, listen: false).loadLibraryItems(type: 'livre');
      // Charger les meilleures épreuves (limité aux 5 premières)
      Provider.of<ExamProvider>(context, listen: false).loadFeaturedExams(limit: 5);
      // Charger les publicités depuis l'API
      _loadAdvertisements();
    });
  }

  Future<void> _loadAdvertisements() async {
    setState(() {
      _adsLoading = true;
    });

    try {
      final ads = await _advertisementService.getActiveAdvertisements();
      setState(() {
        _advertisements = ads;
        _adsLoading = false;
      });

      // Démarrer le timer seulement si on a des publicités
      if (_advertisements.isNotEmpty) {
        _startAdTimer();
      }
    } catch (e) {
      print('Error loading ads: $e');
      setState(() {
        _adsLoading = false;
      });
    }
  }

  void _startAdTimer() {
    _adTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (_pageController.hasClients) {
        int nextPage = (_currentAdIndex + 1) % _advertisements.length;
        _pageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _adTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bienvenue'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              // Navigate to settings
              Navigator.pushNamed(context, '/settings');
            },
          ),
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {
              // Navigate to notifications
              Navigator.pushNamed(context, '/notifications');
            },
          ),
        ],
      ),
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          final user = authProvider.user;
          String userName = 'Utilisateur';
          if (user != null) {
            userName = '${user.prenom} ${user.nom}';
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with user info
              Container(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: const Color(0xFF1E3A8A),
                      child: Text(
                        userName.substring(0, 1).toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Bonjour $userName !',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E3A8A),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Search bar
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Rechercher...',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: Colors.grey[100],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Advertisement Carousel
              _buildAdvertisementCarousel(screenWidth, screenHeight),

              const SizedBox(height: 16),

              // Sections with "Voir tout" buttons
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionHeader('Catégories', '/courses-categories'),
                      _buildCategoriesSection(screenWidth),

                      _buildSectionHeader('Cours Populaires', '/courses'),
                      _buildPopularCoursesSection(screenWidth),

                      _buildSectionHeader('Notre Bibliothèque', '/library'),
                      _buildLibrarySection(screenWidth),

                      _buildSectionHeader('Nos Meilleures Épreuves', '/courses'),
                      _buildBestExamsSection(screenWidth),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildAdvertisementCarousel(double screenWidth, double screenHeight) {
    // Si les publicités sont en cours de chargement
    if (_adsLoading) {
      return Container(
        height: screenHeight * 0.22,
        margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // Si aucune publicité n'est disponible
    if (_advertisements.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      height: screenHeight * 0.22,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentAdIndex = index;
              });
            },
            itemCount: _advertisements.length,
            itemBuilder: (context, index) {
              final ad = _advertisements[index];
              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AdvertisementDetailScreen(
                        advertisement: ad,
                      ),
                    ),
                  );
                },
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Stack(
                      children: [
                        // Background Image
                        Positioned.fill(
                          child: Image.network(
                            ad.imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: const Color(0xFF1E3A8A),
                                child: Center(
                                  child: Icon(
                                    Icons.image_not_supported,
                                    size: 60,
                                    color: Colors.white.withValues(alpha: 0.5),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        // Gradient Overlay
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  Colors.black.withValues(alpha: 0.7),
                                ],
                              ),
                            ),
                          ),
                        ),
                        // Content
                        Positioned(
                          bottom: 16,
                          left: 16,
                          right: 16,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                ad.appName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                ad.title,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.9),
                                  fontSize: 14,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          // Indicators
          Positioned(
            bottom: 8,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _advertisements.length,
                (index) => Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _currentAdIndex == index ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    color: _currentAdIndex == index
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.5),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, String route) {
    if (title == 'Catégories') {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Row(
              children: [
                IconButton(
                  icon: Icon(Icons.refresh, size: 20),
                  onPressed: () {
                    Provider.of<CourseProvider>(context, listen: false).loadCategories();
                  },
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pushNamed(context, route);
                  },
                  child: const Text('Voir tout'),
                ),
              ],
            ),
          ],
        ),
      );
    } else {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pushNamed(context, route);
              },
              child: const Text('Voir tout'),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildCategoriesSection(double screenWidth) {
    return Consumer<CourseProvider>(
      builder: (context, courseProvider, child) {
        // Force le rechargement des catégories si elles sont vides
        if (courseProvider.categories.isEmpty && courseProvider.state != CourseLoadingState.loading) {
          courseProvider.loadCategories();
        }

        final categories = courseProvider.categories;

        if (courseProvider.state == CourseLoadingState.loading && categories.isEmpty) {
          return const SizedBox(
            height: 100,
            child: Center(
              child: CircularProgressIndicator(
                color: Color(0xFF1E3A8A),
              ),
            ),
          );
        }

        if (categories.isEmpty) {
          return const SizedBox(
            height: 100,
            child: Center(
              child: Text('Aucune catégorie disponible'),
            ),
          );
        }

        return SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: categories.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.only(left: 16.0),
                child: _buildCategoryCard(categories[index], screenWidth),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildCategoryCard(CourseCategory category, double screenWidth) {
    return Container(
      width: screenWidth * 0.4,
      margin: const EdgeInsets.only(right: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () {
          // Navigate to category screen
          Navigator.pushNamed(
            context,
            '/courses-by-category',
            arguments: {
              'slug': category.slug,
              'title': category.name,
            },
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.school, // University hat icon
                size: 30,
                color: const Color(0xFF1E3A8A),
              ),
              const SizedBox(height: 6),
              Flexible(
                child: Text(
                  category.name,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPopularCoursesSection(double screenWidth) {
    return Consumer<CourseProvider>(
      builder: (context, courseProvider, child) {
        final courses = courseProvider.courses.take(4).toList(); // Take first 4 courses

        if (courseProvider.state == CourseLoadingState.loading && courses.isEmpty) {
          return const SizedBox(
            height: 200,
            child: Center(
              child: CircularProgressIndicator(
                color: Color(0xFF1E3A8A),
              ),
            ),
          );
        }

        if (courses.isEmpty) {
          return const SizedBox(
            height: 200,
            child: Center(
              child: Text('Aucun cours disponible'),
            ),
          );
        }

        return SizedBox(
          height: 200,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: courses.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.only(left: 16.0),
                child: _buildCourseCard(courses[index], screenWidth),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildCourseCard(Course course, double screenWidth) {
    return Container(
      width: screenWidth * 0.6,
      margin: const EdgeInsets.only(right: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () {
          Navigator.pushNamed(
            context,
            '/course-detail',
            arguments: {
              'courseTitle': course.title,
              'instructor': course.instructor,
              'rating': course.rating,
              'price': course.price,
              'description': course.courseDescription,
              'slug': course.slug,
            },
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Course image section with favorite icon
            Container(
              height: 100,
              decoration: BoxDecoration(
                color: const Color(0xFF1E3A8A),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              ),
              child: Stack(
                children: [
                  // Course image
                  if (course.imageUrl != null && course.imageUrl!.isNotEmpty)
                    Positioned.fill(
                      child: ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                        child: Image.network(
                          course.imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            // Fallback to icon if image fails to load
                            return Container(
                              color: const Color(0xFF1E3A8A),
                              child: const Center(
                                child: Icon(
                                  Icons.school,
                                  size: 30,
                                  color: Colors.white,
                                ),
                              ),
                            );
                          },
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Container(
                              color: const Color(0xFF1E3A8A),
                              child: const Center(
                                child: CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    )
                  else
                    // Fallback icon if no image URL
                    const Center(
                      child: Icon(
                        Icons.school,
                        size: 30,
                        color: Colors.white,
                      ),
                    ),
                  // Favorite icon
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        Icons.bookmark_border,
                        size: 16,
                        color: const Color(0xFF1E3A8A),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Title section below the blue background
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    course.title,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    course.instructor,
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(
                        Icons.star,
                        size: 12,
                        color: Colors.amber[600],
                      ),
                      const SizedBox(width: 2),
                      Text(
                        course.rating.toStringAsFixed(1),
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLibrarySection(double screenWidth) {
    return Consumer<LibraryProvider>(
      builder: (context, libraryProvider, child) {
        // Utiliser les vrais livres de la bibliothèque
        final libraryItems = libraryProvider.libraryItems.take(5).toList();

        // Afficher un indicateur de chargement pendant le chargement
        if (libraryProvider.state == LibraryLoadingState.loading && libraryItems.isEmpty) {
          return const SizedBox(
            height: 150,
            child: Center(
              child: CircularProgressIndicator(
                color: Color(0xFF1E3A8A),
              ),
            ),
          );
        }

        // Afficher un message si aucun livre n'est disponible
        if (libraryItems.isEmpty) {
          return const SizedBox(
            height: 150,
            child: Center(
              child: Text('Aucun livre disponible'),
            ),
          );
        }

        return SizedBox(
          height: 150,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: libraryItems.length,
            itemBuilder: (context, index) {
              final item = libraryItems[index];
              return Padding(
                padding: const EdgeInsets.only(left: 16.0),
                child: _buildLibraryCard(item, screenWidth),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildLibraryCard(LibraryItem libraryItem, double screenWidth) {
    // Utiliser le type du document de la bibliothèque
    String docType = libraryItem.type;
    IconData icon = Icons.menu_book; // Icône par défaut pour les livres

    // Déterminer l'icône basée sur le type
    if (docType.toLowerCase().contains('fascicule')) {
      icon = Icons.article;
    } else if (docType.toLowerCase().contains('livre')) {
      icon = Icons.menu_book;
    }

    return Container(
      width: screenWidth * 0.5,
      margin: const EdgeInsets.only(right: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () {
          // Ouvrir directement le livre PDF
          if (libraryItem.link != null && libraryItem.link!.isNotEmpty) {
            Navigator.pushNamed(
              context,
              '/pdf-viewer',
              arguments: {
                'url': libraryItem.link,
                'title': libraryItem.title,
              },
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('PDF non disponible pour "${libraryItem.title}"'),
                backgroundColor: Colors.orange,
              ),
            );
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 40,
                color: const Color(0xFF1E3A8A),
              ),
              const SizedBox(height: 8),
              Text(
                libraryItem.title,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                docType,
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBestExamsSection(double screenWidth) {
    return Consumer<ExamProvider>(
      builder: (context, examProvider, child) {
        // Debug: Afficher les données brutes
        print('🔍 [HomeScreen] Featured exams raw: ${examProvider.featuredExams}');
        print('🔍 [HomeScreen] Featured exams type: ${examProvider.featuredExams.runtimeType}');

        // Utiliser les vraies épreuves en vedette
        final exams = examProvider.featuredExams;

        // Afficher un indicateur de chargement pendant le chargement
        if (examProvider.isLoadingFeatured) {
          return const SizedBox(
            height: 150,
            child: Center(
              child: CircularProgressIndicator(
                color: Color(0xFF1E3A8A),
              ),
            ),
          );
        }

        // Afficher un message si aucune épreuve n'est disponible
        if (exams.isEmpty) {
          return const SizedBox(
            height: 150,
            child: Center(
              child: Text('Aucune épreuve disponible'),
            ),
          );
        }

        return SizedBox(
          height: 150,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: exams.length,
            itemBuilder: (context, index) {
              try {
                final exam = exams[index];
                print('🔍 [HomeScreen] Building exam card for index $index: $exam');
                return Padding(
                  padding: const EdgeInsets.only(left: 16.0),
                  child: _buildExamCard(exam, screenWidth),
                );
              } catch (e) {
                print('❌ [HomeScreen] Error building exam card: $e');
                return const SizedBox.shrink();
              }
            },
          ),
        );
      },
    );
  }

  Widget _buildExamCard(Map<String, dynamic> exam, double screenWidth) {
    // Debug: Afficher la structure des données de l'épreuve
    print('🔍 [HomeScreen] Exam data: $exam');

    // Helper pour extraire une valeur multilangue
    String _extractString(dynamic value, {String defaultValue = 'Épreuve'}) {
      if (value == null) return defaultValue;
      if (value is String) return value;
      if (value is Map) {
        return value['fr']?.toString() ?? value['en']?.toString() ?? defaultValue;
      }
      return value.toString();
    }

    // Extraire les données de l'épreuve
    final title = _extractString(exam['titre'] ?? exam['title'] ?? exam['intitule']);
    final formationId = exam['formation_id'] ?? exam['formationId'] ?? exam['id'] ?? 0;
    final formationTitle = _extractString(exam['formation_titre'] ?? exam['formation_title'] ?? exam['titre']);

    // Extraire l'image de la formation
    String? imageUrl;
    final formation = exam['formation'];
    if (formation != null && formation is Map) {
      final img = formation['img'] ?? formation['image'];
      if (img != null && img.toString().isNotEmpty) {
        final imgPath = img.toString();
        if (imgPath.startsWith('http://') || imgPath.startsWith('https://')) {
          imageUrl = imgPath;
        } else {
          String cleanPath = imgPath;
          if (cleanPath.startsWith('/')) cleanPath = cleanPath.substring(1);
          if (!cleanPath.startsWith('storage/')) cleanPath = 'storage/$cleanPath';
          imageUrl = 'https://admin.insamtechs.com/$cleanPath';
        }
      }
    }

    print('🔍 [HomeScreen] Extracted - title: $title, formationId: $formationId, formationTitle: $formationTitle, imageUrl: $imageUrl');

    return Container(
      width: screenWidth * 0.5,
      margin: const EdgeInsets.only(right: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () {
          // Naviguer vers la page d'examen seulement si formationId est valide
          if (formationId > 0) {
            Navigator.pushNamed(
              context,
              '/exam-detail',
              arguments: {
                'formationId': formationId,
                'formationTitle': formationTitle,
              },
            );
          } else {
            // Afficher un message si l'épreuve n'est pas disponible
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Épreuve non disponible pour "$title"'),
                backgroundColor: Colors.orange,
              ),
            );
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image de la formation ou icône par défaut
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                child: imageUrl != null
                    ? Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: const Color(0xFF1E3A8A).withValues(alpha: 0.1),
                            child: const Icon(
                              Icons.quiz,
                              size: 40,
                              color: Color(0xFF1E3A8A),
                            ),
                          );
                        },
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            color: Colors.grey[200],
                            child: const Center(
                              child: CircularProgressIndicator(
                                color: Color(0xFF1E3A8A),
                                strokeWidth: 2,
                              ),
                            ),
                          );
                        },
                      )
                    : Container(
                        color: const Color(0xFF1E3A8A).withValues(alpha: 0.1),
                        child: const Icon(
                          Icons.quiz,
                          size: 40,
                          color: Color(0xFF1E3A8A),
                        ),
                      ),
              ),
            ),
            // Titre et type
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Épreuve',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.2),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
          _navigateToPage(index);
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: const Color(0xFF1E3A8A),
        unselectedItemColor: Colors.grey[400],
        elevation: 0,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Accueil',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.school),
            label: 'Cours',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.menu_book),
            label: 'Bibliothèque',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.message),
            label: 'Messages',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profil',
          ),
        ],
      ),
    );
  }

  void _navigateToPage(int index) {
    switch (index) {
      case 0:
        // Already on home
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
  }
}