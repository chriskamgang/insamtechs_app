import 'package:flutter/foundation.dart';
import '../models/library_item.dart';
import '../models/library_category.dart';
import '../models/fascicule_filiere.dart';
import '../models/fascicule_serie.dart';
import '../services/library_service.dart';

enum LibraryLoadingState { idle, loading, loaded, error }

class LibraryProvider with ChangeNotifier {
  final LibraryService _libraryService = LibraryService();

  List<LibraryItem> _libraryItems = [];
  List<LibraryCategory> _libraryCategories = [];
  List<FasciculeFiliere> _filieres = [];
  List<FasciculeSerie> _series = [];
  LibraryLoadingState _state = LibraryLoadingState.idle;
  String? _errorMessage;

  List<LibraryItem> get libraryItems => _libraryItems;
  List<LibraryCategory> get libraryCategories => _libraryCategories;
  List<FasciculeFiliere> get filieres => _filieres;
  List<FasciculeSerie> get series => _series;
  LibraryLoadingState get state => _state;
  String? get errorMessage => _errorMessage;

  Future<void> loadLibraryItems({
    String? category,
    String? searchQuery,
    String? type,
    bool refresh = false,
  }) async {
    if (_state == LibraryLoadingState.loading && !refresh) return;

    _state = LibraryLoadingState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      _libraryItems = await _libraryService.fetchLibraryItems(
        category: category,
        searchQuery: searchQuery,
        type: type,
      );
      _state = LibraryLoadingState.loaded;
    } catch (e) {
      _state = LibraryLoadingState.error;
      _errorMessage = e.toString();
    }

    notifyListeners();
  }

  Future<void> loadLibraryItemById(String id) async {
    _state = LibraryLoadingState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final item = await _libraryService.fetchLibraryItemById(id);
      _libraryItems = [item]; // Update with single item
      _state = LibraryLoadingState.loaded;
    } catch (e) {
      _state = LibraryLoadingState.error;
      _errorMessage = e.toString();
    }

    notifyListeners();
  }

  Future<void> searchLibraryItems(String query) async {
    _state = LibraryLoadingState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      _libraryItems = await _libraryService.searchLibraryItems(query);
      _state = LibraryLoadingState.loaded;
    } catch (e) {
      _state = LibraryLoadingState.error;
      _errorMessage = e.toString();
    }

    notifyListeners();
  }

  Future<void> loadLibraryCategories() async {
    if (_state == LibraryLoadingState.loading) return;

    _state = LibraryLoadingState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      _libraryCategories = await _libraryService.fetchLibraryCategories();
      _state = LibraryLoadingState.loaded;
    } catch (e) {
      _state = LibraryLoadingState.error;
      _errorMessage = e.toString();
    }

    notifyListeners();
  }

  Future<void> loadFilieres() async {
    if (_state == LibraryLoadingState.loading) return;

    _state = LibraryLoadingState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      _filieres = await _libraryService.fetchFasciculeFilieres();
      _state = LibraryLoadingState.loaded;
    } catch (e) {
      _state = LibraryLoadingState.error;
      _errorMessage = e.toString();
    }

    notifyListeners();
  }

  Future<void> loadLibraryItemsByCategory(String categorySlug) async {
    if (_state == LibraryLoadingState.loading) return;

    _state = LibraryLoadingState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      _libraryItems = await _libraryService.fetchLibraryItemsByCategory(categorySlug);
      _state = LibraryLoadingState.loaded;
    } catch (e) {
      _state = LibraryLoadingState.error;
      _errorMessage = e.toString();
    }

    notifyListeners();
  }

  Future<void> loadSeriesByFiliere(String filiereSlug) async {
    if (_state == LibraryLoadingState.loading) return;

    _state = LibraryLoadingState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      _series = await _libraryService.fetchSeriesByFiliere(filiereSlug);
      _state = LibraryLoadingState.loaded;
    } catch (e) {
      _state = LibraryLoadingState.error;
      _errorMessage = e.toString();
    }

    notifyListeners();
  }

  Future<void> loadCategoriesBySerie(String serieSlug) async {
    if (_state == LibraryLoadingState.loading) return;

    _state = LibraryLoadingState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      _libraryCategories = await _libraryService.fetchCategoriesBySerie(serieSlug);
      _state = LibraryLoadingState.loaded;
    } catch (e) {
      _state = LibraryLoadingState.error;
      _errorMessage = e.toString();
    }

    notifyListeners();
  }

  Future<void> loadFasciculesByCategory(String categorySlug) async {
    if (_state == LibraryLoadingState.loading) return;

    _state = LibraryLoadingState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      _libraryItems = await _libraryService.fetchFasciculesByCategory(categorySlug);
      _state = LibraryLoadingState.loaded;
    } catch (e) {
      _state = LibraryLoadingState.error;
      _errorMessage = e.toString();
    }

    notifyListeners();
  }

  Future<bool> downloadDocument(String documentId) async {
    try {
      bool success = await _libraryService.downloadDocument(documentId);
      if (success) {
        // Update download count locally
        final docIdInt = int.tryParse(documentId);
        if (docIdInt != null) {
          final index = _libraryItems.indexWhere((item) => item.id == docIdInt);
          if (index != -1) {
            _libraryItems[index] = _libraryItems[index].copyWith(
              nbTelechargements: (_libraryItems[index].nbTelechargements ?? 0) + 1
            );
            notifyListeners();
          }
        }
      }
      return success;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> markAsViewed(String documentId) async {
    try {
      bool success = await _libraryService.markAsViewed(documentId);
      if (success) {
        // Update view count locally
        final docIdInt = int.tryParse(documentId);
        if (docIdInt != null) {
          final index = _libraryItems.indexWhere((item) => item.id == docIdInt);
          if (index != -1) {
            _libraryItems[index] = _libraryItems[index].copyWith(
              nbVues: (_libraryItems[index].nbVues ?? 0) + 1
            );
            notifyListeners();
          }
        }
      }
      return success;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  void resetState() {
    _state = LibraryLoadingState.idle;
    _errorMessage = null;
    notifyListeners();
  }

  // Method to get a specific library item by ID
  LibraryItem? getItemById(int id) {
    try {
      return _libraryItems.firstWhere((item) => item.id == id);
    } catch (e) {
      return null;
    }
  }

  // Load fascicule categories (type = 3)
  Future<void> loadFasciculeCategories({bool refresh = false}) async {
    if (_state == LibraryLoadingState.loading && !refresh) return;

    _state = LibraryLoadingState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      _libraryCategories = await _libraryService.fetchFasciculeCategories();
      _state = LibraryLoadingState.loaded;
    } catch (e) {
      _state = LibraryLoadingState.error;
      _errorMessage = e.toString();
    }

    notifyListeners();
  }
}