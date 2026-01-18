import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/enrollment_provider.dart';
import '../utils/translation_helper.dart';

class MyCoursesScreen extends StatefulWidget {
  const MyCoursesScreen({super.key});

  @override
  State<MyCoursesScreen> createState() => _MyCoursesScreenState();
}

class _MyCoursesScreenState extends State<MyCoursesScreen> {
  @override
  void initState() {
    super.initState();
    // Use addPostFrameCallback to avoid calling setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadEnrollments();
    });
  }

  Future<void> _loadEnrollments() async {
    final authProvider = context.read<AuthProvider>();
    if (authProvider.isAuthenticated && authProvider.user?.id != null) {
      final enrollmentProvider = context.read<EnrollmentProvider>();
      await enrollmentProvider.refreshUserEnrollments(authProvider.user!.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes Cours'),
        backgroundColor: const Color(0xFF1E3A8A),
        foregroundColor: Colors.white,
      ),
      resizeToAvoidBottomInset: true,
      body: Consumer<EnrollmentProvider>(
        builder: (context, enrollmentProvider, child) {
          if (enrollmentProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (enrollmentProvider.userEnrollments.isEmpty) {
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
                    'Aucune inscription',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Vous n\'avez pas encore de cours',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[500],
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pushNamed(context, '/courses');
                    },
                    icon: const Icon(Icons.search),
                    label: const Text('Explorer les cours'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E3A8A),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _loadEnrollments,
            child: Column(
              children: [
                // Statistiques en haut
                _buildStatsHeader(enrollmentProvider.userEnrollments),
                // Liste des cours
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: enrollmentProvider.userEnrollments.length,
                    itemBuilder: (context, index) {
                      final enrollment = enrollmentProvider.userEnrollments[index];
                      final formation = enrollment['formation'];

                      if (formation == null) {
                        return const SizedBox.shrink();
                      }

                      return _buildCourseCard(enrollment, formation);
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCourseCard(dynamic enrollment, dynamic formation) {
    final title = TranslationHelper.getTranslatedText(formation['intitule'], defaultText: 'Formation');
    final description = TranslationHelper.getDescription(formation['description']);
    final prix = TranslationHelper.getPrice(formation['prix']);

    final slug = formation['slug'] ?? '';
    final imageUrl = formation['image'] ?? '';
    final etatCommande = enrollment['etat_commande'] ?? 0;
    final date = enrollment['date'] ?? '';

    // Calculer la progression
    final chapitres = formation['chapitres'] ?? [];
    final totalVideos = _getTotalVideos(chapitres);
    final completedVideos = 0; // TODO: Implémenter le tracking des vidéos regardées
    final progressPercentage = totalVideos > 0 ? (completedVideos / totalVideos) * 100 : 0.0;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          if (etatCommande == 0) {
            // Si la commande est en attente
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Cette commande est en attente de validation'),
                backgroundColor: Colors.orange,
              ),
            );
          } else {
            // Si la commande est active, aller au cours
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
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image du cours
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: imageUrl.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(
                              Icons.play_circle_outline,
                              size: 40,
                              color: Colors.grey[400],
                            );
                          },
                        ),
                      )
                    : Icon(
                        Icons.play_circle_outline,
                        size: 40,
                        color: Colors.grey[400],
                      ),
              ),
              const SizedBox(width: 12),
              // Détails du cours
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
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
                      'Prix: $prix FCFA',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Informations sur le cours
                    Row(
                      children: [
                        Icon(Icons.video_library, size: 16, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          '$totalVideos vidéos',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Icon(Icons.schedule, size: 16, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          '${chapitres.length} chapitres',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Progression
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Progression',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              '${progressPercentage.toStringAsFixed(0)}%',
                              style: TextStyle(
                                fontSize: 12,
                                color: const Color(0xFF1E3A8A),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        LinearProgressIndicator(
                          value: progressPercentage / 100,
                          backgroundColor: Colors.grey[300],
                          valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF1E3A8A)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Commandé le: $date',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey[500],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Statut
              Flexible(
                child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: etatCommande == 0
                      ? Colors.orange.withOpacity(0.1)
                      : Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: etatCommande == 0 ? Colors.orange : Colors.green,
                    width: 1,
                  ),
                ),
                child: Text(
                  etatCommande == 0 ? 'En attente' : 'Actif',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: etatCommande == 0 ? Colors.orange : Colors.green,
                  ),
                ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  int _getTotalVideos(List<dynamic> chapitres) {
    int totalVideos = 0;
    for (var chapitre in chapitres) {
      final videos = chapitre['videos'] ?? [];
      totalVideos += videos.length as int;
    }
    return totalVideos;
  }

  Widget _buildStatsHeader(List<dynamic> enrollments) {
    final totalCourses = enrollments.length;
    final activeCourses = enrollments.where((e) => e['etat_commande'] == 1).length;
    final pendingCourses = enrollments.where((e) => e['etat_commande'] == 0).length;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E3A8A).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF1E3A8A).withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildStatItem('Total', totalCourses.toString(), Icons.school),
          ),
          Container(
            width: 1,
            height: 40,
            color: Colors.grey[300],
          ),
          Expanded(
            child: _buildStatItem('Actifs', activeCourses.toString(), Icons.play_circle),
          ),
          Container(
            width: 1,
            height: 40,
            color: Colors.grey[300],
          ),
          Expanded(
            child: _buildStatItem('En attente', pendingCourses.toString(), Icons.schedule),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(
          icon,
          color: const Color(0xFF1E3A8A),
          size: 24,
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E3A8A),
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

}