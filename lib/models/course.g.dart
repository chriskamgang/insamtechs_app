// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'course.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Course _$CourseFromJson(Map<String, dynamic> json) => Course(
  id: (json['id'] as num).toInt(),
  categorieId: (json['categorie_id'] as num).toInt(),
  typeFormationId: (json['type_formation_id'] as num).toInt(),
  intitule: Map<String, String>.from(json['intitule'] as Map),
  description: Map<String, String>.from(json['description'] as Map),
  langueFormation: json['langue_formation'],
  prix: Map<String, String>.from(json['prix'] as Map),
  lien: json['lien'] as String?,
  correctionLink: json['correction_link'] as String?,
  nombreDePoints: (json['nombre_de_points'] as num?)?.toInt(),
  duree: json['duree'] as String,
  dureeComposition: json['duree_composition'] as String?,
  date: json['date'] as String,
  slug: json['slug'] as String,
  telechargeable: json['telechargeable'],
  etat: (json['etat'] as num).toInt(),
  img: json['img'] as String?,
  createdAt: json['created_at'] as String?,
  updatedAt: json['updated_at'] as String?,
  categorie: json['categorie'] == null
      ? null
      : CourseCategory.fromJson(json['categorie'] as Map<String, dynamic>),
  typeFormation: json['type_formation'] == null
      ? null
      : FormationType.fromJson(json['type_formation'] as Map<String, dynamic>),
  chapitres: (json['chapitres'] as List<dynamic>?)
      ?.map((e) => Chapter.fromJson(e as Map<String, dynamic>))
      .toList(),
  avis: (json['avis'] as List<dynamic>?)
      ?.map((e) => CourseReview.fromJson(e as Map<String, dynamic>))
      .toList(),
  enrollmentStatus: json['enrollment_status'] == null
      ? null
      : EnrollmentStatus.fromJson(
          json['enrollment_status'] as Map<String, dynamic>,
        ),
);

Map<String, dynamic> _$CourseToJson(Course instance) => <String, dynamic>{
  'id': instance.id,
  'categorie_id': instance.categorieId,
  'type_formation_id': instance.typeFormationId,
  'intitule': instance.intitule,
  'description': instance.description,
  'langue_formation': instance.langueFormation,
  'prix': instance.prix,
  'lien': instance.lien,
  'correction_link': instance.correctionLink,
  'nombre_de_points': instance.nombreDePoints,
  'duree': instance.duree,
  'duree_composition': instance.dureeComposition,
  'date': instance.date,
  'slug': instance.slug,
  'telechargeable': instance.telechargeable,
  'etat': instance.etat,
  'img': instance.img,
  'created_at': instance.createdAt,
  'updated_at': instance.updatedAt,
  'categorie': instance.categorie,
  'type_formation': instance.typeFormation,
  'chapitres': instance.chapitres,
  'avis': instance.avis,
  'enrollment_status': instance.enrollmentStatus,
};

CourseCategory _$CourseCategoryFromJson(Map<String, dynamic> json) =>
    CourseCategory(
      id: (json['id'] as num).toInt(),
      intitule: json['intitule'],
      img: json['img'] as String?,
      type: (json['type'] as num).toInt(),
      date: json['date'] as String,
      slug: json['slug'] as String,
      createdAt: json['created_at'] as String?,
      updatedAt: json['updated_at'] as String?,
    );

Map<String, dynamic> _$CourseCategoryToJson(CourseCategory instance) =>
    <String, dynamic>{
      'id': instance.id,
      'intitule': instance.intitule,
      'img': instance.img,
      'type': instance.type,
      'date': instance.date,
      'slug': instance.slug,
      'created_at': instance.createdAt,
      'updated_at': instance.updatedAt,
    };

FormationType _$FormationTypeFromJson(Map<String, dynamic> json) =>
    FormationType(
      id: (json['id'] as num).toInt(),
      intitule: json['intitule'],
      createdAt: json['created_at'] as String?,
      updatedAt: json['updated_at'] as String?,
    );

Map<String, dynamic> _$FormationTypeToJson(FormationType instance) =>
    <String, dynamic>{
      'id': instance.id,
      'intitule': instance.intitule,
      'created_at': instance.createdAt,
      'updated_at': instance.updatedAt,
    };

CoursesResponse _$CoursesResponseFromJson(Map<String, dynamic> json) =>
    CoursesResponse(
      currentPage: (json['current_page'] as num).toInt(),
      data: (json['data'] as List<dynamic>)
          .map((e) => Course.fromJson(e as Map<String, dynamic>))
          .toList(),
      firstPageUrl: json['first_page_url'] as String,
      from: (json['from'] as num?)?.toInt(),
      lastPage: (json['last_page'] as num).toInt(),
      lastPageUrl: json['last_page_url'] as String,
      links: (json['links'] as List<dynamic>)
          .map((e) => PageLink.fromJson(e as Map<String, dynamic>))
          .toList(),
      nextPageUrl: json['next_page_url'] as String?,
      path: json['path'] as String,
      perPage: (json['per_page'] as num).toInt(),
      prevPageUrl: json['prev_page_url'] as String?,
      to: (json['to'] as num?)?.toInt(),
      total: (json['total'] as num).toInt(),
    );

Map<String, dynamic> _$CoursesResponseToJson(CoursesResponse instance) =>
    <String, dynamic>{
      'current_page': instance.currentPage,
      'data': instance.data,
      'first_page_url': instance.firstPageUrl,
      'from': instance.from,
      'last_page': instance.lastPage,
      'last_page_url': instance.lastPageUrl,
      'links': instance.links,
      'next_page_url': instance.nextPageUrl,
      'path': instance.path,
      'per_page': instance.perPage,
      'prev_page_url': instance.prevPageUrl,
      'to': instance.to,
      'total': instance.total,
    };

PageLink _$PageLinkFromJson(Map<String, dynamic> json) => PageLink(
  url: json['url'] as String?,
  label: json['label'] as String,
  active: json['active'] as bool,
);

Map<String, dynamic> _$PageLinkToJson(PageLink instance) => <String, dynamic>{
  'url': instance.url,
  'label': instance.label,
  'active': instance.active,
};
