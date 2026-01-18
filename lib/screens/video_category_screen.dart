import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/video_provider.dart';
import '../data/mock_data.dart';
import '../models/course.dart';

class VideoCategoryScreen extends StatefulWidget {
  final String slug;
  final String title;

  const VideoCategoryScreen({
    super.key,
    required this.slug,
    required this.title,
  });

  @override
  State<VideoCategoryScreen> createState() => _VideoCategoryScreenState();
}

class _VideoCategoryScreenState extends State<VideoCategoryScreen> {
  @override
  void initState() {
    super.initState();
    _loadCategoryVideos();
  }

  Future<void> _loadCategoryVideos() async {
    final videoProvider = context.read<VideoProvider>();
    await videoProvider.loadCategoryBySlug(widget.slug);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: const Color(0xFF1E3A8A),
        foregroundColor: Colors.white,
      ),
      body: Consumer<VideoProvider>(
        builder: (context, videoProvider, child) {
          if (videoProvider.isLoadingCategories) {
            return const Center(child: CircularProgressIndicator());
          }

          // Trouver la catégorie dans les données de test
          final categories = videoProvider.videoCategories;
          CourseCategory? category;

          try {
            category = categories.firstWhere(
              (cat) => cat.slug == widget.slug,
            );
          } catch (e) {
            category = null;
          }

          if (category == null) {
            return const Center(
              child: Text('Catégorie introuvable'),
            );
          }

          // Charger les cours et filtrer par categorieId
          final allCourses = MockData.getMockCourses();
          final formations = allCourses
              .where((course) => course.categorieId == category!.id)
              .toList();

          if (formations.isEmpty) {
            return const Center(
              child: Text('Aucune vidéo dans cette catégorie'),
            );
          }

          return RefreshIndicator(
            onRefresh: _loadCategoryVideos,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: formations.length,
              itemBuilder: (context, index) {
                final video = formations[index];
                return _buildVideoCard(video);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildVideoCard(Course course) {
    final title = course.title;
    final instructor = course.instructor;
    final duration = course.duree;
    final description = course.courseDescription;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          Navigator.pushNamed(
            context,
            '/enhanced-video-player',
            arguments: {
              'video': course,
              'title': title,
            },
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Thumbnail simulé
                  Container(
                    width: 100,
                    height: 70,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E3A8A).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Stack(
                      children: [
                        const Center(
                          child: Icon(
                            Icons.play_circle_outline,
                            size: 40,
                            color: Color(0xFF1E3A8A),
                          ),
                        ),
                        Positioned(
                          bottom: 4,
                          right: 4,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.7),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              duration,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Informations de la vidéo
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
                          instructor,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          description,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Actions
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pushNamed(
                          context,
                          '/enhanced-video-player',
                          arguments: {
                            'video': course,
                            'title': title,
                          },
                        );
                      },
                      icon: const Icon(Icons.play_arrow, size: 20),
                      label: const Text('Lire'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E3A8A),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton.icon(
                    onPressed: () {
                      // Ajouter aux favoris ou autre action
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Ajouté aux favoris: $title'),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    },
                    icon: const Icon(Icons.favorite_border, size: 20),
                    label: const Text('Favoris'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
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
}