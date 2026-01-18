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
    print('🔵 [CourseService] getCoursesByCategory() - Category: $categorySlug, Page: $page');
    try {
      final response = await _apiService.get(
        '${ApiConfig.coursesByCategoryEndpoint}/$categorySlug',
        queryParameters: {'page': page},
      );

      print('📊 [CourseService] getCoursesByCategory() - Response data: ${response.data}');

      // Check if response.data is null or not a Map
      if (response.data == null) {
        print('⚠️ [CourseService] getCoursesByCategory() - Response data is null, returning empty response');
        return CoursesResponse(
          currentPage: 1,
          data: [],
          firstPageUrl: '',
          lastPage: 1,
          lastPageUrl: '',
          links: [],
          path: '',
          total: 0,
          perPage: 20,
        );
      }

      // Ensure response.data is a Map
      Map<String, dynamic> responseData;
      if (response.data is! Map<String, dynamic>) {
        print('⚠️ [CourseService] getCoursesByCategory() - Response is not a Map, trying to convert');
        responseData = {
          'data': [],
          'current_page': 1,
          'first_page_url': '',
          'last_page': 1,
          'last_page_url': '',
          'links': [],
          'path': '',
          'total': 0,
          'per_page': 20,
        };
      } else {
        responseData = response.data as Map<String, dynamic>;
      }

      // Sanitize the response data to handle null values
      final sanitizedData = _sanitizeCoursesResponse(responseData);

      print('✅ [CourseService] getCoursesByCategory() - Success, courses count: ${sanitizedData['data']?.length ?? 0}');
      return CoursesResponse.fromJson(sanitizedData);
    } catch (e) {
      print('❌ [CourseService] getCoursesByCategory() - Error: ${e.toString()}');
      print('🔧 [CourseService] getCoursesByCategory() - Error type: ${e.runtimeType}');
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
      print('📊 [CourseService] getCourseBySlug() - Raw response data type: ${response.data.runtimeType}');

      // Log the structure of the response to understand the data format
      if (response.data is Map<String, dynamic>) {
        final dataMap = response.data as Map<String, dynamic>;
        print('📊 [CourseService] getCourseBySlug() - Available keys in response: ${dataMap.keys.toList()}');

        // Check if chapitres exist in the response
        if (dataMap.containsKey('chapitres')) {
          final chapitres = dataMap['chapitres'];
          print('📊 [CourseService] getCourseBySlug() - Found chapitres field: ${chapitres.runtimeType}');
          if (chapitres is List) {
            print('📊 [CourseService] getCourseBySlug() - Number of chapters: ${chapitres.length}');
            if (chapitres.isNotEmpty) {
              print('📊 [CourseService] getCourseBySlug() - First chapter structure: ${chapitres[0].runtimeType}');
              if (chapitres[0] is Map<String, dynamic>) {
                final firstChapter = chapitres[0] as Map<String, dynamic>;
                print('📊 [CourseService] getCourseBySlug() - First chapter keys: ${firstChapter.keys.toList()}');

                // Check the structure of the first chapter
                if (firstChapter.containsKey('titre')) {
                  print('📊 [CourseService] getCourseBySlug() - First chapter titre: ${firstChapter['titre']}');
                  print('📊 [CourseService] getCourseBySlug() - First chapter titre type: ${firstChapter['titre'].runtimeType}');
                } else {
                  print('⚠️ [CourseService] getCourseBySlug() - No titre field in first chapter');
                }

                if (firstChapter.containsKey('videos')) {
                  final videos = firstChapter['videos'];
                  print('📊 [CourseService] getCourseBySlug() - First chapter videos: ${videos.runtimeType}');
                  if (videos is List) {
                    print('📊 [CourseService] getCourseBySlug() - First chapter videos count: ${videos.length}');
                  }
                } else {
                  print('⚠️ [CourseService] getCourseBySlug() - No videos field in first chapter');
                }
              }
            }
          }
        } else {
          print('⚠️ [CourseService] getCourseBySlug() - No chapitres field in response');
        }
      }

      print('📊 [CourseService] getCourseBySlug() - Course has ${response.data?['chapitres']?.length ?? 0} chapters initially');

      // Sanitize the response data to handle null values in arrays
      var sanitizedData = _sanitizeCourseData(response.data);

      // If no chapters are present in the response, try to load them separately
      if (sanitizedData['chapitres'] == null || (sanitizedData['chapitres'] as List).isEmpty) {
        print('⚠️ [CourseService] getCourseBySlug() - No chapters found in initial response, attempting to load separately');
        try {
          final courseId = sanitizedData['id'];
          if (courseId != null) {
            // Try different possible endpoints for chapters
            List<String> possibleEndpoints = [
              '/formation_chapitres/$courseId',
              '/formations/$courseId/chapitres',
              '/cours/$courseId/chapitres',
              '/formation/$courseId/chapitres',
              '/api/formations/$courseId/chapitres',
              '/api/cours/$courseId/chapitres'
            ];

            for (String endpoint in possibleEndpoints) {
              try {
                final chaptersResponse = await _apiService.get(endpoint);
                if (chaptersResponse.data is Map && chaptersResponse.data['chapitres'] != null) {
                  sanitizedData['chapitres'] = chaptersResponse.data['chapitres'];
                  print('✅ [CourseService] getCourseBySlug() - Loaded ${sanitizedData['chapitres']?.length ?? 0} chapters from $endpoint');
                  break; // Exit the loop once we find the correct endpoint
                } else if (chaptersResponse.data is List) {
                  sanitizedData['chapitres'] = chaptersResponse.data;
                  print('✅ [CourseService] getCourseBySlug() - Loaded ${sanitizedData['chapitres']?.length ?? 0} chapters from $endpoint (list response)');
                  break; // Exit the loop once we find the correct endpoint
                }
              } catch (e) {
                print('⚠️ [CourseService] getCourseBySlug() - Endpoint $endpoint failed: $e');
                continue; // Try the next endpoint
              }
            }
          }
        } catch (chapterError) {
          print('⚠️ [CourseService] getCourseBySlug() - Failed to load chapters separately: $chapterError');
          // Continue with the course even if chapters couldn't be loaded separately
        }
      }

      // Apply sanitization to handle chapters and other nested data
      sanitizedData = _sanitizeCourseData(sanitizedData);
      print('📊 [CourseService] getCourseBySlug() - Course has ${sanitizedData['chapitres']?.length ?? 0} chapters initially');

      // Load videos for each chapter if they don't exist
      if (sanitizedData['chapitres'] != null) {
        final chapters = sanitizedData['chapitres'] as List;
        print('🔄 [CourseService] getCourseBySlug() - Checking videos for ${chapters.length} chapters');

        for (int i = 0; i < chapters.length; i++) {
          final chapter = chapters[i] as Map<String, dynamic>;
          final chapterId = chapter['id'] as int?;

          if (chapterId != null) {
            // Check if videos are already present
            if (chapter['videos'] == null || (chapter['videos'] as List).isEmpty) {
              print('🔍 [CourseService] getCourseBySlug() - Loading videos for chapter $chapterId');
              final videos = await getVideosForChapter(chapterId);

              if (videos.isNotEmpty) {
                print('✅ [CourseService] getCourseBySlug() - Loaded ${videos.length} videos for chapter $chapterId');
                chapters[i] = {
                  ...chapter,
                  'videos': videos,
                };
              } else {
                print('⚠️ [CourseService] getCourseBySlug() - No videos found for chapter $chapterId');
                chapters[i] = {
                  ...chapter,
                  'videos': [],
                };
              }
            } else {
              print('📚 [CourseService] getCourseBySlug() - Chapter $chapterId already has ${(chapter['videos'] as List).length} videos');
            }
          }
        }

        sanitizedData['chapitres'] = chapters;
      }

      // Apply final sanitization after adding videos
      sanitizedData = _sanitizeCourseData(sanitizedData);
      print('📊 [CourseService] getCourseBySlug() - Final course has ${sanitizedData['chapitres']?.length ?? 0} chapters');

      // Log detailed information about chapters
      if (sanitizedData['chapitres'] != null && (sanitizedData['chapitres'] as List).isNotEmpty) {
        final chapters = sanitizedData['chapitres'] as List;
        print('📊 [CourseService] getCourseBySlug() - Chapter details:');
        for (int i = 0; i < chapters.length && i < 3; i++) { // Log first 3 chapters only
          final chapter = chapters[i] as Map<String, dynamic>;
          print('   Chapter ${i+1}:');
          print('     - titre: ${chapter['titre']}');
          print('     - duree: ${chapter['duree']}');
          print('     - videos count: ${(chapter['videos'] as List?)?.length ?? 0}');
          if (chapter['videos'] != null && (chapter['videos'] as List).isNotEmpty) {
            final videos = chapter['videos'] as List;
            for (int j = 0; j < videos.length && j < 2; j++) { // Log first 2 videos only
              final video = videos[j] as Map<String, dynamic>;
              print('       Video ${j+1}: ${video['titre']}');
            }
          }
        }
      }

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

    // Handle langue_formation - can be null or a Map
    if (sanitized['langue_formation'] != null && sanitized['langue_formation'] is! Map) {
      // If it's a string, convert to Map
      final langueStr = sanitized['langue_formation'].toString();
      sanitized['langue_formation'] = {'fr': langueStr, 'en': langueStr};
    } else if (sanitized['langue_formation'] == null) {
      sanitized['langue_formation'] = {'fr': 'français', 'en': 'french'};
    }

    // Handle categorie - can be null or non-Map
    if (sanitized['categorie'] != null) {
      if (sanitized['categorie'] is Map) {
        try {
          final categorieMap = Map<String, dynamic>.from(sanitized['categorie'] as Map);
          sanitized['categorie'] = _sanitizeCategoryData(categorieMap);
        } catch (e) {
          print('⚠️ [CourseService] Error sanitizing categorie: $e');
          sanitized['categorie'] = null;
        }
      } else {
        print('⚠️ [CourseService] categorie is not a Map (${sanitized['categorie'].runtimeType}), setting to null');
        sanitized['categorie'] = null;
      }
    } else {
      print('ℹ️ [CourseService] categorie is null, keeping as null');
    }

    // Handle type_formation - can be null or non-Map
    if (sanitized['type_formation'] != null) {
      if (sanitized['type_formation'] is Map) {
        try {
          final typeFormationMap = Map<String, dynamic>.from(sanitized['type_formation'] as Map);
          sanitized['type_formation'] = _sanitizeFormationTypeData(typeFormationMap);
        } catch (e) {
          print('⚠️ [CourseService] Error sanitizing type_formation: $e');
          sanitized['type_formation'] = null;
        }
      } else {
        print('⚠️ [CourseService] type_formation is not a Map (${sanitized['type_formation'].runtimeType}), setting to null');
        sanitized['type_formation'] = null;
      }
    } else {
      print('ℹ️ [CourseService] type_formation is null, keeping as null');
    }

    return sanitized;
  }

  /// Sanitize category data
  Map<String, dynamic> _sanitizeCategoryData(Map<String, dynamic> data) {
    final sanitized = Map<String, dynamic>.from(data);

    // Ensure intitule is properly formatted
    if (sanitized['intitule'] != null && sanitized['intitule'] is! Map) {
      final intituleStr = sanitized['intitule'].toString();
      sanitized['intitule'] = {'fr': intituleStr, 'en': intituleStr};
    } else if (sanitized['intitule'] == null) {
      sanitized['intitule'] = {'fr': 'Catégorie', 'en': 'Category'};
    }

    sanitized['slug'] ??= 'category-${sanitized['id'] ?? 'unknown'}';
    sanitized['type'] ??= 1;

    return sanitized;
  }

  /// Sanitize formation type data
  Map<String, dynamic> _sanitizeFormationTypeData(Map<String, dynamic> data) {
    final sanitized = Map<String, dynamic>.from(data);

    // Ensure intitule is properly formatted
    if (sanitized['intitule'] != null && sanitized['intitule'] is! Map) {
      final intituleStr = sanitized['intitule'].toString();
      sanitized['intitule'] = {'fr': intituleStr, 'en': intituleStr};
    } else if (sanitized['intitule'] == null) {
      sanitized['intitule'] = {'fr': 'Formation', 'en': 'Training'};
    }

    sanitized['slug'] ??= 'type-${sanitized['id'] ?? 'unknown'}';

    return sanitized;
  }

  /// Sanitize course data to handle null values and prevent casting errors
  Map<String, dynamic> _sanitizeCourseData(Map<String, dynamic> data) {
    // First apply the shallow sanitization to handle basic fields
    final sanitized = _sanitizeCourseDataShallow(data);

    // Then handle additional fields specific to detailed course view
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

    // Backend utilise 'intitule', pas besoin de mapping car le modèle utilise @JsonKey(name: 'intitule')
    // Mais on garde la sanitization pour les valeurs nulles ou vides
    if (sanitized['intitule'] == null) {
      // Si intitule est null, créer une valeur par défaut
      sanitized['intitule'] = {'fr': 'Chapitre sans titre', 'en': 'Untitled chapter'};
    } else if (sanitized['intitule'] is Map) {
      final intituleMap = sanitized['intitule'] as Map;
      final frTitle = intituleMap['fr']?.toString().trim();
      final enTitle = intituleMap['en']?.toString().trim();

      // Si les deux langues sont vides, utiliser les valeurs par défaut
      if ((frTitle == null || frTitle.isEmpty) && (enTitle == null || enTitle.isEmpty)) {
        sanitized['intitule'] = {'fr': 'Chapitre sans titre', 'en': 'Untitled chapter'};
      } else {
        // S'assurer qu'au moins une langue a un titre valide
        sanitized['intitule'] = {
          'fr': (frTitle != null && frTitle.isNotEmpty) ? frTitle : 'Chapitre sans titre',
          'en': (enTitle != null && enTitle.isNotEmpty) ? enTitle : 'Untitled chapter',
        };
      }
    } else if (sanitized['intitule'] is String) {
      // Si intitule est une string, la convertir en Map
      sanitized['intitule'] = {'fr': sanitized['intitule'], 'en': sanitized['intitule']};
    }

    // Handle videos array - check if videos exist in the chapter data
    // Videos might be stored separately in the backend, so we'll check for possible video-related fields
    if (sanitized['videos'] is List) {
      final videosRaw = sanitized['videos'] as List;
      final videos = <Map<String, dynamic>>[];

      for (final video in videosRaw) {
        if (video != null && video is Map<String, dynamic>) {
          videos.add(_sanitizeVideoData(video));
        }
      }

      sanitized['videos'] = videos;
    } else if (sanitized['videos'] == null) {
      // Check if videos might be stored under a different field name
      // Common alternative field names for videos in chapters
      List<String> possibleVideoFields = ['video', 'videos_list', 'contenu', 'lessons', 'lecons', 'fichiers'];

      for (String field in possibleVideoFields) {
        if (sanitized[field] is List) {
          final videosRaw = sanitized[field] as List;
          final videos = <Map<String, dynamic>>[];

          for (final item in videosRaw) {
            if (item != null && item is Map<String, dynamic>) {
              // If the item is not already in video format, we might need to convert it
              videos.add(_sanitizeVideoData(item));
            }
          }

          sanitized['videos'] = videos;
          break; // Found videos in an alternative field
        }
      }

      // If no videos were found in alternative fields, initialize as empty list
      if (sanitized['videos'] == null) {
        sanitized['videos'] = [];
      }
    }

    return sanitized;
  }

  /// Sanitize video data to handle null values
  Map<String, dynamic> _sanitizeVideoData(Map<String, dynamic> video) {
    final sanitized = Map<String, dynamic>.from(video);

    // Backend utilise 'intitule' pour les vidéos aussi, comme pour les chapitres
    if (sanitized['intitule'] == null) {
      sanitized['intitule'] = {'fr': 'Vidéo sans titre', 'en': 'Untitled video'};
    } else if (sanitized['intitule'] is Map) {
      final intituleMap = sanitized['intitule'] as Map;
      final frTitle = intituleMap['fr']?.toString().trim();
      final enTitle = intituleMap['en']?.toString().trim();

      // Si les deux langues sont vides, utiliser les valeurs par défaut
      if ((frTitle == null || frTitle.isEmpty) && (enTitle == null || enTitle.isEmpty)) {
        sanitized['intitule'] = {'fr': 'Vidéo sans titre', 'en': 'Untitled video'};
      } else {
        // S'assurer qu'au moins une langue a un titre valide
        sanitized['intitule'] = {
          'fr': (frTitle != null && frTitle.isNotEmpty) ? frTitle : 'Vidéo sans titre',
          'en': (enTitle != null && enTitle.isNotEmpty) ? enTitle : 'Untitled video',
        };
      }
    } else if (sanitized['intitule'] is String) {
      // Si intitule est une string, la convertir en Map
      sanitized['intitule'] = {'fr': sanitized['intitule'], 'en': sanitized['intitule']};
    }

    // Backend utilise 'lien' au lieu de 'url'
    if (sanitized['lien'] != null && sanitized['url'] == null) {
      sanitized['url'] = sanitized['lien'];
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

  /// Charger les vidéos pour un chapitre spécifique
  Future<List<dynamic>> getVideosForChapter(int chapterId) async {
    try {
      // Use the correct endpoint that we just created in the backend
      final endpoint = '/chapitres/$chapterId/videos';

      print('🔍 [CourseService] getVideosForChapter() - Loading ALL videos (mobile) from $endpoint');

      // Mobile app: Request ALL videos (not just free ones like web)
      final response = await _apiService.get(
        endpoint,
        queryParameters: {
          'platform': 'mobile',  // Backend should return all videos for mobile
          'all': 'true',         // Request all videos including paid ones
        },
      );

      // Check if response is HTML (error page) - if so, return empty list
      if (response.data is String) {
        print('⚠️ [CourseService] getVideosForChapter() - Received HTML response from $endpoint, returning empty list');
        return [];
      }

      // Handle the response format from our new endpoint
      if (response.data is Map) {
        // Our endpoint returns: { "chapitre_id": X, "chapitre_title": "...", "videos": [...] }
        if (response.data['videos'] != null && response.data['videos'] is List) {
          final videos = response.data['videos'] as List;
          print('✅ [CourseService] getVideosForChapter() - Found ${videos.length} videos for chapter $chapterId');
          return videos;
        }
      }

      // If we get here, no videos were found
      print('⚠️ [CourseService] getVideosForChapter() - No videos found for chapter $chapterId');
      return [];
    } catch (e) {
      print('❌ [CourseService] getVideosForChapter() - Error loading videos for chapter $chapterId: $e');
      return [];
    }
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
    print('🔵 [CourseService] getCategories() - Starting...');
    try {
      // Try to get all categories at once
      final response = await _apiService.get(ApiConfig.categoriesEndpoint);
      print('✅ [CourseService] getCategories() - Response received');

      // The videotheque endpoint returns: { "categories": {...pagination}, "all_categories": [...] }
      // We want to use "all_categories" for the full list
      if (response.data is Map<String, dynamic>) {
        if (response.data['all_categories'] != null) {
          print('📊 [CourseService] getCategories() - Found all_categories field');
          final categoriesData = response.data['all_categories'] as List<dynamic>;
          print('📊 [CourseService] getCategories() - Categories count: ${categoriesData.length}');
          return categoriesData.map((categoryData) => CourseCategory.fromJson(categoryData as Map<String, dynamic>)).toList();
        } else if (response.data['data'] != null) {
          // Check if this is a paginated response
          print('📊 [CourseService] getCategories() - Found data field');

          // If it's a paginated response, we need to get all pages
          final categoriesData = response.data['data'] as List<dynamic>;
          print('📊 [CourseService] getCategories() - Initial categories count: ${categoriesData.length}');

          // Check if there are more pages
          int currentPage = response.data['current_page'] ?? 1;
          int lastPage = response.data['last_page'] ?? 1;

          print('📊 [CourseService] getCategories() - Current page: $currentPage, Last page: $lastPage');

          // Collect all categories from all pages
          List<CourseCategory> allCategories = categoriesData
              .map((categoryData) => CourseCategory.fromJson(categoryData as Map<String, dynamic>))
              .toList();

          // If there are more pages, fetch them
          while (currentPage < lastPage) {
            currentPage++;
            print('📊 [CourseService] getCategories() - Fetching page $currentPage of $lastPage');

            final nextPageResponse = await _apiService.get(
              ApiConfig.categoriesEndpoint,
              queryParameters: {'page': currentPage},
            );

            if (nextPageResponse.data is Map<String, dynamic> &&
                nextPageResponse.data['data'] != null) {
              final nextPageData = nextPageResponse.data['data'] as List<dynamic>;
              final nextPageCategories = nextPageData
                  .map((categoryData) => CourseCategory.fromJson(categoryData as Map<String, dynamic>))
                  .toList();

              allCategories.addAll(nextPageCategories);
              print('📊 [CourseService] getCategories() - Added ${nextPageData.length} categories from page $currentPage');
            } else {
              print('⚠️ [CourseService] getCategories() - Unexpected response format for page $currentPage');
              break;
            }
          }

          print('📊 [CourseService] getCategories() - Total categories collected: ${allCategories.length}');

          // Trier les catégories par ordre alphabétique
          allCategories.sort((a, b) => a.name.compareTo(b.name));

          return allCategories;
        }
      } else if (response.data is List<dynamic>) {
        // Fallback if response is directly a list
        print('📊 [CourseService] getCategories() - Direct list response');
        return (response.data as List<dynamic>)
            .map((categoryData) => CourseCategory.fromJson(categoryData as Map<String, dynamic>))
            .toList();
      }

      print('⚠️ [CourseService] getCategories() - No valid data found in response');
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