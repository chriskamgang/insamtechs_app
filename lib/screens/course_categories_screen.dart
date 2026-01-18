import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/course_provider.dart';
import '../widgets/course_category_card.dart';

class CourseCategoriesScreen extends StatefulWidget {
  const CourseCategoriesScreen({super.key});

  @override
  State<CourseCategoriesScreen> createState() => _CourseCategoriesScreenState();
}

class _CourseCategoriesScreenState extends State<CourseCategoriesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Charger les catégories via le service directement
      _loadCategories();
    });
  }

  Future<void> _loadCategories() async {
    final courseProvider = context.read<CourseProvider>();
    await courseProvider.loadCategories();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Catégories de cours'),
        backgroundColor: const Color(0xFF1E3A8A),
        foregroundColor: Colors.white,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: const Color(0xFF1E3A8A),
          statusBarIconBrightness: Brightness.light,
        ),
      ),
      body: Consumer<CourseProvider>(
        builder: (context, courseProvider, child) {
          if (courseProvider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (courseProvider.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.red,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Erreur: ${courseProvider.errorMessage}',
                    style: const TextStyle(fontSize: 16, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => _loadCategories(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E3A8A),
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Réessayer'),
                  ),
                ],
              ),
            );
          }

          if (courseProvider.categories.isEmpty) {
            return const Center(
              child: Text(
                'Aucune catégorie disponible',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => _loadCategories(),
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.8, // Ajuster l'aspect des cartes
              ),
              itemCount: courseProvider.categories.length,
              itemBuilder: (context, index) {
                final category = courseProvider.categories[index];
                return CourseCategoryCard(
                  category: category,
                  screenWidth: screenWidth,
                  screenHeight: screenHeight,
                );
              },
            ),
          );
        },
      ),
    );
  }
}