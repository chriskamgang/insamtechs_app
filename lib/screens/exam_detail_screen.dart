import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/exam_provider.dart';
import '../utils/translation_helper.dart';

class ExamDetailScreen extends StatefulWidget {
  final int formationId;
  final String formationTitle;

  const ExamDetailScreen({
    super.key,
    required this.formationId,
    required this.formationTitle,
  });

  @override
  State<ExamDetailScreen> createState() => _ExamDetailScreenState();
}

class _ExamDetailScreenState extends State<ExamDetailScreen> {
  @override
  void initState() {
    super.initState();
    _loadExam();
  }

  Future<void> _loadExam() async {
    final authProvider = context.read<AuthProvider>();
    if (authProvider.isAuthenticated && authProvider.user?.id != null) {
      await context.read<ExamProvider>().loadExamForFormation(
        widget.formationId,
        authProvider.user!.id!,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'Examen - ${widget.formationTitle}',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF1E3A8A),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Consumer<ExamProvider>(
        builder: (context, examProvider, child) {
          if (examProvider.isLoadingExam) {
            return const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF1E3A8A),
              ),
            );
          }

          if (examProvider.hasExamError) {
            return _buildErrorWidget(examProvider.examError!, _loadExam);
          }

          if (examProvider.currentExam == null) {
            return _buildNoExamWidget();
          }

          return SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.all(screenWidth * 0.04),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Carte principale de l'examen
                  _buildExamInfoCard(examProvider, screenWidth, screenHeight),

                  SizedBox(height: screenHeight * 0.02),

                  // Tentative en cours ou historique
                  if (examProvider.isAttemptInProgress)
                    _buildCurrentAttemptCard(examProvider, screenWidth, screenHeight)
                  else
                    _buildActionCard(examProvider, screenWidth, screenHeight),

                  SizedBox(height: screenHeight * 0.02),

                  // Historique des tentatives
                  _buildHistorySection(examProvider, screenWidth, screenHeight),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildExamInfoCard(ExamProvider examProvider, double screenWidth, double screenHeight) {
    final exam = examProvider.currentExam!;
    final titre = TranslationHelper.getTranslatedText(exam.titre, defaultText: 'Examen');
    final description = TranslationHelper.getTranslatedText(exam.description, defaultText: '');

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(screenWidth * 0.04),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 10,
            spreadRadius: 2,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête avec icône
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E3A8A).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.assignment,
                  color: Color(0xFF1E3A8A),
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titre,
                      style: TextStyle(
                        fontSize: screenWidth * 0.05,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.formationTitle,
                      style: TextStyle(
                        fontSize: screenWidth * 0.035,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          if (description.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              description,
              style: TextStyle(
                fontSize: screenWidth * 0.035,
                color: Colors.grey[700],
                height: 1.4,
              ),
            ),
          ],

          const SizedBox(height: 20),

          // Informations détaillées
          Row(
            children: [
              Expanded(
                child: _buildInfoItem(
                  Icons.timer,
                  'Durée',
                  '${exam.dureeMinutes} min',
                  screenWidth,
                ),
              ),
              Expanded(
                child: _buildInfoItem(
                  Icons.quiz,
                  'Questions',
                  '${exam.questions.length}',
                  screenWidth,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: _buildInfoItem(
                  Icons.grade,
                  'Note de passage',
                  '${exam.notePassage.toStringAsFixed(1)}/20',
                  screenWidth,
                ),
              ),
              Expanded(
                child: _buildInfoItem(
                  Icons.assignment_turned_in,
                  'Points total',
                  '${exam.questions.fold(0, (sum, q) => sum + q.points)}',
                  screenWidth,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String label, String value, double screenWidth) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 18,
            color: const Color(0xFF1E3A8A),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: screenWidth * 0.025,
                    color: Colors.grey[600],
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: screenWidth * 0.032,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentAttemptCard(ExamProvider examProvider, double screenWidth, double screenHeight) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(screenWidth * 0.04),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.hourglass_bottom,
                color: Colors.orange[600],
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Examen en cours',
                  style: TextStyle(
                    fontSize: screenWidth * 0.045,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange[800],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Timer
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange[200]!),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.access_time,
                  color: Colors.orange[600],
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Temps restant: ${examProvider.formattedRemainingTime}',
                  style: TextStyle(
                    fontSize: screenWidth * 0.04,
                    fontWeight: FontWeight.w600,
                    color: Colors.orange[800],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Progression
          Text(
            'Progression: ${examProvider.answeredQuestionsCount}/${examProvider.totalQuestionsCount} questions',
            style: TextStyle(
              fontSize: screenWidth * 0.035,
              color: Colors.grey[700],
            ),
          ),

          const SizedBox(height: 8),

          LinearProgressIndicator(
            value: examProvider.progressPercentage / 100,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(Colors.orange[600]!),
          ),

          const SizedBox(height: 16),

          // Bouton continuer
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.pushNamed(
                  context,
                  '/exam-taking',
                  arguments: {
                    'formationId': widget.formationId,
                    'formationTitle': widget.formationTitle,
                  },
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange[600],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.play_arrow),
              label: Text(
                'Continuer l\'examen',
                style: TextStyle(
                  fontSize: screenWidth * 0.04,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard(ExamProvider examProvider, double screenWidth, double screenHeight) {
    final authProvider = context.read<AuthProvider>();

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(screenWidth * 0.04),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 10,
            spreadRadius: 2,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Commencer l\'examen',
            style: TextStyle(
              fontSize: screenWidth * 0.045,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),

          const SizedBox(height: 12),

          Text(
            'Vous êtes sur le point de commencer cet examen. Assurez-vous d\'avoir suffisamment de temps pour le terminer.',
            style: TextStyle(
              fontSize: screenWidth * 0.035,
              color: Colors.grey[600],
              height: 1.4,
            ),
          ),

          const SizedBox(height: 20),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () async {
                if (authProvider.isAuthenticated && authProvider.user?.id != null) {
                  final success = await examProvider.startExam(authProvider.user!.id!);

                  if (success && mounted) {
                    Navigator.pushNamed(
                      context,
                      '/exam-taking',
                      arguments: {
                        'formationId': widget.formationId,
                        'formationTitle': widget.formationTitle,
                      },
                    );
                  } else if (mounted && examProvider.hasExamError) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(examProvider.examError!),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E3A8A),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.play_arrow),
              label: Text(
                'Commencer l\'examen',
                style: TextStyle(
                  fontSize: screenWidth * 0.04,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistorySection(ExamProvider examProvider, double screenWidth, double screenHeight) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(screenWidth * 0.04),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 10,
            spreadRadius: 2,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Historique des tentatives',
                style: TextStyle(
                  fontSize: screenWidth * 0.045,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              TextButton(
                onPressed: () {
                  final authProvider = context.read<AuthProvider>();
                  if (authProvider.isAuthenticated && authProvider.user?.id != null) {
                    examProvider.loadExamHistory(
                      examProvider.currentExam!.id,
                      authProvider.user!.id!,
                    );
                  }
                },
                child: Text(
                  'Actualiser',
                  style: TextStyle(
                    fontSize: screenWidth * 0.032,
                    color: const Color(0xFF1E3A8A),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          if (examProvider.isLoadingHistory)
            const Center(child: CircularProgressIndicator())
          else if (examProvider.examHistory.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Text(
                  'Aucune tentative précédente',
                  style: TextStyle(
                    fontSize: screenWidth * 0.035,
                    color: Colors.grey[600],
                  ),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: examProvider.examHistory.length,
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final attempt = examProvider.examHistory[index];
                return _buildHistoryItem(attempt, screenWidth);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildHistoryItem(dynamic attempt, double screenWidth) {
    // TODO: Implémenter l'affichage des tentatives
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        'Tentative en cours de développement',
        style: TextStyle(
          fontSize: screenWidth * 0.032,
          color: Colors.grey[600],
        ),
      ),
    );
  }

  Widget _buildErrorWidget(String errorMessage, VoidCallback onRetry) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
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
            Text(
              errorMessage,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
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
      ),
    );
  }

  Widget _buildNoExamWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.assignment_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Aucun examen disponible',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Il n\'y a pas d\'examen configuré pour cette formation.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }
}