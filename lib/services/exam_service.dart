import 'package:dio/dio.dart';
import '../config/environment.dart';
import '../models/exam.dart';
import '../models/exam_attempt.dart';
import '../models/certificate.dart';

class ExamService {
  static final ExamService _instance = ExamService._internal();
  factory ExamService() => _instance;

  final Dio _dio = Dio();
  final String baseUrl = EnvironmentConfig.apiBaseUrl;

  ExamService._internal() {
    _dio.options.baseUrl = baseUrl;
    _dio.options.connectTimeout = const Duration(seconds: 30);
    _dio.options.receiveTimeout = const Duration(seconds: 30);
    _dio.options.headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
  }

  /// Récupère un examen pour une formation donnée
  Future<Map<String, dynamic>> getExamForFormation(int formationId, int userId) async {
    try {
      final response = await _dio.get(
        '/examens/formation/$formationId',
        queryParameters: {'userId': userId},
      );

      return {
        'success': true,
        'data': response.data,
      };
    } on DioException catch (e) {
      return {
        'success': false,
        'message': e.response?.data['message'] ?? 'Erreur lors de la récupération de l\'examen',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Erreur de connexion: ${e.toString()}',
      };
    }
  }

  /// Commence un examen
  Future<Map<String, dynamic>> startExam(int examenId, int userId) async {
    try {
      final response = await _dio.post(
        '/examens/$examenId/commencer',
        data: {
          'user_id': userId,
        },
      );

      return {
        'success': true,
        'data': response.data,
      };
    } on DioException catch (e) {
      return {
        'success': false,
        'message': e.response?.data['message'] ?? 'Erreur lors du démarrage de l\'examen',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Erreur de connexion: ${e.toString()}',
      };
    }
  }

  /// Soumet les réponses à un examen
  Future<Map<String, dynamic>> submitExamAnswers(
    int tentativeId,
    int userId,
    List<UserAnswer> reponses,
  ) async {
    try {
      final response = await _dio.post(
        '/examens/tentatives/$tentativeId/soumettre',
        data: {
          'user_id': userId,
          'reponses': reponses.map((r) => r.toJson()).toList(),
        },
      );

      return {
        'success': true,
        'data': response.data,
      };
    } on DioException catch (e) {
      return {
        'success': false,
        'message': e.response?.data['message'] ?? 'Erreur lors de la soumission des réponses',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Erreur de connexion: ${e.toString()}',
      };
    }
  }

  /// Récupère le résultat détaillé d'un examen
  Future<Map<String, dynamic>> getExamResult(int tentativeId, int userId) async {
    try {
      final response = await _dio.get(
        '/examens/tentatives/$tentativeId/resultat',
        queryParameters: {'userId': userId},
      );

      return {
        'success': true,
        'data': response.data,
      };
    } on DioException catch (e) {
      return {
        'success': false,
        'message': e.response?.data['message'] ?? 'Erreur lors de la récupération du résultat',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Erreur de connexion: ${e.toString()}',
      };
    }
  }

  /// Vérifie le statut d'une tentative d'examen
  Future<Map<String, dynamic>> getAttemptStatus(int tentativeId, int userId) async {
    try {
      final response = await _dio.get('/examens/tentatives/$tentativeId/statut/$userId');

      return {
        'success': true,
        'data': response.data,
      };
    } on DioException catch (e) {
      return {
        'success': false,
        'message': e.response?.data['message'] ?? 'Erreur lors de la vérification du statut',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Erreur de connexion: ${e.toString()}',
      };
    }
  }

  /// Récupère l'historique des tentatives pour un examen
  Future<Map<String, dynamic>> getExamHistory(int examenId, int userId) async {
    try {
      final response = await _dio.get(
        '/examens/$examenId/historique',
        queryParameters: {'userId': userId},
      );

      return {
        'success': true,
        'data': response.data,
      };
    } on DioException catch (e) {
      return {
        'success': false,
        'message': e.response?.data['message'] ?? 'Erreur lors de la récupération de l\'historique',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Erreur de connexion: ${e.toString()}',
      };
    }
  }

  /// Parse les données d'examen depuis la réponse API
  Exam parseExam(Map<String, dynamic> examData) {
    return Exam.fromJson(examData);
  }

  /// Parse les données de tentative depuis la réponse API
  ExamAttempt parseExamAttempt(Map<String, dynamic> attemptData) {
    return ExamAttempt.fromJson(attemptData);
  }

  /// Parse les données de résultat depuis la réponse API
  ExamResult parseExamResult(Map<String, dynamic> resultData) {
    return ExamResult.fromJson(resultData);
  }

  /// Calcule le temps restant en secondes
  int calculateRemainingTime(DateTime startTime, int durationMinutes) {
    final now = DateTime.now();
    final endTime = startTime.add(Duration(minutes: durationMinutes));
    final remaining = endTime.difference(now);
    return remaining.inSeconds > 0 ? remaining.inSeconds : 0;
  }

  /// Formate le temps en format MM:SS ou HH:MM:SS
  String formatTime(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final remainingSeconds = seconds % 60;

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
    } else {
      return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
    }
  }

  /// Vérifie si un examen est expiré
  bool isExamExpired(DateTime startTime, int durationMinutes) {
    final now = DateTime.now();
    final endTime = startTime.add(Duration(minutes: durationMinutes));
    return now.isAfter(endTime);
  }

  /// Récupère le certificat pour une tentative d'examen réussie
  Future<Map<String, dynamic>> getCertificate(int tentativeId, int userId) async {
    try {
      final response = await _dio.get(
        '/certificats/tentative/$tentativeId',
        queryParameters: {'userId': userId},
      );

      return {
        'success': true,
        'data': response.data,
      };
    } on DioException catch (e) {
      return {
        'success': false,
        'message': e.response?.data['message'] ?? 'Erreur lors de la récupération du certificat',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Erreur de connexion: ${e.toString()}',
      };
    }
  }

  /// Récupère tous les certificats d'un utilisateur
  Future<Map<String, dynamic>> getUserCertificates(int userId) async {
    try {
      final response = await _dio.get('/certificats/user/$userId');

      return {
        'success': true,
        'data': response.data,
      };
    } on DioException catch (e) {
      return {
        'success': false,
        'message': e.response?.data['message'] ?? 'Erreur lors de la récupération des certificats',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Erreur de connexion: ${e.toString()}',
      };
    }
  }

  /// Vérifie la validité d'un certificat par son code
  Future<Map<String, dynamic>> verifyCertificate(String certificateCode) async {
    try {
      final response = await _dio.get('/certificats/verify/$certificateCode');

      return {
        'success': true,
        'data': response.data,
      };
    } on DioException catch (e) {
      return {
        'success': false,
        'message': e.response?.data['message'] ?? 'Certificat non trouvé ou invalide',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Erreur de connexion: ${e.toString()}',
      };
    }
  }

  /// Parse les données de certificat depuis la réponse API
  Certificate parseCertificate(Map<String, dynamic> certificateData) {
    return Certificate.fromJson(certificateData);
  }
}