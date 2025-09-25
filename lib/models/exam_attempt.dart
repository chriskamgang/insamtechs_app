import 'exam.dart';

class ExamAttempt {
  final int id;
  final int examenId;
  final int userId;
  final DateTime debutExamen;
  final DateTime? finExamen;
  final int? score;
  final int scoreMax;
  final bool? reussi;
  final Map<String, dynamic>? reponsesUtilisateur;
  final String statut; // en_cours, termine, expire, abandonne
  final Exam? examen;

  ExamAttempt({
    required this.id,
    required this.examenId,
    required this.userId,
    required this.debutExamen,
    this.finExamen,
    this.score,
    required this.scoreMax,
    this.reussi,
    this.reponsesUtilisateur,
    required this.statut,
    this.examen,
  });

  factory ExamAttempt.fromJson(Map<String, dynamic> json) {
    return ExamAttempt(
      id: json['id'] ?? 0,
      examenId: json['examen_id'] ?? 0,
      userId: json['user_id'] ?? 0,
      debutExamen: DateTime.parse(json['debut_examen']),
      finExamen: json['fin_examen'] != null
          ? DateTime.parse(json['fin_examen'])
          : null,
      score: json['score'],
      scoreMax: json['score_max'] ?? 0,
      reussi: json['reussi'],
      reponsesUtilisateur: json['reponses_utilisateur'],
      statut: json['statut'] ?? 'en_cours',
      examen: json['examen'] != null ? Exam.fromJson(json['examen']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'examen_id': examenId,
      'user_id': userId,
      'debut_examen': debutExamen.toIso8601String(),
      'fin_examen': finExamen?.toIso8601String(),
      'score': score,
      'score_max': scoreMax,
      'reussi': reussi,
      'reponses_utilisateur': reponsesUtilisateur,
      'statut': statut,
      'examen': examen?.toJson(),
    };
  }

  double? get pourcentage {
    if (score == null || scoreMax == 0) return null;
    return (score! / scoreMax) * 100;
  }

  bool get isEnCours => statut == 'en_cours';
  bool get isTermine => statut == 'termine';
  bool get isExpire => statut == 'expire';
  bool get isAbandonne => statut == 'abandonne';
}

class ExamResult {
  final ExamAttempt tentative;
  final List<QuestionCorrection> correction;
  final ExamStatistiques statistiques;
  final double pourcentage;

  ExamResult({
    required this.tentative,
    required this.correction,
    required this.statistiques,
    required this.pourcentage,
  });

  factory ExamResult.fromJson(Map<String, dynamic> json) {
    return ExamResult(
      tentative: ExamAttempt.fromJson(json['tentative']),
      correction: (json['correction'] as List)
          .map((c) => QuestionCorrection.fromJson(c))
          .toList(),
      statistiques: ExamStatistiques.fromJson(json['statistiques']),
      pourcentage: double.parse(json['pourcentage']?.toString() ?? '0'),
    );
  }

  // Convenience getters
  double get scorePercentage => pourcentage;
  bool get isPassed => pourcentage >= 70.0; // Note de passage par défaut à 70%
  int get totalQuestions => correction.length;
  int get correctAnswers => correction.where((c) => c.estCorrecte).length;
}

class QuestionCorrection {
  final Question question;
  final List<QuestionReponse> reponsesPossibles;
  final int? reponseUtilisateurId;
  final QuestionReponse? reponseUtilisateur;
  final QuestionReponse bonneReponse;
  final bool estCorrecte;
  final int pointsObtenus;

  QuestionCorrection({
    required this.question,
    required this.reponsesPossibles,
    this.reponseUtilisateurId,
    this.reponseUtilisateur,
    required this.bonneReponse,
    required this.estCorrecte,
    required this.pointsObtenus,
  });

  factory QuestionCorrection.fromJson(Map<String, dynamic> json) {
    return QuestionCorrection(
      question: Question.fromJson(json['question']),
      reponsesPossibles: (json['reponses_possibles'] as List)
          .map((r) => QuestionReponse.fromJson(r))
          .toList(),
      reponseUtilisateurId: json['reponse_utilisateur_id'],
      reponseUtilisateur: json['reponse_utilisateur'] != null
          ? QuestionReponse.fromJson(json['reponse_utilisateur'])
          : null,
      bonneReponse: QuestionReponse.fromJson(json['bonne_reponse']),
      estCorrecte: json['est_correcte'] ?? false,
      pointsObtenus: json['points_obtenus'] ?? 0,
    );
  }
}

class ExamStatistiques {
  final int totalQuestions;
  final int bonnesReponses;
  final int mauvaisesReponses;
  final double pourcentageReussite;
  final int tempsPasse; // en secondes

  ExamStatistiques({
    required this.totalQuestions,
    required this.bonnesReponses,
    required this.mauvaisesReponses,
    required this.pourcentageReussite,
    required this.tempsPasse,
  });

  factory ExamStatistiques.fromJson(Map<String, dynamic> json) {
    return ExamStatistiques(
      totalQuestions: json['total_questions'] ?? 0,
      bonnesReponses: json['bonnes_reponses'] ?? 0,
      mauvaisesReponses: json['mauvaises_reponses'] ?? 0,
      pourcentageReussite: double.parse(json['pourcentage_reussite']?.toString() ?? '0'),
      tempsPasse: json['temps_passe'] ?? 0,
    );
  }

  String get tempsPasseFormate {
    final hours = tempsPasse ~/ 3600;
    final minutes = (tempsPasse % 3600) ~/ 60;
    final seconds = tempsPasse % 60;

    if (hours > 0) {
      return '${hours}h ${minutes}min ${seconds}s';
    } else if (minutes > 0) {
      return '${minutes}min ${seconds}s';
    } else {
      return '${seconds}s';
    }
  }
}

class UserAnswer {
  final int questionId;
  final int reponse;

  UserAnswer({
    required this.questionId,
    required this.reponse,
  });

  Map<String, dynamic> toJson() {
    return {
      'question_id': questionId,
      'reponse': reponse,
    };
  }
}