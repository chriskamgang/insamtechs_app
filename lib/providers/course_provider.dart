import 'package:flutter/foundation.dart';
import '../models/course.dart';
import '../data/mock_data.dart';
import '../utils/logging_mixin.dart';

enum CourseLoadingState { loading, loaded, error }

class CourseProvider extends ChangeNotifier with LoggingMixin {
  CourseLoadingState _state = CourseLoadingState.loading;
  List<Course> _courses = [];
  List<Course> _featuredCourses = [];
  List<CourseCategory> _categories = [];
  String? _errorMessage;
  int _currentPage = 1;
  bool _hasMorePages = true;

  // Getters
  CourseLoadingState get state => _state;
  List<Course> get courses => _courses;
  List<Course> get featuredCourses => _featuredCourses;
  List<CourseCategory> get categories => _categories;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _state == CourseLoadingState.loading;
  bool get hasError => _state == CourseLoadingState.error;
  bool get hasMorePages => _hasMorePages;

  /// Initialize and load initial data
  Future<void> initialize() async {
    logProviderInfo('Starting CourseProvider initialization');
    logProviderStateChange('idle', 'loading');
    _setState(CourseLoadingState.loading);
    _clearError();

    try {
      logProviderInfo('Loading initial data (featured courses, categories, courses)');

      // Simulate loading delay for realistic UX
      await Future.delayed(const Duration(milliseconds: 500));

      // Load featured courses and categories from mock data
      _featuredCourses = MockData.getFeaturedCourses();
      _categories = MockData.getMockCategories();
      _courses = MockData.getMockCourses();

      // Mock pagination
      _hasMorePages = false;
      _currentPage = 1;

      logProviderStateChange('loading', 'loaded');
      logProviderSuccess('CourseProvider initialization completed', data: {
        'coursesCount': _courses.length,
        'featuredCoursesCount': _featuredCourses.length,
        'categoriesCount': _categories.length,
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

      // Simulate loading delay
      await Future.delayed(const Duration(milliseconds: 300));

      if (refresh) {
        _courses = MockData.getMockCourses();
      }

      _hasMorePages = false;
      notifyListeners();
    } catch (e) {
      throw Exception('Erreur lors du chargement des cours: ${e.toString()}');
    }
  }

  /// Load more courses (pagination)
  Future<void> loadMoreCourses() async {
    if (!_hasMorePages || _state == CourseLoadingState.loading) return;

    try {
      await loadCourses(refresh: false);
    } catch (e) {
      _setError(e.toString());
    }
  }

  /// Load featured courses for home screen
  Future<void> loadFeaturedCourses() async {
    try {
      await Future.delayed(const Duration(milliseconds: 300));
      _featuredCourses = MockData.getFeaturedCourses();
      notifyListeners();
    } catch (e) {
      throw Exception('Erreur lors du chargement des cours populaires: ${e.toString()}');
    }
  }

  /// Load course categories
  Future<void> loadCategories() async {
    try {
      await Future.delayed(const Duration(milliseconds: 300));
      _categories = MockData.getMockCategories();
      notifyListeners();
    } catch (e) {
      throw Exception('Erreur lors du chargement des catégories: ${e.toString()}');
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
      await Future.delayed(const Duration(milliseconds: 300));
      final searchResults = MockData.searchCourses(query);
      _courses = searchResults;
      _hasMorePages = false;
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
      await Future.delayed(const Duration(milliseconds: 300));
      final filteredCourses = MockData.getCoursesByCategory(categorySlug);
      _courses = filteredCourses;
      _hasMorePages = false;
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
      await Future.delayed(const Duration(milliseconds: 300));
      final course = MockData.getCourseBySlug(slug);
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