class Certificate {
  final int id;
  final int userId;
  final int formationId;
  final int tentativeId;
  final String formationTitle;
  final String userName;
  final double scoreObtenu;
  final double notePassage;
  final DateTime dateObtention;
  final String certificateCode;
  final bool isValid;
  final DateTime? dateExpiration;

  Certificate({
    required this.id,
    required this.userId,
    required this.formationId,
    required this.tentativeId,
    required this.formationTitle,
    required this.userName,
    required this.scoreObtenu,
    required this.notePassage,
    required this.dateObtention,
    required this.certificateCode,
    required this.isValid,
    this.dateExpiration,
  });

  factory Certificate.fromJson(Map<String, dynamic> json) {
    return Certificate(
      id: json['id'] ?? 0,
      userId: json['user_id'] ?? 0,
      formationId: json['formation_id'] ?? 0,
      tentativeId: json['tentative_id'] ?? 0,
      formationTitle: json['formation_title'] ?? '',
      userName: json['user_name'] ?? '',
      scoreObtenu: double.parse(json['score_obtenu']?.toString() ?? '0'),
      notePassage: double.parse(json['note_passage']?.toString() ?? '0'),
      dateObtention: DateTime.parse(json['date_obtention'] ?? DateTime.now().toIso8601String()),
      certificateCode: json['certificate_code'] ?? '',
      isValid: json['is_valid'] ?? true,
      dateExpiration: json['date_expiration'] != null
          ? DateTime.parse(json['date_expiration'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'formation_id': formationId,
      'tentative_id': tentativeId,
      'formation_title': formationTitle,
      'user_name': userName,
      'score_obtenu': scoreObtenu,
      'note_passage': notePassage,
      'date_obtention': dateObtention.toIso8601String(),
      'certificate_code': certificateCode,
      'is_valid': isValid,
      'date_expiration': dateExpiration?.toIso8601String(),
    };
  }

  bool get isPassed => scoreObtenu >= notePassage;

  String get statusText {
    if (!isValid) return 'Certificat invalide';
    if (dateExpiration != null && DateTime.now().isAfter(dateExpiration!)) {
      return 'Certificat expiré';
    }
    return isPassed ? 'Certifié' : 'Non certifié';
  }

  String get displayScore => '${scoreObtenu.toStringAsFixed(1)}/${notePassage.toStringAsFixed(1)}';
}