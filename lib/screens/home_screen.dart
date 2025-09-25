import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/course_provider.dart';
import '../providers/enrollment_provider.dart';
import '../providers/wishlist_provider.dart';
import '../providers/library_provider.dart';
import '../models/course.dart';
import '../utils/translation_helper.dart';
import '../widgets/wishlist_button.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    print('🏠 [HomeScreen] initState() - Initializing home screen');
    super.initState();
    // Defer loading to after the first frame to avoid setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadUserEnrollments();
      _loadLibraryContent();
    });
  }

  Future<void> _loadUserEnrollments() async {
    print('🏠 [HomeScreen] _loadUserEnrollments() - Starting to load user enrollments');
    final authProvider = context.read<AuthProvider>();
    final userId = authProvider.user?.id;
    if (authProvider.isAuthenticated && userId != null) {
      print('🏠 [HomeScreen] _loadUserEnrollments() - User authenticated, loading data for user ID: $userId');
      final enrollmentProvider = context.read<EnrollmentProvider>();
      final wishlistProvider = context.read<WishlistProvider>();

      try {
        await Future.wait([
          enrollmentProvider.refreshUserEnrollments(userId),
          wishlistProvider.loadUserWishlist(userId),
        ]);
        print('✅ [HomeScreen] _loadUserEnrollments() - Successfully loaded user enrollments and wishlist');
      } catch (e) {
        print('❌ [HomeScreen] _loadUserEnrollments() - Error loading user data: ${e.toString()}');
      }
    } else {
      print('⚠️ [HomeScreen] _loadUserEnrollments() - User not authenticated, skipping enrollment load');
    }
  }

  Future<void> _loadLibraryContent() async {
    print('🏠 [HomeScreen] _loadLibraryContent() - Loading library content');
    try {
      await context.read<LibraryProvider>().loadLibraryContent();
      print('✅ [HomeScreen] _loadLibraryContent() - Successfully loaded library content');
    } catch (e) {
      print('❌ [HomeScreen] _loadLibraryContent() - Error loading library: ${e.toString()}');
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
        ),
        automaticallyImplyLeading: false,
        title: Consumer<AuthProvider>(
          builder: (context, authProvider, child) {
            final user = authProvider.user;
            final userName = user?.fullName ?? 'Étudiant';

            return Row(
              children: [
                Text(
                  'Bienvenue, ',
                  style: TextStyle(
                    fontSize: screenWidth * 0.05,
                    color: Colors.black,
                    fontWeight: FontWeight.normal,
                  ),
                ),
                Expanded(
                  child: Text(
                    userName,
                    style: TextStyle(
                      fontSize: screenWidth * 0.05,
                      color: const Color(0xFF1E3A8A),
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            );
          },
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.settings,
              color: Colors.grey[400],
              size: 28,
            ),
            onPressed: () {
              print('🏠 [HomeScreen] Settings button pressed - Navigating to settings');
              Navigator.pushNamed(context, '/settings');
            },
          ),
          IconButton(
            icon: Icon(
              Icons.notifications_outlined,
              color: Colors.grey[400],
              size: 28,
            ),
            onPressed: () {
              print('🏠 [HomeScreen] Notifications button pressed - Navigating to notifications');
              Navigator.pushNamed(context, '/notifications');
            },
          ),
        ],
      ),
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: RefreshIndicator(
        onRefresh: () async {
          await context.read<CourseProvider>().refresh();
          // Also refresh user enrollments and wishlist if authenticated
          if (mounted) {
            final authProvider = context.read<AuthProvider>();
            final userId = authProvider.user?.id;
            if (authProvider.isAuthenticated && userId != null) {
              await Future.wait([
                context.read<EnrollmentProvider>().refreshUserEnrollments(userId),
                context.read<WishlistProvider>().refreshWishlist(userId),
              ]);
            }
          }
        },
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: screenHeight * 0.02),

              // Search Bar
              _buildSearchBar(screenWidth),

              SizedBox(height: screenHeight * 0.03),

              // Categories
              _buildCategoriesSection(screenWidth),

              SizedBox(height: screenHeight * 0.02),

              SizedBox(height: screenHeight * 0.01),

              // My Enrolled Courses
              _buildMyCoursesSection(screenWidth, screenHeight),

              SizedBox(height: screenHeight * 0.03),

              // Featured Courses
              _buildFeaturedCoursesSection(screenWidth, screenHeight),

              SizedBox(height: screenHeight * 0.03),

              // Notre bibliothèque
              _buildLibrarySection(screenWidth, screenHeight),

              SizedBox(height: screenHeight * 0.03),

              // Nos meilleures épreuves
              _buildBestExamsSection(screenWidth, screenHeight),

              SizedBox(height: screenHeight * 0.02),
            ],
          ),
        ),
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(screenWidth),
    );
  }

  Widget _buildSearchBar(double screenWidth) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Rechercher des cours...',
          hintStyle: TextStyle(
            color: Colors.grey[500],
            fontSize: screenWidth * 0.04,
          ),
          prefixIcon: Icon(Icons.search, color: Colors.grey[500]),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.clear, color: Colors.grey[500]),
                  onPressed: () {
                    _searchController.clear();
                    context.read<CourseProvider>().loadCourses(refresh: true);
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        onSubmitted: (query) {
          if (query.trim().isNotEmpty) {
            context.read<CourseProvider>().searchCourses(query);
            // Navigate to courses screen with search results
            Navigator.pushNamed(context, '/courses');
          }
        },
      ),
    );
  }

  Widget _buildCategoriesSection(double screenWidth) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Catégories',
              style: TextStyle(
                fontSize: screenWidth * 0.05,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pushNamed(context, '/courses');
              },
              child: Text(
                'Voir tout',
                style: TextStyle(
                  color: const Color(0xFF1E3A8A),
                  fontSize: screenWidth * 0.035,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Consumer<CourseProvider>(
          builder: (context, courseProvider, child) {
            if (courseProvider.isLoading) {
              return const SizedBox(
                height: 80,
                child: Center(child: CircularProgressIndicator()),
              );
            }

            if (courseProvider.hasError) {
              return SizedBox(
                height: 80,
                child: Center(
                  child: Text(
                    'Erreur: ${courseProvider.errorMessage}',
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }

            return SizedBox(
              height: 80,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: courseProvider.categories.length,
                itemBuilder: (context, index) {
                  final category = courseProvider.categories[index];
                  return _buildCategoryCard(category, screenWidth);
                },
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildCategoryCard(CourseCategory category, double screenWidth) {
    return Container(
      width: screenWidth * 0.25,
      margin: const EdgeInsets.only(right: 12),
      child: InkWell(
        onTap: () {
          context.read<CourseProvider>().filterByCategory(category.slug);
          Navigator.pushNamed(context, '/courses');
        },
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1E3A8A).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _getCategoryIcon(category.name),
                size: 28,
                color: const Color(0xFF1E3A8A),
              ),
              const SizedBox(height: 4),
              Text(
                category.name,
                style: TextStyle(
                  fontSize: screenWidth * 0.025,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1E3A8A),
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String categoryName) {
    switch (categoryName.toLowerCase()) {
      case 'développement web':
      case 'web development':
        return Icons.code;
      case 'marketing digital':
      case 'digital marketing':
        return Icons.trending_up;
      case 'design graphique':
      case 'graphic design':
        return Icons.palette;
      default:
        return Icons.school;
    }
  }

  Widget _buildFeaturedCoursesSection(double screenWidth, double screenHeight) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Cours Populaires',
              style: TextStyle(
                fontSize: screenWidth * 0.05,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pushNamed(context, '/courses');
              },
              child: Text(
                'Voir tout',
                style: TextStyle(
                  color: const Color(0xFF1E3A8A),
                  fontSize: screenWidth * 0.035,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Consumer<CourseProvider>(
          builder: (context, courseProvider, child) {
            if (courseProvider.isLoading) {
              return SizedBox(
                height: screenHeight * 0.3,
                child: const Center(child: CircularProgressIndicator()),
              );
            }

            if (courseProvider.hasError) {
              return SizedBox(
                height: screenHeight * 0.3,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Erreur: ${courseProvider.errorMessage}',
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => courseProvider.refresh(),
                        child: const Text('Réessayer'),
                      ),
                    ],
                  ),
                ),
              );
            }

            return SizedBox(
              height: screenHeight * 0.3,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: courseProvider.featuredCourses.length,
                itemBuilder: (context, index) {
                  final course = courseProvider.featuredCourses[index];
                  return _buildCourseCard(course, screenWidth, screenHeight);
                },
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildCourseCard(Course course, double screenWidth, double screenHeight) {
    return Container(
      width: screenWidth * 0.7,
      margin: const EdgeInsets.only(right: 16),
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
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withValues(alpha: 0.1),
                spreadRadius: 1,
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Course Image
              Stack(
                children: [
                  Container(
                    height: screenHeight * 0.15,
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                      color: Colors.grey[200],
                    ),
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                      child: course.imageUrl != null
                          ? Image.network(
                              course.imageUrl!,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return _buildPlaceholderImage(course.title, screenHeight * 0.15);
                              },
                            )
                          : _buildPlaceholderImage(course.title, screenHeight * 0.15),
                    ),
                  ),
                  // Wishlist Button
                  Positioned(
                    top: 8,
                    right: 8,
                    child: WishlistButton(
                      formationId: course.id,
                      size: 20,
                    ),
                  ),
                ],
              ),

              // Course Info
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        course.title,
                        style: TextStyle(
                          fontSize: screenWidth * 0.04,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        course.instructor,
                        style: TextStyle(
                          fontSize: screenWidth * 0.03,
                          color: Colors.grey[600],
                        ),
                      ),
                      const Spacer(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.star,
                                color: Colors.amber,
                                size: screenWidth * 0.04,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                course.rating.toString(),
                                style: TextStyle(
                                  fontSize: screenWidth * 0.035,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            '${course.price}€',
                            style: TextStyle(
                              fontSize: screenWidth * 0.04,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF1E3A8A),
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

  Widget _buildPlaceholderImage(String title, double height) {
    return Container(
      width: double.infinity,
      height: height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF1E3A8A).withOpacity(0.7),
            const Color(0xFF3B82F6).withOpacity(0.7),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.school,
              color: Colors.white,
              size: 40,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavigationBar(double screenWidth) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.transparent,
        elevation: 0,
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });

          switch (index) {
            case 0:
              // Already on home
              break;
            case 1:
              Navigator.pushNamed(context, '/courses');
              break;
            case 2:
              Navigator.pushNamed(context, '/messages');
              break;
            case 3:
              Navigator.pushNamed(context, '/profile');
              break;
          }
        },
        selectedItemColor: const Color(0xFF1E3A8A),
        unselectedItemColor: Colors.grey[400],
        selectedLabelStyle: TextStyle(fontSize: screenWidth * 0.03),
        unselectedLabelStyle: TextStyle(fontSize: screenWidth * 0.03),
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

  Widget _buildMyCoursesSection(double screenWidth, double screenHeight) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        if (!authProvider.isAuthenticated) {
          return const SizedBox.shrink();
        }

        return Consumer<EnrollmentProvider>(
          builder: (context, enrollmentProvider, child) {
            if (enrollmentProvider.userEnrollments.isEmpty) {
              return const SizedBox.shrink();
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Mes cours',
                      style: TextStyle(
                        fontSize: screenWidth * 0.055,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () {
                        Navigator.pushNamed(context, '/courses');
                      },
                      child: Text(
                        'Voir tout',
                        style: TextStyle(
                          fontSize: screenWidth * 0.035,
                          color: const Color(0xFF1E3A8A),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: screenHeight * 0.25,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: enrollmentProvider.userEnrollments.take(5).length,
                    itemBuilder: (context, index) {
                      final enrollment = enrollmentProvider.userEnrollments[index];
                      final formation = enrollment['formation'];

                      if (formation == null) {
                        return const SizedBox.shrink();
                      }

                      return Container(
                        width: screenWidth * 0.7,
                        margin: const EdgeInsets.only(right: 16),
                        child: _buildEnrolledCourseCard(formation, enrollment, screenWidth, screenHeight),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildEnrolledCourseCard(dynamic formation, dynamic enrollment, double screenWidth, double screenHeight) {
    // Extraire les données de formation depuis l'objet enrollment
    final title = TranslationHelper.getTranslatedText(formation['intitule'], defaultText: 'Formation');
    final description = TranslationHelper.getDescription(formation['description']);
    final prix = TranslationHelper.getPrice(formation['prix']);

    final slug = formation['slug'] ?? '';
    final imageUrl = formation['image'] ?? '';
    final etatCommande = enrollment['etat_commande'] ?? 0;
    final date = enrollment['date'] ?? '';

    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(
          context,
          '/course-detail',
          arguments: {
            'courseTitle': title,
            'instructor': 'INSAM Tech',
            'rating': 5.0,
            'price': prix,
            'description': description,
            'slug': slug,
          },
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              spreadRadius: 2,
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: Container(
                height: screenHeight * 0.12,
                width: double.infinity,
                color: Colors.grey[200],
                child: imageUrl.isNotEmpty
                    ? Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: const Color(0xFF1E3A8A).withValues(alpha: 0.1),
                            child: const Icon(
                              Icons.play_circle_outline,
                              size: 48,
                              color: Color(0xFF1E3A8A),
                            ),
                          );
                        },
                      )
                    : Container(
                        color: const Color(0xFF1E3A8A).withValues(alpha: 0.1),
                        child: const Icon(
                          Icons.play_circle_outline,
                          size: 48,
                          color: Color(0xFF1E3A8A),
                        ),
                      ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: screenWidth * 0.04,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'INSAM Tech',
                      style: TextStyle(
                        fontSize: screenWidth * 0.035,
                        color: Colors.grey[600],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    // Statut de la commande (optimisé pour l'espace)
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: etatCommande == 0
                                  ? Colors.orange.withValues(alpha: 0.2)
                                  : Colors.green.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              etatCommande == 0 ? 'En attente' : 'Actif',
                              style: TextStyle(
                                fontSize: screenWidth * 0.028,
                                color: etatCommande == 0 ? Colors.orange : Colors.green,
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
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
    );
  }

  Widget _buildLibrarySection(double screenWidth, double screenHeight) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Notre bibliothèque',
                style: TextStyle(
                  fontSize: screenWidth * 0.05,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/digital-library');
                },
                child: Text(
                  'Voir tout',
                  style: TextStyle(
                    fontSize: screenWidth * 0.035,
                    color: const Color(0xFF1E3A8A),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),

        SizedBox(height: screenHeight * 0.01),

        // Library Content
        Consumer<LibraryProvider>(
          builder: (context, libraryProvider, child) {
            if (libraryProvider.isLoadingLibrary) {
              return Container(
                height: screenHeight * 0.3,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: const Center(child: CircularProgressIndicator()),
              );
            }

            if (libraryProvider.hasLibraryError) {
              return Container(
                height: screenHeight * 0.3,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 48,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Erreur de chargement',
                        style: TextStyle(
                          fontSize: screenWidth * 0.04,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            final books = libraryProvider.books.take(5).toList();

            if (books.isEmpty) {
              return Container(
                height: screenHeight * 0.3,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.library_books_outlined,
                        size: 48,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Aucun livre disponible',
                        style: TextStyle(
                          fontSize: screenWidth * 0.04,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            return SizedBox(
              height: screenHeight * 0.3,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: books.length,
                itemBuilder: (context, index) {
                  final book = books[index];
                  return _buildLibraryBookCard(book, screenWidth, screenHeight);
                },
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildLibraryBookCard(Map<String, dynamic> book, double screenWidth, double screenHeight) {
    final title = book['titre'] ?? 'Livre sans titre';
    final author = book['auteur'] ?? 'Auteur inconnu';
    final coverUrl = book['cover_url'] ?? '';
    final pdfUrl = book['pdf_url'] ?? '';

    return Container(
      width: screenWidth * 0.4,
      margin: const EdgeInsets.only(right: 16),
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
          }
        },
        child: Container(
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Book Cover
              Expanded(
                flex: 3,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                    color: Colors.grey[200],
                  ),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                    child: coverUrl.isNotEmpty
                        ? Image.network(
                            coverUrl,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Center(
                                child: Icon(
                                  Icons.book,
                                  size: 40,
                                  color: Colors.grey[400],
                                ),
                              );
                            },
                          )
                        : Center(
                            child: Icon(
                              Icons.book,
                              size: 40,
                              color: Colors.grey[400],
                            ),
                          ),
                  ),
                ),
              ),

              // Book Info
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: screenWidth * 0.032,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        author,
                        style: TextStyle(
                          fontSize: screenWidth * 0.028,
                          color: Colors.grey[600],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const Spacer(),
                      if (pdfUrl.isNotEmpty)
                        Row(
                          children: [
                            Icon(
                              Icons.picture_as_pdf,
                              size: 16,
                              color: Colors.red[400],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'PDF',
                              style: TextStyle(
                                fontSize: screenWidth * 0.025,
                                color: Colors.red[400],
                                fontWeight: FontWeight.w500,
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

  Widget _buildBestExamsSection(double screenWidth, double screenHeight) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Nos meilleures épreuves',
                  style: TextStyle(
                    fontSize: screenWidth * 0.045,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
              TextButton(
                onPressed: () {
                  // TODO: Navigate to exams screen when implemented
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Section épreuves bientôt disponible'),
                      backgroundColor: Color(0xFF1E3A8A),
                    ),
                  );
                },
                child: Text(
                  'Voir tout',
                  style: TextStyle(
                    fontSize: screenWidth * 0.035,
                    color: const Color(0xFF1E3A8A),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),

        SizedBox(height: screenHeight * 0.01),

        // Best Exams Content - From Backend
        Consumer<CourseProvider>(
          builder: (context, courseProvider, child) {
            if (courseProvider.isLoading) {
              return SizedBox(
                height: screenHeight * 0.25,
                child: const Center(child: CircularProgressIndicator()),
              );
            }

            if (courseProvider.hasError) {
              return SizedBox(
                height: screenHeight * 0.25,
                child: Center(
                  child: Text(
                    'Erreur de chargement des épreuves',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: screenWidth * 0.035,
                    ),
                  ),
                ),
              );
            }

            // Utiliser les formations du provider (limitées à 5 pour l'affichage)
            final formations = courseProvider.featuredCourses.take(5).toList();

            if (formations.isEmpty) {
              return SizedBox(
                height: screenHeight * 0.25,
                child: Center(
                  child: Text(
                    'Aucune épreuve disponible',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: screenWidth * 0.035,
                    ),
                  ),
                ),
              );
            }

            return SizedBox(
              height: screenHeight * 0.25,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: formations.length,
                itemBuilder: (context, index) {
                  final formation = formations[index];
                  final formationData = {
                    'id': formation.id,
                    'nom': formation.title,
                    'image': formation.imageUrl,
                    'description': formation.description,
                    'prix': formation.price,
                  };
                  return _buildExamCard(formationData, index, screenWidth, screenHeight);
                },
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildExamCard(Map<String, dynamic> formation, int index, double screenWidth, double screenHeight) {
    final title = formation['nom'] ?? 'Formation';
    final imageUrl = formation['image'] ?? formation['img'] ?? '';
    final formationId = formation['id'] ?? index;
    final description = formation['description'] ?? '';

    // Couleurs par défaut basées sur l'index si pas d'image
    final defaultColors = [
      const Color(0xFF4CAF50), // Vert
      const Color(0xFF2196F3), // Bleu
      const Color(0xFFFF9800), // Orange
      const Color(0xFF9C27B0), // Violet
      const Color(0xFF00BCD4), // Cyan
      const Color(0xFFE91E63), // Rose
      const Color(0xFF795548), // Marron
      const Color(0xFF607D8B), // Bleu gris
    ];

    final cardColor = defaultColors[index % defaultColors.length];

    return Container(
      width: screenWidth * 0.6,
      margin: const EdgeInsets.only(right: 16),
      child: InkWell(
        onTap: () {
          Navigator.pushNamed(
            context,
            '/exam-detail',
            arguments: {
              'formationId': formationId,
              'formationTitle': title,
            },
          );
        },
        child: Container(
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image de l'épreuve
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                child: Container(
                  height: screenHeight * 0.1,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        cardColor.withValues(alpha: 0.8),
                        cardColor.withValues(alpha: 0.6),
                      ],
                    ),
                  ),
                  child: Stack(
                    children: [
                      // Image de fond
                      imageUrl.isNotEmpty ? Image.network(
                        imageUrl,
                        width: double.infinity,
                        height: double.infinity,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            color: cardColor.withValues(alpha: 0.1),
                            child: Center(
                              child: CircularProgressIndicator(
                                value: loadingProgress.expectedTotalBytes != null
                                    ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                    : null,
                                strokeWidth: 2,
                                color: cardColor,
                              ),
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: cardColor.withValues(alpha: 0.3),
                            child: Icon(
                              Icons.school,
                              size: 40,
                              color: Colors.white.withValues(alpha: 0.8),
                            ),
                          );
                        },
                      ) : Container(
                        color: cardColor.withValues(alpha: 0.3),
                        child: Icon(
                          Icons.school,
                          size: 40,
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                      ),
                      // Overlay gradient
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.4),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                // Exam Icon and Type
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E3A8A).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.assignment,
                        color: Color(0xFF1E3A8A),
                        size: 24,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.orange[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Épreuve',
                        style: TextStyle(
                          fontSize: screenWidth * 0.025,
                          color: Colors.orange[800],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Exam Title
                Text(
                  title,
                  style: TextStyle(
                    fontSize: screenWidth * 0.04,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),

                const SizedBox(height: 8),

                // Exam Year and Stats
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 16,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '2024',
                      style: TextStyle(
                        fontSize: screenWidth * 0.032,
                        color: Colors.grey[600],
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      Icons.star,
                      size: 16,
                      color: Colors.amber[600],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '4.5',
                      style: TextStyle(
                        fontSize: screenWidth * 0.032,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),

                const Spacer(),

                // Download Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      // TODO: Implement download functionality
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Téléchargement bientôt disponible'),
                          backgroundColor: Color(0xFF1E3A8A),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E3A8A),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    icon: const Icon(Icons.download, size: 16),
                    label: Text(
                      'Télécharger',
                      style: TextStyle(fontSize: screenWidth * 0.028),
                    ),
                  ),
                ),
              ],
            ),
          ),
            ],
          ),
        ),
      ),
    );
  }

}