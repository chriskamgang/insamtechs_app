import 'package:flutter/foundation.dart';
import '../services/library_service.dart';

class LibraryProvider with ChangeNotifier {
  final LibraryService _libraryService = LibraryService();

  // État de la bibliothèque
  Map<String, dynamic>? _libraryContent;
  bool _isLoadingLibrary = false;
  String? _libraryError;

  // État des livres
  List<dynamic> _books = [];
  bool _isLoadingBooks = false;
  String? _booksError;
  String? _currentBookCategory;

  // État des filières
  List<dynamic> _studyFields = [];
  bool _isLoadingStudyFields = false;
  String? _studyFieldsError;

  // État des fascicules
  List<dynamic> _fascicules = [];
  bool _isLoadingFascicules = false;
  String? _fasciculesError;
  String? _currentFasciculeCategory;

  // Getters pour la bibliothèque
  Map<String, dynamic>? get libraryContent => _libraryContent;
  bool get isLoadingLibrary => _isLoadingLibrary;
  String? get libraryError => _libraryError;
  bool get hasLibraryError => _libraryError != null;

  // Getters pour les livres
  List<dynamic> get books => List.unmodifiable(_books);
  bool get isLoadingBooks => _isLoadingBooks;
  String? get booksError => _booksError;
  bool get hasBooksError => _booksError != null;
  String? get currentBookCategory => _currentBookCategory;

  // Getters pour les filières
  List<dynamic> get studyFields => List.unmodifiable(_studyFields);
  bool get isLoadingStudyFields => _isLoadingStudyFields;
  String? get studyFieldsError => _studyFieldsError;
  bool get hasStudyFieldsError => _studyFieldsError != null;

  // Getters pour les fascicules
  List<dynamic> get fascicules => List.unmodifiable(_fascicules);
  bool get isLoadingFascicules => _isLoadingFascicules;
  String? get fasciculesError => _fasciculesError;
  bool get hasFasciculesError => _fasciculesError != null;
  String? get currentFasciculeCategory => _currentFasciculeCategory;

  /// Charger le contenu de la bibliothèque
  Future<void> loadLibraryContent() async {
    _setLoadingLibrary(true);
    _clearLibraryError();

    try {
      _libraryContent = await _libraryService.getLibraryContent();
      notifyListeners();
    } catch (e) {
      _setLibraryError('Erreur lors du chargement de la bibliothèque: ${e.toString()}');
    } finally {
      _setLoadingLibrary(false);
    }
  }

  /// Charger les livres par catégorie
  Future<void> loadBooksByCategory(String categorySlug) async {
    _setLoadingBooks(true);
    _clearBooksError();

    try {
      _books = await _libraryService.getBooksByCategory(categorySlug);
      _currentBookCategory = categorySlug;
      notifyListeners();
    } catch (e) {
      _setBooksError('Erreur lors du chargement des livres: ${e.toString()}');
    } finally {
      _setLoadingBooks(false);
    }
  }

  /// Charger les filières d'étude
  Future<void> loadStudyFields() async {
    _setLoadingStudyFields(true);
    _clearStudyFieldsError();

    try {
      _studyFields = await _libraryService.getStudyFields();
      notifyListeners();
    } catch (e) {
      _setStudyFieldsError('Erreur lors du chargement des filières: ${e.toString()}');
    } finally {
      _setLoadingStudyFields(false);
    }
  }

  /// Charger les fascicules par catégorie
  Future<void> loadFasciculesByCategory(String categorySlug) async {
    _setLoadingFascicules(true);
    _clearFasciculesError();

    try {
      _fascicules = await _libraryService.getFasciculesByCategory(categorySlug);
      _currentFasciculeCategory = categorySlug;
      notifyListeners();
    } catch (e) {
      _setFasciculesError('Erreur lors du chargement des fascicules: ${e.toString()}');
    } finally {
      _setLoadingFascicules(false);
    }
  }

  /// Actualiser toutes les données de la bibliothèque
  Future<void> refreshLibrary() async {
    await Future.wait([
      loadLibraryContent(),
      loadStudyFields(),
    ]);
  }

  /// Vider toutes les données (lors de la déconnexion)
  void clearAllData() {
    _libraryContent = null;
    _books.clear();
    _studyFields.clear();
    _fascicules.clear();
    _currentBookCategory = null;
    _currentFasciculeCategory = null;

    _clearLibraryError();
    _clearBooksError();
    _clearStudyFieldsError();
    _clearFasciculesError();

    notifyListeners();
  }

  /// Rechercher dans les livres
  List<dynamic> searchBooks(String query) {
    if (query.trim().isEmpty) return _books;

    return _books.where((book) {
      final title = book['titre']?.toString().toLowerCase() ?? '';
      final author = book['auteur']?.toString().toLowerCase() ?? '';
      final description = book['description']?.toString().toLowerCase() ?? '';
      final searchQuery = query.toLowerCase();

      return title.contains(searchQuery) ||
             author.contains(searchQuery) ||
             description.contains(searchQuery);
    }).toList();
  }

  /// Rechercher dans les fascicules
  List<dynamic> searchFascicules(String query) {
    if (query.trim().isEmpty) return _fascicules;

    return _fascicules.where((fascicule) {
      final title = fascicule['titre']?.toString().toLowerCase() ?? '';
      final description = fascicule['description']?.toString().toLowerCase() ?? '';
      final searchQuery = query.toLowerCase();

      return title.contains(searchQuery) ||
             description.contains(searchQuery);
    }).toList();
  }

  // Méthodes privées pour la gestion d'état

  void _setLoadingLibrary(bool loading) {
    _isLoadingLibrary = loading;
    notifyListeners();
  }

  void _setLibraryError(String error) {
    _libraryError = error;
    notifyListeners();
  }

  void _clearLibraryError() {
    _libraryError = null;
  }

  void _setLoadingBooks(bool loading) {
    _isLoadingBooks = loading;
    notifyListeners();
  }

  void _setBooksError(String error) {
    _booksError = error;
    notifyListeners();
  }

  void _clearBooksError() {
    _booksError = null;
  }

  void _setLoadingStudyFields(bool loading) {
    _isLoadingStudyFields = loading;
    notifyListeners();
  }

  void _setStudyFieldsError(String error) {
    _studyFieldsError = error;
    notifyListeners();
  }

  void _clearStudyFieldsError() {
    _studyFieldsError = null;
  }

  void _setLoadingFascicules(bool loading) {
    _isLoadingFascicules = loading;
    notifyListeners();
  }

  void _setFasciculesError(String error) {
    _fasciculesError = error;
    notifyListeners();
  }

  void _clearFasciculesError() {
    _fasciculesError = null;
  }
}