import 'package:flutter/material.dart';
import '../models/course.dart';

class CourseCategoryCard extends StatelessWidget {
  final CourseCategory category;
  final double screenWidth;
  final double screenHeight;

  const CourseCategoryCard({
    super.key,
    required this.category,
    required this.screenWidth,
    required this.screenHeight,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          // Naviguer vers les cours de cette catégorie
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
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image de la catégorie
              Container(
                width: double.infinity,
                height: 80,
                decoration: BoxDecoration(
                  color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  image: category.imageUrl != null
                      ? DecorationImage(
                          image: NetworkImage(category.imageUrl!),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: category.imageUrl == null
                    ? const Icon(
                        Icons.category,
                        size: 40,
                        color: Color(0xFF3B82F6),
                      )
                    : null,
              ),
              const SizedBox(height: 12),
              
              // Nom de la catégorie
              Text(
                category.name,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              
              // Informations supplémentaires
              Text(
                'Cours',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}