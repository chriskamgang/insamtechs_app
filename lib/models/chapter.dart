import 'package:json_annotation/json_annotation.dart';

part 'chapter.g.dart';

@JsonSerializable()
class Chapter {
  final int id;
  @JsonKey(name: 'formation_id')
  final int formationId;
  final Map<String, String> titre;
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
  final Map<String, String> titre;
  final Map<String, String>? description;
  final String? url;
  final String? duree;
  final bool? gratuit;
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
    this.thumbnail,
    this.createdAt,
    this.updatedAt,
  });

  factory Video.fromJson(Map<String, dynamic> json) => _$VideoFromJson(json);
  Map<String, dynamic> toJson() => _$VideoToJson(this);

  // Convenience getters
  String get title => titre['fr'] ?? titre['en'] ?? 'Vidéo sans titre';
  String get videoDescription => description?['fr'] ?? description?['en'] ?? '';
  bool get isFree => gratuit ?? false;
  String get thumbnailUrl => thumbnail ?? '';
  String get duration => duree ?? '0:00';
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