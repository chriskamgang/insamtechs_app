import '../models/course.dart';
import '../models/search_response.dart';
import '../config/api_config.dart';
import 'api_service.dart';

class CourseService {
  static final CourseService _instance = CourseService._internal();
  factory CourseService() => _instance;
  CourseService._internal();

  final ApiService _apiService = ApiService();

  /// Fetch all courses with pagination
  Future<CoursesResponse> getCourses({int page = 1}) async {
    print('🔵 [CourseService] getCourses() - Starting with page: $page');
    try {
      print('🔵 [CourseService] getCourses() - Calling API: ${ApiConfig.coursesEndpoint}');
      final response = await _apiService.get(
        ApiConfig.coursesEndpoint,
        queryParameters: {'page': page},
      );

      print('✅ [CourseService] getCourses() - Success, courses count: ${response.data?['data']?.length ?? 0}');

      // Sanitize the response data to handle null values
      final sanitizedData = _sanitizeCoursesResponse(response.data);

      return CoursesResponse.fromJson(sanitizedData);
    } catch (e) {
      print('❌ [CourseService] getCourses() - Error: ${e.toString()}');
      throw CourseException('Erreur lors du chargement des cours: ${e.toString()}');
    }
  }

  /// Fetch courses by category
  Future<CoursesResponse> getCoursesByCategory(String categorySlug, {int page = 1}) async {
    try {
      final response = await _apiService.get(
        '${ApiConfig.coursesByCategoryEndpoint}/$categorySlug',
        queryParameters: {'page': page},
      );

      // Sanitize the response data to handle null values
      final sanitizedData = _sanitizeCoursesResponse(response.data);

      return CoursesResponse.fromJson(sanitizedData);
    } catch (e) {
      throw CourseException('Erreur lors du chargement des cours par catégorie: ${e.toString()}');
    }
  }

  /// Search courses
  Future<List<Course>> searchCourses(String query) async {
    try {
      // First try the dedicated search endpoint
      try {
        final response = await _apiService.get(
          ApiConfig.searchEndpoint,
          queryParameters: {
            'q': query,
          },
        );

        final searchResponse = SearchResponse.fromJson(response.data);

        // If search endpoint returns results, use them
        if (searchResponse.results.formations.isNotEmpty) {
          return searchResponse.results.formations;
        }
      } catch (e) {
        print('Search endpoint failed, falling back to client-side filtering: $e');
      }

      // Fallback: Get all courses and filter client-side
      final coursesResponse = await getCourses(page: 1);
      final allCourses = coursesResponse.data;

      final queryLower = query.toLowerCase();
      final filteredCourses = allCourses.where((course) {
        return course.title.toLowerCase().contains(queryLower) ||
               course.courseDescription.toLowerCase().contains(queryLower) ||
               course.categoryName.toLowerCase().contains(queryLower);
      }).toList();

      return filteredCourses;
    } catch (e) {
      throw CourseException('Erreur lors de la recherche: ${e.toString()}');
    }
  }

  /// Get course details by slug
  Future<Course> getCourseBySlug(String slug) async {
    print('🔵 [CourseService] getCourseBySlug() - Starting with slug: $slug');
    try {
      final endpoint = '${ApiConfig.courseBySlugEndpoint}/$slug';
      print('🔵 [CourseService] getCourseBySlug() - Calling API: $endpoint');

      final response = await _apiService.get(endpoint);

      print('✅ [CourseService] getCourseBySlug() - Success, got course data');
      print('📊 [CourseService] getCourseBySlug() - Course has ${response.data?['chapitres']?.length ?? 0} chapters');

      // Sanitize the response data to handle null values in arrays
      final sanitizedData = _sanitizeCourseData(response.data);

      return Course.fromJson(sanitizedData);
    } catch (e) {
      print('❌ [CourseService] getCourseBySlug() - Error: ${e.toString()}');
      print('🔧 [CourseService] getCourseBySlug() - Error type: ${e.runtimeType}');
      throw CourseException('Erreur lors du chargement du cours: ${e.toString()}');
    }
  }

  /// Sanitize courses response to handle null values in the data array
  Map<String, dynamic> _sanitizeCoursesResponse(Map<String, dynamic> response) {
    final sanitized = Map<String, dynamic>.from(response);

    // Handle the 'data' array which contains courses
    if (sanitized['data'] is List) {
      final dataList = sanitized['data'] as List;
      final sanitizedCourses = <Map<String, dynamic>>[];

      for (final courseData in dataList) {
        if (courseData != null && courseData is Map<String, dynamic>) {
          sanitizedCourses.add(_sanitizeCourseDataShallow(courseData));
        }
      }

      sanitized['data'] = sanitizedCourses;
    }

    return sanitized;
  }

  /// Sanitize course data for list responses (shallow sanitization without chapters/reviews)
  Map<String, dynamic> _sanitizeCourseDataShallow(Map<String, dynamic> data) {
    final sanitized = Map<String, dynamic>.from(data);

    // Ensure required string fields have default values
    sanitized['duree'] ??= '0:00';
    sanitized['date'] ??= DateTime.now().toString().split(' ')[0];
    sanitized['slug'] ??= 'course-${sanitized['id'] ?? 'unknown'}';

    // Ensure Map<String, String> fields are properly formatted
    if (sanitized['intitule'] == null || sanitized['intitule'] is! Map) {
      sanitized['intitule'] = {'fr': 'Cours sans titre', 'en': 'Untitled course'};
    } else {
      final intituleMap = Map<String, dynamic>.from(sanitized['intitule'] as Map);
      sanitized['intitule'] = {
        'fr': intituleMap['fr']?.toString() ?? 'Cours sans titre',
        'en': intituleMap['en']?.toString() ?? 'Untitled course',
      };
    }

    if (sanitized['description'] == null || sanitized['description'] is! Map) {
      sanitized['description'] = {'fr': '', 'en': ''};
    } else {
      final descMap = Map<String, dynamic>.from(sanitized['description'] as Map);
      sanitized['description'] = {
        'fr': descMap['fr']?.toString() ?? '',
        'en': descMap['en']?.toString() ?? '',
      };
    }

    if (sanitized['prix'] == null || sanitized['prix'] is! Map) {
      sanitized['prix'] = {'fr': '0', 'en': '0'};
    } else {
      final prixMap = Map<String, dynamic>.from(sanitized['prix'] as Map);
      sanitized['prix'] = {
        'fr': prixMap['fr']?.toString() ?? '0',
        'en': prixMap['en']?.toString() ?? '0',
      };
    }

    return sanitized;
  }

  /// Sanitize course data to handle null values and prevent casting errors
  Map<String, dynamic> _sanitizeCourseData(Map<String, dynamic> data) {
    final sanitized = Map<String, dynamic>.from(data);

    // Handle chapitres array - remove null entries and sanitize each chapter
    if (sanitized['chapitres'] is List) {
      final chapitresRaw = sanitized['chapitres'] as List;
      final chapitres = <Map<String, dynamic>>[];

      for (final chapter in chapitresRaw) {
        if (chapter != null && chapter is Map<String, dynamic>) {
          chapitres.add(_sanitizeChapterData(chapter));
        }
      }

      sanitized['chapitres'] = chapitres;
    }

    // Handle avis array - remove null entries and sanitize each review
    if (sanitized['avis'] is List) {
      final avisRaw = sanitized['avis'] as List;
      final avis = <Map<String, dynamic>>[];

      for (final review in avisRaw) {
        if (review != null && review is Map<String, dynamic>) {
          avis.add(_sanitizeReviewData(review));
        }
      }

      sanitized['avis'] = avis;
    }

    return sanitized;
  }

  /// Sanitize chapter data to handle null values
  Map<String, dynamic> _sanitizeChapterData(Map<String, dynamic> chapter) {
    final sanitized = Map<String, dynamic>.from(chapter);

    // Ensure titre is not null and is a proper Map with valid content
    if (sanitized['titre'] == null) {
      sanitized['titre'] = {'fr': 'Chapitre sans titre', 'en': 'Untitled chapter'};
    } else if (sanitized['titre'] is Map) {
      final titreMap = sanitized['titre'] as Map;
      final frTitle = titreMap['fr']?.toString().trim();
      final enTitle = titreMap['en']?.toString().trim();

      // If both French and English titles are empty or null, provide defaults
      if ((frTitle == null || frTitle.isEmpty) && (enTitle == null || enTitle.isEmpty)) {
        sanitized['titre'] = {'fr': 'Chapitre sans titre', 'en': 'Untitled chapter'};
      } else {
        // Ensure at least one language has a valid title
        sanitized['titre'] = {
          'fr': (frTitle != null && frTitle.isNotEmpty) ? frTitle : 'Chapitre sans titre',
          'en': (enTitle != null && enTitle.isNotEmpty) ? enTitle : 'Untitled chapter',
        };
      }
    }

    // Handle videos array - remove null entries and ensure safe casting
    if (sanitized['videos'] is List) {
      final videosRaw = sanitized['videos'] as List;
      final videos = <Map<String, dynamic>>[];

      for (final video in videosRaw) {
        if (video != null && video is Map<String, dynamic>) {
          videos.add(_sanitizeVideoData(video));
        }
      }

      sanitized['videos'] = videos;
    }

    return sanitized;
  }

  /// Sanitize video data to handle null values
  Map<String, dynamic> _sanitizeVideoData(Map<String, dynamic> video) {
    final sanitized = Map<String, dynamic>.from(video);

    // Ensure titre is not null and is a proper Map with valid content
    if (sanitized['titre'] == null) {
      sanitized['titre'] = {'fr': 'Vidéo sans titre', 'en': 'Untitled video'};
    } else if (sanitized['titre'] is Map) {
      final titreMap = sanitized['titre'] as Map;
      final frTitle = titreMap['fr']?.toString().trim();
      final enTitle = titreMap['en']?.toString().trim();

      // If both French and English titles are empty or null, provide defaults
      if ((frTitle == null || frTitle.isEmpty) && (enTitle == null || enTitle.isEmpty)) {
        sanitized['titre'] = {'fr': 'Vidéo sans titre', 'en': 'Untitled video'};
      } else {
        // Ensure at least one language has a valid title
        sanitized['titre'] = {
          'fr': (frTitle != null && frTitle.isNotEmpty) ? frTitle : 'Vidéo sans titre',
          'en': (enTitle != null && enTitle.isNotEmpty) ? enTitle : 'Untitled video',
        };
      }
    }

    // Ensure duree has a valid value and format
    final duree = sanitized['duree']?.toString().trim();
    if (duree == null || duree.isEmpty || duree == '0' || duree == '0.0') {
      sanitized['duree'] = '0:00';
    } else if (!duree.contains(':')) {
      // If it's a number without colon, assume it's seconds and format it
      try {
        final seconds = double.parse(duree).toInt();
        final minutes = seconds ~/ 60;
        final remainingSeconds = seconds % 60;
        sanitized['duree'] = '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
      } catch (e) {
        sanitized['duree'] = '0:00';
      }
    }

    return sanitized;
  }

  /// Sanitize review data to handle null values
  Map<String, dynamic> _sanitizeReviewData(Map<String, dynamic> review) {
    final sanitized = Map<String, dynamic>.from(review);

    // Ensure required fields have default values - note can be null, but if it's not null, it should be a valid number
    if (sanitized['note'] != null && sanitized['note'] is! int) {
      try {
        sanitized['note'] = int.parse(sanitized['note'].toString());
      } catch (e) {
        sanitized['note'] = null; // Set to null if can't parse, will use default in getter
      }
    }

    return sanitized;
  }

  /// Get featured courses (first page for now)
  Future<List<Course>> getFeaturedCourses({int limit = 6}) async {
    try {
      final coursesResponse = await getCourses(page: 1);
      return coursesResponse.data.take(limit).toList();
    } catch (e) {
      throw CourseException('Erreur lors du chargement des cours populaires: ${e.toString()}');
    }
  }

  /// Get categories from dedicated endpoint
  Future<List<CourseCategory>> getCategories() async {
    try {
      final response = await _apiService.get(ApiConfig.categoriesEndpoint);

      // Check if response has the 'data' field (from the API structure)
      if (response.data is Map<String, dynamic> && response.data['data'] != null) {
        final categoriesData = response.data['data'] as List<dynamic>;
        return categoriesData.map((categoryData) => CourseCategory.fromJson(categoryData)).toList();
      } else if (response.data is List<dynamic>) {
        // Fallback if response is directly a list
        return (response.data as List<dynamic>)
            .map((categoryData) => CourseCategory.fromJson(categoryData))
            .toList();
      }

      return [];
    } catch (e) {
      print('Error loading categories from API, falling back to course extraction: $e');
      // Fallback to original method if API fails
      try {
        final coursesResponse = await getCourses(page: 1);
        final categories = <CourseCategory>[];
        final seenIds = <int>{};

        for (final course in coursesResponse.data) {
          if (course.categorie != null && !seenIds.contains(course.categorie!.id)) {
            categories.add(course.categorie!);
            seenIds.add(course.categorie!.id);
          }
        }

        return categories;
      } catch (e) {
        throw CourseException('Erreur lors du chargement des catégories: ${e.toString()}');
      }
    }
  }
}

/// Custom exception for course-related errors
class CourseException implements Exception {
  final String message;

  CourseException(this.message);

  @override
  String toString() => message;
}