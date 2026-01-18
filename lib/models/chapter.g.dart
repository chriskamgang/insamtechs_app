// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chapter.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Chapter _$ChapterFromJson(Map<String, dynamic> json) => Chapter(
  id: (json['id'] as num).toInt(),
  formationId: (json['formation_id'] as num).toInt(),
  titre: _parseIntitule(json['intitule']),
  description: _parseIntituleOptional(json['description']),
  duree: json['duree'] as String?,
  gratuit: json['gratuit'] as bool?,
  createdAt: json['created_at'] as String?,
  updatedAt: json['updated_at'] as String?,
  videos: (json['videos'] as List<dynamic>?)
      ?.map((e) => Video.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$ChapterToJson(Chapter instance) => <String, dynamic>{
  'id': instance.id,
  'formation_id': instance.formationId,
  'intitule': instance.titre,
  'description': instance.description,
  'duree': instance.duree,
  'gratuit': instance.gratuit,
  'created_at': instance.createdAt,
  'updated_at': instance.updatedAt,
  'videos': instance.videos,
};

Video _$VideoFromJson(Map<String, dynamic> json) => Video(
  id: (json['id'] as num).toInt(),
  chapitreId: (json['chapitre_id'] as num).toInt(),
  titre: _parseIntitule(json['intitule']),
  description: _parseIntituleOptional(json['description']),
  url: Video._urlFromJson(json['lien']),
  duree: json['duree'] as String?,
  gratuit: json['gratuit'] as bool?,
  image: json['image'] as String?,
  thumbnail: json['thumbnail'] as String?,
  createdAt: json['created_at'] as String?,
  updatedAt: json['updated_at'] as String?,
);

Map<String, dynamic> _$VideoToJson(Video instance) => <String, dynamic>{
  'id': instance.id,
  'chapitre_id': instance.chapitreId,
  'intitule': instance.titre,
  'description': instance.description,
  'lien': instance.url,
  'duree': instance.duree,
  'gratuit': instance.gratuit,
  'image': instance.image,
  'thumbnail': instance.thumbnail,
  'created_at': instance.createdAt,
  'updated_at': instance.updatedAt,
};

CourseReview _$CourseReviewFromJson(Map<String, dynamic> json) => CourseReview(
  id: (json['id'] as num).toInt(),
  userId: (json['user_id'] as num).toInt(),
  formationId: (json['formation_id'] as num).toInt(),
  note: (json['note'] as num?)?.toInt(),
  commentaire: json['commentaire'] as String?,
  createdAt: json['created_at'] as String?,
  updatedAt: json['updated_at'] as String?,
  user: json['user'] == null
      ? null
      : ReviewUser.fromJson(json['user'] as Map<String, dynamic>),
);

Map<String, dynamic> _$CourseReviewToJson(CourseReview instance) =>
    <String, dynamic>{
      'id': instance.id,
      'user_id': instance.userId,
      'formation_id': instance.formationId,
      'note': instance.note,
      'commentaire': instance.commentaire,
      'created_at': instance.createdAt,
      'updated_at': instance.updatedAt,
      'user': instance.user,
    };

ReviewUser _$ReviewUserFromJson(Map<String, dynamic> json) => ReviewUser(
  id: (json['id'] as num).toInt(),
  nom: json['nom'] as String,
  prenom: json['prenom'] as String,
  photo: json['photo'] as String?,
);

Map<String, dynamic> _$ReviewUserToJson(ReviewUser instance) =>
    <String, dynamic>{
      'id': instance.id,
      'nom': instance.nom,
      'prenom': instance.prenom,
      'photo': instance.photo,
    };

EnrollmentStatus _$EnrollmentStatusFromJson(Map<String, dynamic> json) =>
    EnrollmentStatus(
      isEnrolled: json['is_enrolled'] as bool,
      enrollmentDate: json['enrollment_date'] as String?,
      progress: (json['progress'] as num?)?.toDouble(),
      lastWatchedVideo: (json['last_watched_video'] as num?)?.toInt(),
      completedVideos: (json['completed_videos'] as List<dynamic>?)
          ?.map((e) => (e as num).toInt())
          .toList(),
    );

Map<String, dynamic> _$EnrollmentStatusToJson(EnrollmentStatus instance) =>
    <String, dynamic>{
      'is_enrolled': instance.isEnrolled,
      'enrollment_date': instance.enrollmentDate,
      'progress': instance.progress,
      'last_watched_video': instance.lastWatchedVideo,
      'completed_videos': instance.completedVideos,
    };
