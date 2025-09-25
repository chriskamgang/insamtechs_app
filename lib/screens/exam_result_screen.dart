import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/exam_provider.dart';
import '../models/exam_attempt.dart';
import '../utils/translation_helper.dart';

class ExamResultScreen extends StatefulWidget {
  final int tentativeId;
  final String formationTitle;

  const ExamResultScreen({
    super.key,
    required this.tentativeId,
    required this.formationTitle,
  });

  @override
  State<ExamResultScreen> createState() => _ExamResultScreenState();
}

class _ExamResultScreenState extends State<ExamResultScreen>
    with TickerProviderStateMixin {
  late AnimationController _scoreAnimationController;
  late Animation<double> _scoreAnimation;

  @override
  void initState() {
    super.initState();
    _scoreAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _scoreAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _scoreAnimationController, curve: Curves.easeOut),
    );

    _loadResults();
  }

  @override
  void dispose() {
    _scoreAnimationController.dispose();
    super.dispose();
  }

  Future<void> _loadResults() async {
    final authProvider = context.read<AuthProvider>();
    if (authProvider.isAuthenticated && authProvider.user?.id != null) {
      await context.read<ExamProvider>().loadExamResult(
        widget.tentativeId,
        authProvider.user!.id!,
      );
      _scoreAnimationController.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'Résultats - ${widget.formationTitle}',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF1E3A8A),
        foregroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () {
              Navigator.pushNamedAndRemoveUntil(
                context,
                '/home',
                (route) => false,
              );
            },
          ),
        ],
      ),
      body: Consumer<ExamProvider>(
        builder: (context, examProvider, child) {
          if (examProvider.isLoadingResult) {
            return const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF1E3A8A),
              ),
            );
          }

          if (examProvider.hasResultError) {
            return _buildErrorWidget(examProvider.resultError!);
          }

          if (examProvider.examResult == null) {
            return _buildNoResultWidget();
          }

          final result = examProvider.examResult!;

          return SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.all(screenWidth * 0.04),
              child: Column(
                children: [
                  // Carte de score principal
                  _buildScoreCard(result, screenWidth, screenHeight),

                  SizedBox(height: screenHeight * 0.02),

                  // Statistiques détaillées
                  _buildStatisticsCard(result, screenWidth, screenHeight),

                  SizedBox(height: screenHeight * 0.02),

                  // Correction détaillée
                  _buildCorrectionsCard(result, screenWidth, screenHeight),

                  SizedBox(height: screenHeight * 0.02),

                  // Actions
                  _buildActionButtons(screenWidth),

                  SizedBox(height: screenHeight * 0.02),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildScoreCard(ExamResult result, double screenWidth, double screenHeight) {
    final isSuccess = result.tentative.reussi == true;
    final percentage = result.pourcentage;

    return AnimatedBuilder(
      animation: _scoreAnimation,
      builder: (context, child) {
        return Container(
          width: double.infinity,
          padding: EdgeInsets.all(screenWidth * 0.06),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isSuccess
                  ? [Colors.green[400]!, Colors.green[600]!]
                  : [Colors.red[400]!, Colors.red[600]!],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: (isSuccess ? Colors.green : Colors.red).withValues(alpha: 0.3),
                blurRadius: 15,
                spreadRadius: 2,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            children: [
              // Icône de résultat
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isSuccess ? Icons.check_circle : Icons.cancel,
                  size: 48,
                  color: Colors.white,
                ),
              ),

              const SizedBox(height: 16),

              // Titre
              Text(
                isSuccess ? 'Félicitations !' : 'Échec',
                style: TextStyle(
                  fontSize: screenWidth * 0.06,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                isSuccess
                    ? 'Vous avez réussi l\'examen'
                    : 'Vous n\'avez pas atteint la note de passage',
                style: TextStyle(
                  fontSize: screenWidth * 0.04,
                  color: Colors.white.withValues(alpha: 0.9),
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 24),

              // Score animé
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 120,
                    height: 120,
                    child: CircularProgressIndicator(
                      value: _scoreAnimation.value * (percentage / 100),
                      strokeWidth: 8,
                      backgroundColor: Colors.white.withValues(alpha: 0.3),
                      valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                  Column(
                    children: [
                      Text(
                        '${(percentage * _scoreAnimation.value).round()}%',
                        style: TextStyle(
                          fontSize: screenWidth * 0.08,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        '${result.tentative.score}/${result.tentative.scoreMax}',
                        style: TextStyle(
                          fontSize: screenWidth * 0.035,
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Temps
              Container(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.access_time,
                      color: Colors.white,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Temps: ${result.statistiques.tempsPasseFormate}',
                      style: TextStyle(
                        fontSize: screenWidth * 0.032,
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatisticsCard(ExamResult result, double screenWidth, double screenHeight) {
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
            'Statistiques détaillées',
            style: TextStyle(
              fontSize: screenWidth * 0.045,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),

          const SizedBox(height: 20),

          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  Icons.quiz,
                  'Questions',
                  '${result.statistiques.totalQuestions}',
                  Colors.blue,
                  screenWidth,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  Icons.check_circle,
                  'Correctes',
                  '${result.statistiques.bonnesReponses}',
                  Colors.green,
                  screenWidth,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  Icons.cancel,
                  'Incorrectes',
                  '${result.statistiques.mauvaisesReponses}',
                  Colors.red,
                  screenWidth,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  Icons.percent,
                  'Réussite',
                  '${result.statistiques.pourcentageReussite.toStringAsFixed(1)}%',
                  Colors.orange,
                  screenWidth,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String label, String value, Color color, double screenWidth) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: 28,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: screenWidth * 0.04,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: screenWidth * 0.03,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCorrectionsCard(ExamResult result, double screenWidth, double screenHeight) {
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
                'Correction détaillée',
                style: TextStyle(
                  fontSize: screenWidth * 0.045,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              Icon(
                Icons.assignment_turned_in,
                color: Colors.grey[600],
                size: 24,
              ),
            ],
          ),

          const SizedBox(height: 16),

          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: result.correction.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final correction = result.correction[index];
              return _buildCorrectionItem(correction, index + 1, screenWidth);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCorrectionItem(QuestionCorrection correction, int questionNumber, double screenWidth) {
    final questionText = TranslationHelper.getTranslatedText(
      correction.question.question,
      defaultText: 'Question $questionNumber',
    );

    final bonneReponseText = TranslationHelper.getTranslatedText(
      correction.bonneReponse.reponse,
      defaultText: 'Bonne réponse',
    );

    final reponseUtilisateurText = correction.reponseUtilisateur != null
        ? TranslationHelper.getTranslatedText(
            correction.reponseUtilisateur!.reponse,
            defaultText: 'Votre réponse',
          )
        : 'Non répondu';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: correction.estCorrecte ? Colors.green[50] : Colors.red[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: correction.estCorrecte ? Colors.green[200]! : Colors.red[200]!,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête de la question
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: correction.estCorrecte ? Colors.green : Colors.red,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  correction.estCorrecte ? Icons.check : Icons.close,
                  color: Colors.white,
                  size: 16,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Question $questionNumber (${correction.pointsObtenus}/${correction.question.points} pts)',
                  style: TextStyle(
                    fontSize: screenWidth * 0.035,
                    fontWeight: FontWeight.w600,
                    color: correction.estCorrecte ? Colors.green[800] : Colors.red[800],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Question
          Text(
            questionText,
            style: TextStyle(
              fontSize: screenWidth * 0.035,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),

          const SizedBox(height: 12),

          // Réponses
          if (correction.reponseUtilisateur != null) ...[
            _buildAnswerRow(
              'Votre réponse',
              reponseUtilisateurText,
              correction.estCorrecte ? Colors.green : Colors.red,
              screenWidth,
            ),
            const SizedBox(height: 8),
          ],

          if (!correction.estCorrecte)
            _buildAnswerRow(
              'Bonne réponse',
              bonneReponseText,
              Colors.green,
              screenWidth,
            ),
        ],
      ),
    );
  }

  Widget _buildAnswerRow(String label, String answer, Color color, double screenWidth) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: screenWidth * 0.028,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            answer,
            style: TextStyle(
              fontSize: screenWidth * 0.032,
              color: Colors.black87,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(double screenWidth) {
    final examProvider = context.watch<ExamProvider>();
    final result = examProvider.examResult;
    final isPassed = result != null && result.isPassed;

    return Column(
      children: [
        // Certificate button (only if passed)
        if (isPassed) ...[
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.pushNamed(
                  context,
                  '/certificate',
                  arguments: {
                    'tentativeId': widget.tentativeId,
                    'formationTitle': widget.formationTitle,
                  },
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.workspace_premium),
              label: Text(
                'Voir mon certificat',
                style: TextStyle(
                  fontSize: screenWidth * 0.04,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],

        // Home button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () {
              Navigator.pushNamedAndRemoveUntil(
                context,
                '/home',
                (route) => false,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E3A8A),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const Icon(Icons.home),
            label: Text(
              'Retour à l\'accueil',
              style: TextStyle(
                fontSize: screenWidth * 0.04,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),

        const SizedBox(height: 12),

        // Share button (only if passed)
        if (isPassed) ...[
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                // Share success message
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('J\'ai réussi l\'examen "${widget.formationTitle}" avec ${result.scorePercentage.toStringAsFixed(1)}%!'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.green,
                side: const BorderSide(color: Colors.green),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.share),
              label: Text(
                'Partager ma réussite',
                style: TextStyle(
                  fontSize: screenWidth * 0.04,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ] else ...[
          // Retry button (if failed)
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                Navigator.pop(context); // Go back to exam detail
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF1E3A8A),
                side: const BorderSide(color: Color(0xFF1E3A8A)),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.refresh),
              label: Text(
                'Reprendre l\'examen',
                style: TextStyle(
                  fontSize: screenWidth * 0.04,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildErrorWidget(String errorMessage) {
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
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              errorMessage,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/home',
                  (route) => false,
                );
              },
              icon: const Icon(Icons.home),
              label: const Text('Retour à l\'accueil'),
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

  Widget _buildNoResultWidget() {
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
              'Résultats non disponibles',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Les résultats de cet examen ne sont pas encore disponibles.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/home',
                  (route) => false,
                );
              },
              icon: const Icon(Icons.home),
              label: const Text('Retour à l\'accueil'),
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
}