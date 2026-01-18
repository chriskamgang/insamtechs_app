import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/course_provider.dart';
import '../widgets/course_card.dart';

class CourseByCategoryScreen extends StatefulWidget {
  final String slug;
  final String title;

  const CourseByCategoryScreen({
    super.key,
    required this.slug,
    required this.title,
  });

  @override
  State<CourseByCategoryScreen> createState() => _CourseByCategoryScreenState();
}

class _CourseByCategoryScreenState extends State<CourseByCategoryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCoursesByCategory();
    });
  }

  Future<void> _loadCoursesByCategory() async {
    final courseProvider = context.read<CourseProvider>();
    try {
      await courseProvider.filterByCategory(widget.slug);
    } catch (e) {
      print('Erreur lors du chargement des cours par catégorie: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
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
                    onPressed: _loadCoursesByCategory,
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

          if (courseProvider.courses.isEmpty) {
            return const Center(
              child: Text(
                'Aucun cours disponible dans cette catégorie',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _loadCoursesByCategory,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: courseProvider.courses.length,
              itemBuilder: (context, index) {
                final course = courseProvider.courses[index];
                return CourseCard(
                  course: course,
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