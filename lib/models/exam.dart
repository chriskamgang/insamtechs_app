class Exam {
  final int id;
  final int formationId;
  final Map<String, String> titre;
  final Map<String, String> description;
  final int dureeMinutes;
  final double notePassage;
  final bool actif;
  final List<Question> questions;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Exam({
    required this.id,
    required this.formationId,
    required this.titre,
    required this.description,
    required this.dureeMinutes,
    required this.notePassage,
    required this.actif,
    required this.questions,
    this.createdAt,
    this.updatedAt,
  });

  factory Exam.fromJson(Map<String, dynamic> json) {
    return Exam(
      id: json['id'] ?? 0,
      formationId: json['formation_id'] ?? 0,
      titre: _parseStringMap(json['titre']),
      description: _parseStringMap(json['description']),
      dureeMinutes: json['duree_minutes'] ?? 60,
      notePassage: double.parse(json['note_passage']?.toString() ?? '0'),
      actif: json['actif'] ?? true,
      questions: (json['questions'] as List?)
          ?.map((q) => Question.fromJson(q))
          .toList() ?? [],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
    );
  }

  /// Helper pour parser les Maps avec des valeurs potentiellement null
  static Map<String, String> _parseStringMap(dynamic value) {
    if (value == null) return {'fr': '', 'en': ''};
    if (value is Map) {
      return Map<String, String>.from(
        value.map((key, val) => MapEntry(key.toString(), val?.toString() ?? ''))
      );
    }
    if (value is String) {
      return {'fr': value, 'en': value};
    }
    return {'fr': '', 'en': ''};
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'formation_id': formationId,
      'titre': titre,
      'description': description,
      'duree_minutes': dureeMinutes,
      'note_passage': notePassage,
      'actif': actif,
      'questions': questions.map((q) => q.toJson()).toList(),
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}

class Question {
  final int id;
  final int examenId;
  final Map<String, String> question;
  final String type; // qcm, vrai_faux, texte
  final int points;
  final int ordre;
  final List<QuestionReponse> reponses;

  Question({
    required this.id,
    required this.examenId,
    required this.question,
    required this.type,
    required this.points,
    required this.ordre,
    required this.reponses,
  });

  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
      id: json['id'] ?? 0,
      examenId: json['examen_id'] ?? 0,
      question: Exam._parseStringMap(json['question']),
      type: json['type'] ?? 'qcm',
      points: json['points'] ?? 1,
      ordre: json['ordre'] ?? 1,
      reponses: (json['reponses'] as List?)
          ?.map((r) => QuestionReponse.fromJson(r))
          .toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'examen_id': examenId,
      'question': question,
      'type': type,
      'points': points,
      'ordre': ordre,
      'reponses': reponses.map((r) => r.toJson()).toList(),
    };
  }
}

class QuestionReponse {
  final int id;
  final int questionId;
  final Map<String, String> reponse;
  final bool estCorrect;
  final int ordre;

  QuestionReponse({
    required this.id,
    required this.questionId,
    required this.reponse,
    required this.estCorrect,
    required this.ordre,
  });

  factory QuestionReponse.fromJson(Map<String, dynamic> json) {
    return QuestionReponse(
      id: json['id'] ?? 0,
      questionId: json['question_id'] ?? 0,
      reponse: Exam._parseStringMap(json['reponse']),
      estCorrect: json['est_correct'] ?? false,
      ordre: json['ordre'] ?? 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'question_id': questionId,
      'reponse': reponse,
      'est_correct': estCorrect,
      'ordre': ordre,
    };
  }
}