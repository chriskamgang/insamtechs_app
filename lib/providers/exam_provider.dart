import 'dart:async';
import 'package:flutter/foundation.dart';
import '../services/exam_service.dart';
import '../models/exam.dart';
import '../models/exam_attempt.dart';

class ExamProvider with ChangeNotifier {
  final ExamService _examService = ExamService();

  // État pour l'examen actuel
  Exam? _currentExam;
  bool _isLoadingExam = false;
  String? _examError;

  // État pour la tentative en cours
  ExamAttempt? _currentAttempt;
  bool _isAttemptInProgress = false;
  Timer? _examTimer;
  int _remainingTime = 0;

  // État pour les réponses de l'utilisateur
  Map<int, int> _userAnswers = {}; // questionId -> responseId

  // État pour les résultats
  ExamResult? _examResult;
  bool _isLoadingResult = false;
  String? _resultError;

  // État pour l'historique
  List<ExamAttempt> _examHistory = [];
  bool _isLoadingHistory = false;
  String? _historyError;

  // Getters pour l'examen
  Exam? get currentExam => _currentExam;
  bool get isLoadingExam => _isLoadingExam;
  String? get examError => _examError;
  bool get hasExamError => _examError != null;

  // Getters pour la tentative
  ExamAttempt? get currentAttempt => _currentAttempt;
  bool get isAttemptInProgress => _isAttemptInProgress;
  int get remainingTime => _remainingTime;
  Map<int, int> get userAnswers => Map.unmodifiable(_userAnswers);

  // Getters pour les résultats
  ExamResult? get examResult => _examResult;
  bool get isLoadingResult => _isLoadingResult;
  String? get resultError => _resultError;
  bool get hasResultError => _resultError != null;

  // Getters pour l'historique
  List<ExamAttempt> get examHistory => List.unmodifiable(_examHistory);
  bool get isLoadingHistory => _isLoadingHistory;
  String? get historyError => _historyError;
  bool get hasHistoryError => _historyError != null;

  // Formatage du temps
  String get formattedRemainingTime => _examService.formatTime(_remainingTime);

  /// Charge un examen pour une formation
  Future<void> loadExamForFormation(int formationId, int userId) async {
    _isLoadingExam = true;
    _examError = null;
    notifyListeners();

    try {
      final result = await _examService.getExamForFormation(formationId, userId);

      if (result['success']) {
        final data = result['data'];
        if (data['examen'] != null) {
          _currentExam = _examService.parseExam(data['examen']);

          // Vérifier s'il y a une tentative en cours
          if (data['tentative_en_cours'] != null) {
            _currentAttempt = _examService.parseExamAttempt(data['tentative_en_cours']);
            _isAttemptInProgress = true;
            _startTimer();
          }
        }
      } else {
        _examError = result['message'];
      }
    } catch (e) {
      _examError = 'Erreur lors du chargement de l\'examen: ${e.toString()}';
    }

    _isLoadingExam = false;
    notifyListeners();
  }

  /// Démarre un examen
  Future<bool> startExam(int userId) async {
    if (_currentExam == null) return false;

    try {
      final result = await _examService.startExam(_currentExam!.id, userId);

      if (result['success']) {
        final data = result['data'];
        _currentAttempt = _examService.parseExamAttempt(data['tentative']);
        _isAttemptInProgress = true;
        _userAnswers.clear();
        _remainingTime = data['temps_restant'] ?? _currentExam!.dureeMinutes * 60;
        _startTimer();
        notifyListeners();
        return true;
      } else {
        _examError = result['message'];
        notifyListeners();
        return false;
      }
    } catch (e) {
      _examError = 'Erreur lors du démarrage de l\'examen: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  /// Sauvegarde une réponse d'utilisateur (local)
  void saveUserAnswer(int questionId, int responseId) {
    _userAnswers[questionId] = responseId;
    notifyListeners();
  }

  /// Supprime une réponse d'utilisateur
  void removeUserAnswer(int questionId) {
    _userAnswers.remove(questionId);
    notifyListeners();
  }

  /// Soumet l'examen
  Future<bool> submitExam(int userId) async {
    if (_currentAttempt == null || _userAnswers.isEmpty) return false;

    try {
      final userAnswersList = _userAnswers.entries
          .map((entry) => UserAnswer(questionId: entry.key, reponse: entry.value))
          .toList();

      final result = await _examService.submitExamAnswers(
        _currentAttempt!.id,
        userId,
        userAnswersList,
      );

      if (result['success']) {
        _stopTimer();
        _isAttemptInProgress = false;

        // Recharger les données de tentative avec le score
        final data = result['data'];
        _currentAttempt = _examService.parseExamAttempt(data['tentative']);

        notifyListeners();
        return true;
      } else {
        _examError = result['message'];
        notifyListeners();
        return false;
      }
    } catch (e) {
      _examError = 'Erreur lors de la soumission: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  /// Charge les résultats détaillés d'un examen
  Future<void> loadExamResult(int tentativeId, int userId) async {
    _isLoadingResult = true;
    _resultError = null;
    notifyListeners();

    try {
      final result = await _examService.getExamResult(tentativeId, userId);

      if (result['success']) {
        _examResult = _examService.parseExamResult(result['data']);
      } else {
        _resultError = result['message'];
      }
    } catch (e) {
      _resultError = 'Erreur lors du chargement des résultats: ${e.toString()}';
    }

    _isLoadingResult = false;
    notifyListeners();
  }

  /// Charge l'historique des tentatives
  Future<void> loadExamHistory(int examenId, int userId) async {
    _isLoadingHistory = true;
    _historyError = null;
    notifyListeners();

    try {
      final result = await _examService.getExamHistory(examenId, userId);

      if (result['success']) {
        final data = result['data'];
        _examHistory = (data['tentatives'] as List)
            .map((attempt) => _examService.parseExamAttempt(attempt))
            .toList();
      } else {
        _historyError = result['message'];
      }
    } catch (e) {
      _historyError = 'Erreur lors du chargement de l\'historique: ${e.toString()}';
    }

    _isLoadingHistory = false;
    notifyListeners();
  }

  /// Démarre le timer pour l'examen
  void _startTimer() {
    if (_currentExam == null || _currentAttempt == null) return;

    _remainingTime = _examService.calculateRemainingTime(
      _currentAttempt!.debutExamen,
      _currentExam!.dureeMinutes,
    );

    _examTimer?.cancel();
    _examTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingTime > 0) {
        _remainingTime--;
        notifyListeners();
      } else {
        // Temps écoulé
        _stopTimer();
        _isAttemptInProgress = false;
        _examError = 'Temps écoulé! L\'examen a été automatiquement soumis.';
        notifyListeners();
      }
    });
  }

  /// Arrête le timer
  void _stopTimer() {
    _examTimer?.cancel();
    _examTimer = null;
  }

  /// Vérifie le statut d'une tentative
  Future<void> checkAttemptStatus(int tentativeId, int userId) async {
    try {
      final result = await _examService.getAttemptStatus(tentativeId, userId);

      if (result['success']) {
        final data = result['data'];
        _remainingTime = data['temps_restant'] ?? 0;

        if (data['est_expire'] == true) {
          _stopTimer();
          _isAttemptInProgress = false;
          _examError = 'L\'examen a expiré.';
        }

        notifyListeners();
      }
    } catch (e) {
      // Silencieux pour ne pas interrompre l'utilisateur
    }
  }

  /// Obtient le nombre de questions répondues
  int get answeredQuestionsCount => _userAnswers.length;

  /// Obtient le nombre total de questions
  int get totalQuestionsCount => _currentExam?.questions.length ?? 0;

  /// Obtient le pourcentage de progression
  double get progressPercentage {
    if (totalQuestionsCount == 0) return 0.0;
    return (answeredQuestionsCount / totalQuestionsCount) * 100;
  }

  /// Vérifie si toutes les questions ont été répondues
  bool get allQuestionsAnswered => answeredQuestionsCount == totalQuestionsCount;

  /// Réinitialise l'état
  void reset() {
    _stopTimer();
    _currentExam = null;
    _currentAttempt = null;
    _isAttemptInProgress = false;
    _userAnswers.clear();
    _examResult = null;
    _examHistory.clear();
    _remainingTime = 0;
    _examError = null;
    _resultError = null;
    _historyError = null;
    notifyListeners();
  }

  /// Clear errors
  void clearErrors() {
    _examError = null;
    _resultError = null;
    _historyError = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _stopTimer();
    super.dispose();
  }
}