import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/exam_provider.dart';
import '../models/exam.dart';
import '../utils/translation_helper.dart';

class ExamTakingScreen extends StatefulWidget {
  final int formationId;
  final String formationTitle;

  const ExamTakingScreen({
    super.key,
    required this.formationId,
    required this.formationTitle,
  });

  @override
  State<ExamTakingScreen> createState() => _ExamTakingScreenState();
}

class _ExamTakingScreenState extends State<ExamTakingScreen> {
  final PageController _pageController = PageController();
  int _currentQuestionIndex = 0;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadExamIfNeeded();
  }

  Future<void> _loadExamIfNeeded() async {
    final examProvider = context.read<ExamProvider>();
    final authProvider = context.read<AuthProvider>();

    if (examProvider.currentExam == null && authProvider.isAuthenticated) {
      await examProvider.loadExamForFormation(
        widget.formationId,
        authProvider.user!.id!,
      );
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return WillPopScope(
      onWillPop: () async {
        final shouldExit = await _showExitConfirmation();
        return shouldExit ?? false;
      },
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: _buildAppBar(screenWidth),
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
              return _buildErrorWidget(examProvider.examError!);
            }

            if (!examProvider.isAttemptInProgress || examProvider.currentExam == null) {
              return _buildNoAttemptWidget();
            }

            final questions = examProvider.currentExam!.questions;
            if (questions.isEmpty) {
              return _buildNoQuestionsWidget();
            }

            return Column(
              children: [
                // Timer et progression
                _buildTimerAndProgress(examProvider, screenWidth),

                // Questions
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    onPageChanged: (index) {
                      setState(() {
                        _currentQuestionIndex = index;
                      });
                    },
                    itemCount: questions.length,
                    itemBuilder: (context, index) {
                      return _buildQuestionCard(
                        questions[index],
                        index + 1,
                        questions.length,
                        examProvider,
                        screenWidth,
                        screenHeight,
                      );
                    },
                  ),
                ),

                // Navigation
                _buildNavigationBar(examProvider, screenWidth),
              ],
            );
          },
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(double screenWidth) {
    return AppBar(
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
      leading: IconButton(
        icon: const Icon(Icons.close),
        onPressed: () async {
          final shouldExit = await _showExitConfirmation();
          if (shouldExit == true && mounted) {
            Navigator.pop(context);
          }
        },
      ),
    );
  }

  Widget _buildTimerAndProgress(ExamProvider examProvider, double screenWidth) {
    return Container(
      padding: EdgeInsets.all(screenWidth * 0.04),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 5,
            spreadRadius: 1,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Timer
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
            decoration: BoxDecoration(
              color: examProvider.remainingTime < 300 // < 5 minutes
                  ? Colors.red[50]
                  : Colors.orange[50],
              borderRadius: BorderRadius.circular(25),
              border: Border.all(
                color: examProvider.remainingTime < 300
                    ? Colors.red[300]!
                    : Colors.orange[300]!,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.access_time,
                  color: examProvider.remainingTime < 300
                      ? Colors.red[600]
                      : Colors.orange[600],
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Temps restant: ${examProvider.formattedRemainingTime}',
                  style: TextStyle(
                    fontSize: screenWidth * 0.04,
                    fontWeight: FontWeight.w600,
                    color: examProvider.remainingTime < 300
                        ? Colors.red[800]
                        : Colors.orange[800],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Progression
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Question ${_currentQuestionIndex + 1} sur ${examProvider.totalQuestionsCount}',
                style: TextStyle(
                  fontSize: screenWidth * 0.035,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[700],
                ),
              ),
              Text(
                '${examProvider.answeredQuestionsCount} répondues',
                style: TextStyle(
                  fontSize: screenWidth * 0.035,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[700],
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Barre de progression
          LinearProgressIndicator(
            value: (_currentQuestionIndex + 1) / examProvider.totalQuestionsCount,
            backgroundColor: Colors.grey[300],
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF1E3A8A)),
            minHeight: 6,
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionCard(
    Question question,
    int questionNumber,
    int totalQuestions,
    ExamProvider examProvider,
    double screenWidth,
    double screenHeight,
  ) {
    final questionText = TranslationHelper.getTranslatedText(
      question.question,
      defaultText: 'Question sans texte',
    );

    return SingleChildScrollView(
      padding: EdgeInsets.all(screenWidth * 0.04),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: EdgeInsets.all(screenWidth * 0.04),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // En-tête de la question
              _buildQuestionHeader(question, questionNumber, screenWidth),

              const SizedBox(height: 20),

              // Texte de la question
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Text(
                  questionText,
                  style: TextStyle(
                    fontSize: screenWidth * 0.045,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                    height: 1.4,
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Réponses selon le type de question
              if (question.type == 'qcm')
                _buildMultipleChoiceAnswers(question, examProvider, screenWidth)
              else if (question.type == 'vrai_faux')
                _buildTrueFalseAnswers(question, examProvider, screenWidth)
              else if (question.type == 'texte')
                _buildTextAnswer(question, examProvider, screenWidth),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuestionHeader(Question question, int questionNumber, double screenWidth) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF1E3A8A).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            _getQuestionIcon(question.type),
            color: const Color(0xFF1E3A8A),
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Question $questionNumber',
                style: TextStyle(
                  fontSize: screenWidth * 0.04,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1E3A8A),
                ),
              ),
              Text(
                '${question.points} point${question.points > 1 ? 's' : ''} • ${_getQuestionTypeLabel(question.type)}',
                style: TextStyle(
                  fontSize: screenWidth * 0.032,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
        if (context.read<ExamProvider>().userAnswers.containsKey(question.id))
          Container(
            padding: const EdgeInsets.all(6),
            decoration: const BoxDecoration(
              color: Colors.green,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check,
              color: Colors.white,
              size: 16,
            ),
          ),
      ],
    );
  }

  Widget _buildMultipleChoiceAnswers(Question question, ExamProvider examProvider, double screenWidth) {
    final selectedAnswerId = examProvider.userAnswers[question.id];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Choisissez la bonne réponse:',
          style: TextStyle(
            fontSize: screenWidth * 0.038,
            fontWeight: FontWeight.w500,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 12),
        ...question.reponses.asMap().entries.map((entry) {
          final index = entry.key;
          final response = entry.value;
          final isSelected = selectedAnswerId == response.id;
          final reponseText = TranslationHelper.getTranslatedText(
            response.reponse,
            defaultText: 'Réponse ${index + 1}',
          );

          return GestureDetector(
            onTap: () {
              examProvider.saveUserAnswer(question.id, response.id);
            },
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF1E3A8A).withValues(alpha: 0.1) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? const Color(0xFF1E3A8A) : Colors.grey[300]!,
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isSelected ? const Color(0xFF1E3A8A) : Colors.transparent,
                      border: Border.all(
                        color: isSelected ? const Color(0xFF1E3A8A) : Colors.grey[400]!,
                        width: 2,
                      ),
                    ),
                    child: isSelected
                        ? const Icon(
                            Icons.check,
                            color: Colors.white,
                            size: 16,
                          )
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '${String.fromCharCode(65 + index)}. $reponseText',
                      style: TextStyle(
                        fontSize: screenWidth * 0.038,
                        color: isSelected ? const Color(0xFF1E3A8A) : Colors.black87,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildTrueFalseAnswers(Question question, ExamProvider examProvider, double screenWidth) {
    final selectedAnswerId = examProvider.userAnswers[question.id];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Choisissez Vrai ou Faux:',
          style: TextStyle(
            fontSize: screenWidth * 0.038,
            fontWeight: FontWeight.w500,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildTrueFalseOption(
                'VRAI',
                true,
                question.reponses.isNotEmpty ? question.reponses[0].id : 1,
                selectedAnswerId,
                examProvider,
                question.id,
                screenWidth,
                Colors.green,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildTrueFalseOption(
                'FAUX',
                false,
                question.reponses.length > 1 ? question.reponses[1].id : 2,
                selectedAnswerId,
                examProvider,
                question.id,
                screenWidth,
                Colors.red,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTrueFalseOption(
    String label,
    bool value,
    int responseId,
    int? selectedAnswerId,
    ExamProvider examProvider,
    int questionId,
    double screenWidth,
    Color color,
  ) {
    final isSelected = selectedAnswerId == responseId;

    return GestureDetector(
      onTap: () {
        examProvider.saveUserAnswer(questionId, responseId);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.1) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? color : Colors.transparent,
                border: Border.all(
                  color: isSelected ? color : Colors.grey[400]!,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 12,
                    )
                  : null,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: screenWidth * 0.04,
                fontWeight: FontWeight.w600,
                color: isSelected ? color : Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextAnswer(Question question, ExamProvider examProvider, double screenWidth) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Votre réponse:',
          style: TextStyle(
            fontSize: screenWidth * 0.038,
            fontWeight: FontWeight.w500,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          maxLines: 5,
          decoration: InputDecoration(
            hintText: 'Tapez votre réponse ici...',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF1E3A8A), width: 2),
            ),
            contentPadding: const EdgeInsets.all(16),
          ),
          onChanged: (value) {
            // TODO: Sauvegarder la réponse texte
            // examProvider.saveTextAnswer(question.id, value);
          },
        ),
      ],
    );
  }

  Widget _buildNavigationBar(ExamProvider examProvider, double screenWidth) {
    final questions = examProvider.currentExam?.questions ?? [];
    final isLastQuestion = _currentQuestionIndex == questions.length - 1;
    final isFirstQuestion = _currentQuestionIndex == 0;

    return Container(
      padding: EdgeInsets.all(screenWidth * 0.04),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 5,
            spreadRadius: 1,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Bouton précédent
          if (!isFirstQuestion)
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  _pageController.previousPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                },
                icon: const Icon(Icons.arrow_back),
                label: const Text('Précédent'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF1E3A8A),
                  side: const BorderSide(color: Color(0xFF1E3A8A)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),

          if (!isFirstQuestion && !isLastQuestion) const SizedBox(width: 16),

          // Bouton suivant ou terminer
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _isSubmitting ? null : () {
                if (isLastQuestion) {
                  _showSubmitConfirmation(examProvider);
                } else {
                  _pageController.nextPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                }
              },
              icon: _isSubmitting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Icon(isLastQuestion ? Icons.check : Icons.arrow_forward),
              label: Text(_isSubmitting
                  ? 'Soumission...'
                  : isLastQuestion
                      ? 'Terminer'
                      : 'Suivant'),
              style: ElevatedButton.styleFrom(
                backgroundColor: isLastQuestion ? Colors.green : const Color(0xFF1E3A8A),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
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
              'Erreur',
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
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Retour'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoAttemptWidget() {
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
              'Aucun examen en cours',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Vous devez d\'abord démarrer un examen.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Retour'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoQuestionsWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.quiz_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Aucune question',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Cet examen ne contient aucune question.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Retour'),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getQuestionIcon(String type) {
    switch (type) {
      case 'qcm':
        return Icons.radio_button_checked;
      case 'vrai_faux':
        return Icons.check_box;
      case 'texte':
        return Icons.text_fields;
      default:
        return Icons.help;
    }
  }

  String _getQuestionTypeLabel(String type) {
    switch (type) {
      case 'qcm':
        return 'Choix multiple';
      case 'vrai_faux':
        return 'Vrai/Faux';
      case 'texte':
        return 'Réponse libre';
      default:
        return 'Question';
    }
  }

  Future<bool?> _showExitConfirmation() async {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Quitter l\'examen'),
        content: const Text(
          'Êtes-vous sûr de vouloir quitter l\'examen ? '
          'Vos réponses seront sauvegardées et vous pourrez reprendre plus tard.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Continuer l\'examen'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Quitter'),
          ),
        ],
      ),
    );
  }

  Future<void> _showSubmitConfirmation(ExamProvider examProvider) async {
    final unansweredCount = examProvider.totalQuestionsCount - examProvider.answeredQuestionsCount;

    final shouldSubmit = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Terminer l\'examen'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Voulez-vous vraiment terminer cet examen ?'),
            const SizedBox(height: 12),
            Text('Résumé:'),
            Text('• ${examProvider.answeredQuestionsCount} questions répondues'),
            if (unansweredCount > 0)
              Text(
                '• $unansweredCount questions non répondues',
                style: TextStyle(color: Colors.orange[700]),
              ),
            const SizedBox(height: 12),
            const Text(
              'Une fois soumis, vous ne pourrez plus modifier vos réponses.',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Continuer'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Terminer l\'examen'),
          ),
        ],
      ),
    );

    if (shouldSubmit == true) {
      await _submitExam(examProvider);
    }
  }

  Future<void> _submitExam(ExamProvider examProvider) async {
    setState(() {
      _isSubmitting = true;
    });

    final authProvider = context.read<AuthProvider>();
    if (!authProvider.isAuthenticated) {
      setState(() {
        _isSubmitting = false;
      });
      return;
    }

    final success = await examProvider.submitExam(authProvider.user!.id!);

    setState(() {
      _isSubmitting = false;
    });

    if (success && mounted) {
      // Navigation vers les résultats
      Navigator.pushReplacementNamed(
        context,
        '/exam-result',
        arguments: {
          'tentativeId': examProvider.currentAttempt?.id,
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
}