import 'package:flutter/foundation.dart';
import '../models/course.dart';
import '../services/course_service.dart';
import '../utils/logging_mixin.dart';

enum CourseLoadingState { loading, loaded, error }

class CourseProvider extends ChangeNotifier with LoggingMixin {
  final CourseService _courseService = CourseService();

  CourseLoadingState _state = CourseLoadingState.loading;
  List<Course> _courses = [];
  List<Course> _featuredCourses = [];
  List<CourseCategory> _categories = [];
  String? _errorMessage;
  int _currentPage = 1;
  bool _hasMorePages = true;
  int _totalCourses = 0;

  // Getters
  CourseLoadingState get state => _state;
  List<Course> get courses => _courses;
  List<Course> get featuredCourses => _featuredCourses;
  List<CourseCategory> get categories => _categories;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _state == CourseLoadingState.loading;
  bool get hasError => _state == CourseLoadingState.error;
  bool get hasMorePages => _hasMorePages;
  int get totalCourses => _totalCourses;

  /// Initialize and load initial data
  Future<void> initialize() async {
    logProviderInfo('Starting CourseProvider initialization');
    logProviderStateChange('idle', 'loading');
    _setState(CourseLoadingState.loading);
    _clearError();

    try {
      logProviderInfo('Loading initial data (featured courses, categories, courses)');

      // Load featured courses (limit 6 for home screen)
      final featuredResponse = await _courseService.getFeaturedCourses(limit: 6);
      _featuredCourses = featuredResponse;

      // Load categories
      final categoriesResponse = await _courseService.getCategories();
      _categories = categoriesResponse;

      // Load initial page of courses
      final coursesResponse = await _courseService.getCourses(page: 1);
      _courses = coursesResponse.data;
      _currentPage = coursesResponse.currentPage;
      _hasMorePages = coursesResponse.currentPage < coursesResponse.lastPage;
      _totalCourses = coursesResponse.total;

      logProviderStateChange('loading', 'loaded');
      logProviderSuccess('CourseProvider initialization completed', data: {
        'coursesCount': _courses.length,
        'featuredCoursesCount': _featuredCourses.length,
        'categoriesCount': _categories.length,
        'totalCourses': _totalCourses,
      });
      _setState(CourseLoadingState.loaded);
    } catch (e) {
      final errorMsg = 'Erreur lors du chargement des données: ${e.toString()}';
      logProviderError('initialize', e, data: {'errorMessage': errorMsg});
      logProviderStateChange('loading', 'error');
      _setError(errorMsg);
      _setState(CourseLoadingState.error);
    }
  }

  /// Load all courses with pagination
  Future<void> loadCourses({bool refresh = false}) async {
    try {
      if (refresh) {
        _currentPage = 1;
        _courses.clear();
      }

      final coursesResponse = await _courseService.getCourses(page: _currentPage);

      if (refresh) {
        _courses = coursesResponse.data;
      } else {
        _courses.addAll(coursesResponse.data);
      }

      _currentPage = coursesResponse.currentPage;
      _hasMorePages = coursesResponse.currentPage < coursesResponse.lastPage;
      _totalCourses = coursesResponse.total;

      notifyListeners();
    } catch (e) {
      throw Exception('Erreur lors du chargement des cours: ${e.toString()}');
    }
  }

  /// Load more courses (pagination)
  Future<void> loadMoreCourses() async {
    if (!_hasMorePages || _state == CourseLoadingState.loading) return;

    try {
      _currentPage++;
      await loadCourses(refresh: false);
    } catch (e) {
      _currentPage--; // Revert page increment on error
      _setError(e.toString());
    }
  }

  /// Load featured courses for home screen
  Future<void> loadFeaturedCourses() async {
    try {
      final featuredCourses = await _courseService.getFeaturedCourses(limit: 6);
      _featuredCourses = featuredCourses;
      notifyListeners();
    } catch (e) {
      throw Exception('Erreur lors du chargement des cours populaires: ${e.toString()}');
    }
  }


  /// Search courses
  Future<void> searchCourses(String query) async {
    if (query.trim().isEmpty) {
      await loadCourses(refresh: true);
      return;
    }

    _setState(CourseLoadingState.loading);
    _clearError();

    try {
      final searchResults = await _courseService.searchCourses(query);
      _courses = searchResults;
      _hasMorePages = false; // Search results don't have pagination
      _setState(CourseLoadingState.loaded);
    } catch (e) {
      _setError('Erreur lors de la recherche: ${e.toString()}');
      _setState(CourseLoadingState.error);
    }
  }

  /// Filter courses by category
  Future<void> filterByCategory(String categorySlug) async {
    _setState(CourseLoadingState.loading);
    _clearError();

    try {
      final coursesResponse = await _courseService.getCoursesByCategory(categorySlug);
      _courses = coursesResponse.data;
      _currentPage = coursesResponse.currentPage;
      _hasMorePages = coursesResponse.currentPage < coursesResponse.lastPage;
      _totalCourses = coursesResponse.total;
      _setState(CourseLoadingState.loaded);
    } catch (e) {
      _setError('Erreur lors du filtrage par catégorie: ${e.toString()}');
      _setState(CourseLoadingState.error);
    }
  }

  /// Get course by slug
  Future<Course?> getCourseBySlug(String slug) async {
    logProviderInfo('Getting course by slug', data: {'slug': slug});
    try {
      final course = await _courseService.getCourseBySlug(slug);
      if (course != null) {
        logProviderSuccess('Course retrieved successfully', data: {
          'slug': slug,
          'courseId': course.id,
          'courseTitle': course.title,
          'chaptersCount': course.chapters.length,
        });
      }
      return course;
    } catch (e) {
      final errorMsg = 'Erreur lors du chargement du cours: ${e.toString()}';
      logProviderError('getCourseBySlug', e, data: {
        'slug': slug,
        'errorType': e.runtimeType.toString(),
      });
      _setError(errorMsg);
      return null;
    }
  }

  /// Refresh all data
  Future<void> refresh() async {
    await initialize();
  }

  /// Load categories
  Future<void> loadCategories() async {
    _setState(CourseLoadingState.loading);
    _clearError();

    try {
      final categories = await _courseService.getCategories();
      _categories = categories;
      _setState(CourseLoadingState.loaded);
    } catch (e) {
      _setError('Erreur lors du chargement des catégories: ${e.toString()}');
      _setState(CourseLoadingState.error);
    }
  }

  /// Clear error message
  void clearError() {
    _clearError();
  }

  // Private methods
  void _setState(CourseLoadingState state) {
    _state = state;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
