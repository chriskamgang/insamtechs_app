import 'dart:convert';
import 'package:json_annotation/json_annotation.dart';

part 'chapter.g.dart';

// Helper function to parse intitule field which can be either a Map or a JSON string
Map<String, String> _parseIntitule(dynamic value) {
  if (value == null) {
    return {'fr': '', 'en': ''};
  }

  // If it's already a Map, return it
  if (value is Map) {
    return Map<String, String>.from(value.map(
      (key, val) => MapEntry(key.toString(), val.toString())
    ));
  }

  // If it's a String, try to parse it as JSON
  if (value is String) {
    try {
      final parsed = jsonDecode(value);
      if (parsed is Map) {
        return Map<String, String>.from(parsed.map(
          (key, val) => MapEntry(key.toString(), val.toString())
        ));
      }
    } catch (e) {
      print('⚠️ [Chapter] Error parsing intitule JSON string: $e');
    }
  }

  return {'fr': '', 'en': ''};
}

// Optional version that returns null instead of empty map
Map<String, String>? _parseIntituleOptional(dynamic value) {
  if (value == null) {
    return null;
  }

  final result = _parseIntitule(value);
  // Return null if the result is empty
  if (result['fr']?.isEmpty == true && result['en']?.isEmpty == true) {
    return null;
  }

  return result;
}

@JsonSerializable()
class Chapter {
  final int id;
  @JsonKey(name: 'formation_id')
  final int formationId;
  @JsonKey(name: 'intitule', fromJson: _parseIntitule)  // Backend utilise 'intitule'
  final Map<String, String> titre;
  @JsonKey(fromJson: _parseIntituleOptional)
  final Map<String, String>? description;
  final String? duree;
  final bool? gratuit;
  @JsonKey(name: 'created_at')
  final String? createdAt;
  @JsonKey(name: 'updated_at')
  final String? updatedAt;
  final List<Video>? videos;

  Chapter({
    required this.id,
    required this.formationId,
    required this.titre,
    this.description,
    this.duree,
    this.gratuit,
    this.createdAt,
    this.updatedAt,
    this.videos,
  });

  factory Chapter.fromJson(Map<String, dynamic> json) => _$ChapterFromJson(json);
  Map<String, dynamic> toJson() => _$ChapterToJson(this);

  // Convenience getters
  String get title => titre['fr'] ?? titre['en'] ?? 'Chapitre sans titre';
  String get chapterDescription => description?['fr'] ?? description?['en'] ?? '';
  bool get isFree => gratuit ?? false;
  int get videoCount => videos?.length ?? 0;
}

@JsonSerializable()
class Video {
  final int id;
  @JsonKey(name: 'chapitre_id')
  final int chapitreId;
  @JsonKey(name: 'intitule', fromJson: _parseIntitule)  // Backend utilise 'intitule' pour les vidéos aussi
  final Map<String, String> titre;
  @JsonKey(fromJson: _parseIntituleOptional)
  final Map<String, String>? description;
  @JsonKey(name: 'lien', fromJson: _urlFromJson)  // Backend utilise 'lien' au lieu de 'url'
  final String? url;
  final String? duree;
  final bool? gratuit;
  final String? image;  // Image thumbnail from API
  final String? thumbnail;
  @JsonKey(name: 'created_at')
  final String? createdAt;
  @JsonKey(name: 'updated_at')
  final String? updatedAt;

  Video({
    required this.id,
    required this.chapitreId,
    required this.titre,
    this.description,
    this.url,
    this.duree,
    this.gratuit,
    this.image,
    this.thumbnail,
    this.createdAt,
    this.updatedAt,
  });

  // Custom JSON converter to handle "null" string from API
  static String? _urlFromJson(dynamic value) {
    if (value == null || value == 'null' || value == '') {
      return null;
    }
    return value as String?;
  }

  factory Video.fromJson(Map<String, dynamic> json) => _$VideoFromJson(json);
  Map<String, dynamic> toJson() => _$VideoToJson(this);

  // Convenience getters
  String get title => titre['fr'] ?? titre['en'] ?? 'Vidéo sans titre';
  String get videoDescription => description?['fr'] ?? description?['en'] ?? '';
  bool get isFree => gratuit ?? false;
  String get thumbnailUrl => image ?? thumbnail ?? '';
  String get duration => duree ?? '0:00';
  bool get hasValidUrl => url != null && url!.isNotEmpty;
}

@JsonSerializable()
class CourseReview {
  final int id;
  @JsonKey(name: 'user_id')
  final int userId;
  @JsonKey(name: 'formation_id')
  final int formationId;
  final int? note;
  final String? commentaire;
  @JsonKey(name: 'created_at')
  final String? createdAt;
  @JsonKey(name: 'updated_at')
  final String? updatedAt;
  final ReviewUser? user;

  CourseReview({
    required this.id,
    required this.userId,
    required this.formationId,
    this.note,
    this.commentaire,
    this.createdAt,
    this.updatedAt,
    this.user,
  });

  factory CourseReview.fromJson(Map<String, dynamic> json) => _$CourseReviewFromJson(json);
  Map<String, dynamic> toJson() => _$CourseReviewToJson(this);

  String get comment => commentaire ?? '';
  double get rating => note?.toDouble() ?? 5.0;
  String get userName => user?.name ?? 'Utilisateur anonyme';
  String get reviewDate => createdAt ?? '';
}

@JsonSerializable()
class ReviewUser {
  final int id;
  final String nom;
  final String prenom;
  final String? photo;

  ReviewUser({
    required this.id,
    required this.nom,
    required this.prenom,
    this.photo,
  });

  factory ReviewUser.fromJson(Map<String, dynamic> json) => _$ReviewUserFromJson(json);
  Map<String, dynamic> toJson() => _$ReviewUserToJson(this);

  String get name => '$prenom $nom';
}

@JsonSerializable()
class EnrollmentStatus {
  @JsonKey(name: 'is_enrolled')
  final bool isEnrolled;
  @JsonKey(name: 'enrollment_date')
  final String? enrollmentDate;
  final double? progress;
  @JsonKey(name: 'last_watched_video')
  final int? lastWatchedVideo;
  @JsonKey(name: 'completed_videos')
  final List<int>? completedVideos;

  EnrollmentStatus({
    required this.isEnrolled,
    this.enrollmentDate,
    this.progress,
    this.lastWatchedVideo,
    this.completedVideos,
  });

  factory EnrollmentStatus.fromJson(Map<String, dynamic> json) => _$EnrollmentStatusFromJson(json);
  Map<String, dynamic> toJson() => _$EnrollmentStatusToJson(this);

  double get progressPercentage => progress ?? 0.0;
  int get completedCount => completedVideos?.length ?? 0;
}