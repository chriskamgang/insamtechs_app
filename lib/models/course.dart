import 'package:json_annotation/json_annotation.dart';
import 'chapter.dart';

part 'course.g.dart';

@JsonSerializable()
class Course {
  final int id;
  @JsonKey(name: 'categorie_id')
  final int categorieId;
  @JsonKey(name: 'type_formation_id')
  final int typeFormationId;
  final Map<String, String> intitule;
  final Map<String, String> description;
  @JsonKey(name: 'langue_formation')
  final dynamic langueFormation;
  final Map<String, String> prix;
  final String? lien;
  @JsonKey(name: 'correction_link')
  final String? correctionLink;
  @JsonKey(name: 'nombre_de_points')
  final int? nombreDePoints;
  final String duree;
  @JsonKey(name: 'duree_composition')
  final String? dureeComposition;
  final String date;
  final String slug;
  final dynamic telechargeable;
  final int etat;
  final String? img;
  @JsonKey(name: 'created_at')
  final String? createdAt;
  @JsonKey(name: 'updated_at')
  final String? updatedAt;
  final CourseCategory? categorie;
  @JsonKey(name: 'type_formation')
  final FormationType? typeFormation;
  final List<Chapter>? chapitres;
  final List<CourseReview>? avis;
  @JsonKey(name: 'enrollment_status')
  final EnrollmentStatus? enrollmentStatus;

  Course({
    required this.id,
    required this.categorieId,
    required this.typeFormationId,
    required this.intitule,
    required this.description,
    this.langueFormation,
    required this.prix,
    this.lien,
    this.correctionLink,
    this.nombreDePoints,
    required this.duree,
    this.dureeComposition,
    required this.date,
    required this.slug,
    this.telechargeable,
    required this.etat,
    this.img,
    this.createdAt,
    this.updatedAt,
    this.categorie,
    this.typeFormation,
    this.chapitres,
    this.avis,
    this.enrollmentStatus,
  });

  factory Course.fromJson(Map<String, dynamic> json) => _$CourseFromJson(json);
  Map<String, dynamic> toJson() => _$CourseToJson(this);

  // Convenience getters
  String get title => intitule['fr'] ?? intitule['en'] ?? 'Cours sans titre';
  String get courseDescription => description['fr'] ?? description['en'] ?? '';
  String get price => prix['fr'] ?? prix['en'] ?? '0';
  String get categoryName => categorie?.name ?? '';
  String get instructor => 'Par ${categorie?.name ?? "Instructeur"}';

  // Calculate average rating from reviews
  double get rating => avis != null && avis!.isNotEmpty
      ? avis!.map((review) => review.rating).reduce((a, b) => a + b) / avis!.length
      : 5.0;

  // Progress from enrollment status
  double get progress => enrollmentStatus?.progressPercentage ?? 0.0;

  // Image URL with fallback - construct full URL from backend
  String? get imageUrl {
    if (img != null && img!.isNotEmpty) {
      // If the image path is already a full URL, return as is
      if (img!.startsWith('http://') || img!.startsWith('https://')) {
        return img!;
      }

      // Construct full URL for backend images
      // Backend serves images from storage/app/public, accessible via storage symlink
      const baseUrl = 'http://192.168.1.180:8001';

      // Clean the path by removing any leading slash or 'storage/' prefix
      String cleanPath = img!;
      if (cleanPath.startsWith('/')) {
        cleanPath = cleanPath.substring(1);
      }
      if (!cleanPath.startsWith('storage/')) {
        cleanPath = 'storage/$cleanPath';
      }

      return '$baseUrl/$cleanPath';
    }
    return null; // Return null instead of asset path for network images
  }

  // Additional getters for course details
  List<Chapter> get chapters => chapitres ?? [];
  List<CourseReview> get reviews => avis ?? [];
  bool get isEnrolled => enrollmentStatus?.isEnrolled ?? false;
  int get totalVideos => chapters.fold(0, (total, chapter) => total + (chapter.videoCount));
  int get totalChapters => chapters.length;
  int get reviewCount => reviews.length;

  // Intro video URL - using the 'lien' field as the intro video
  String? get introVideoUrl => lien;

  // Check if the course has an intro video
  bool get hasIntroVideo => lien != null && lien!.isNotEmpty;
}

@JsonSerializable()
class CourseCategory {
  final int id;
  final dynamic intitule; // Can be Map or String
  final String? img;
  final int type;
  final String date;
  final String slug;
  @JsonKey(name: 'created_at')
  final String? createdAt;
  @JsonKey(name: 'updated_at')
  final String? updatedAt;

  CourseCategory({
    required this.id,
    required this.intitule,
    this.img,
    required this.type,
    required this.date,
    required this.slug,
    this.createdAt,
    this.updatedAt,
  });

  factory CourseCategory.fromJson(Map<String, dynamic> json) => _$CourseCategoryFromJson(json);
  Map<String, dynamic> toJson() => _$CourseCategoryToJson(this);

  String get name {
    if (intitule is Map) {
      return (intitule as Map)['fr']?.toString() ?? (intitule as Map)['en']?.toString() ?? 'Catégorie';
    } else if (intitule is String) {
      return intitule as String;
    }
    return 'Catégorie';
  }

  // Image URL with fallback - construct full URL from backend
  String? get imageUrl {
    if (img != null && img!.isNotEmpty) {
      // If the image path is already a full URL, return as is
      if (img!.startsWith('http://') || img!.startsWith('https://')) {
        return img!;
      }

      // Use production backend URL
      const baseUrl = 'https://admin.insamtechs.com';

      // Clean the path by removing any leading slash or 'storage/' prefix
      String cleanPath = img!;
      if (cleanPath.startsWith('/')) {
        cleanPath = cleanPath.substring(1);
      }
      if (!cleanPath.startsWith('storage/')) {
        cleanPath = 'storage/$cleanPath';
      }

      return '$baseUrl/$cleanPath';
    }
    return null;
  }
}

@JsonSerializable()
class FormationType {
  final int id;
  final dynamic intitule; // Can be String or Map<String, String>
  @JsonKey(name: 'created_at')
  final String? createdAt;
  @JsonKey(name: 'updated_at')
  final String? updatedAt;

  FormationType({
    required this.id,
    required this.intitule,
    this.createdAt,
    this.updatedAt,
  });

  factory FormationType.fromJson(Map<String, dynamic> json) => _$FormationTypeFromJson(json);
  Map<String, dynamic> toJson() => _$FormationTypeToJson(this);

  String get name {
    if (intitule is Map) {
      return (intitule as Map)['fr']?.toString() ?? (intitule as Map)['en']?.toString() ?? 'Formation';
    } else if (intitule is String) {
      return intitule as String;
    }
    return 'Formation';
  }
}

@JsonSerializable()
class CoursesResponse {
  @JsonKey(name: 'current_page')
  final int currentPage;
  final List<Course> data;
  @JsonKey(name: 'first_page_url')
  final String firstPageUrl;
  final int? from;
  @JsonKey(name: 'last_page')
  final int lastPage;
  @JsonKey(name: 'last_page_url')
  final String lastPageUrl;
  final List<PageLink> links;
  @JsonKey(name: 'next_page_url')
  final String? nextPageUrl;
  final String path;
  @JsonKey(name: 'per_page')
  final int perPage;
  @JsonKey(name: 'prev_page_url')
  final String? prevPageUrl;
  final int? to;
  final int total;

  CoursesResponse({
    required this.currentPage,
    required this.data,
    required this.firstPageUrl,
    this.from,
    required this.lastPage,
    required this.lastPageUrl,
    required this.links,
    this.nextPageUrl,
    required this.path,
    required this.perPage,
    this.prevPageUrl,
    this.to,
    required this.total,
  });

  factory CoursesResponse.fromJson(Map<String, dynamic> json) => _$CoursesResponseFromJson(json);
  Map<String, dynamic> toJson() => _$CoursesResponseToJson(this);
}

@JsonSerializable()
class PageLink {
  final String? url;
  final String label;
  final bool active;

  PageLink({
    this.url,
    required this.label,
    required this.active,
  });

  factory PageLink.fromJson(Map<String, dynamic> json) => _$PageLinkFromJson(json);
  Map<String, dynamic> toJson() => _$PageLinkToJson(this);
}