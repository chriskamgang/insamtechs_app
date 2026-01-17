import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/environment.dart';
import '../models/library_item.dart';
import '../models/library_category.dart';
import '../models/fascicule_filiere.dart';
import '../models/fascicule_serie.dart';
import '../utils/network_utils.dart';

class LibraryService {
  final NetworkUtils _networkUtils = NetworkUtils();

  // Helper method to extract string from multilingual field or simple string
  String _extractString(dynamic value, {String defaultValue = ''}) {
    if (value == null) return defaultValue;
    if (value is String) return value;
    if (value is Map) {
      // Try to get French version first, then English, then any available
      return value['fr']?.toString() ?? value['en']?.toString() ?? value.values.first?.toString() ?? defaultValue;
    }
    return value.toString();
  }

  Future<List<LibraryItem>> fetchLibraryItems({
    String? category,
    String? searchQuery,
    String? type,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      String url;

      // If category is specified, use the books by category endpoint
      if (category != null && category.isNotEmpty && category != 'Toutes') {
        url = '${EnvironmentConfig.apiBaseUrl}/livres_by_category/$category';
      } else {
        // Otherwise, use the main bibliotheque endpoint
        url = '${EnvironmentConfig.apiBaseUrl}/bibliotheque';
      }

      final response = await _networkUtils.makeRequest(
        Uri.parse(url),
        method: 'GET',
      );

      // Check if the response is HTML (indicating an error page)
      final responseBody = response.body;
      if (responseBody.startsWith('<!DOCTYPE html') ||
          responseBody.startsWith('<html') ||
          responseBody.contains('<head') ||
          responseBody.contains('<body')) {
        throw Exception('Server returned an error page instead of JSON data. Please check if the backend server is running and accessible.');
      }

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(responseBody);
        final List<dynamic> data;

        // The API might return data in different formats
        if (responseData.containsKey('data')) {
          data = responseData['data'];
        } else if (responseData.containsKey('livres')) {
          // If it's specifically books data
          data = responseData['livres'];
        } else {
          // Fallback: use the whole response if it's a list
          data = responseData.values.firstWhere((element) => element is List, orElse: () => []) as List<dynamic>;
        }

        // Convert API data to LibraryItem objects
        return data.map((json) {
          // Extract title and type safely
          String titre = _extractString(json['titre'] ?? json['intitule'] ?? json['nom'] ?? json['title'], defaultValue: 'Document sans titre');
          String typeStr = _extractString(json['type'], defaultValue: '');

          // Determine if this is a book or fascicule based on the API response
          String docType = 'Livre'; // Default type
          if (typeStr.toLowerCase().contains('fascicule') ||
              titre.toLowerCase().contains('fascicule') ||
              titre.toLowerCase().contains('exercice') ||
              titre.toLowerCase().contains('corrigé') ||
              titre.toLowerCase().contains('epreuve') ||
              titre.toLowerCase().contains('concours')) {
            docType = 'Fascicule';
          }

          return LibraryItem(
            id: json['id'] ?? json['ID'] ?? 0,
            titre: titre,
            description: _extractString(json['description'] ?? json['descriptif'] ?? json['desc'], defaultValue: ''),
            type: docType,
            auteur: _extractString(json['auteur'] ?? json['enseignant'] ?? json['instructeur'] ?? json['author'], defaultValue: 'Auteur inconnu'),
            lien: _extractString(json['lien'] ?? json['pdf_url'] ?? json['fichier'] ?? json['url'] ?? json['link'], defaultValue: ''),
            image: _extractString(json['image'] ?? json['img'] ?? json['icone'] ?? json['photo'] ?? json['thumbnail'], defaultValue: ''),
            categorie: _extractString(json['categorie'] ?? json['category'] ?? json['domaine'] ?? json['category_name'], defaultValue: 'Non catégorisé'),
            annee: json['annee'] ?? json['year'] ?? json['annee_publication'] ?? DateTime.now().year,
            slug: _extractString(json['slug'] ?? json['identifiant'] ?? json['code'], defaultValue: ''),
            langue: _extractString(json['langue'] ?? json['langue_formation'] ?? json['language'], defaultValue: 'Français'),
            niveau: _extractString(json['niveau'] ?? json['level'], defaultValue: 'Tous niveaux'),
            taille: json['taille'] ?? json['size'] ?? json['file_size'] ?? 0,
            format: _extractString(json['format'] ?? json['extension'], defaultValue: 'PDF'),
            motsCles: _extractString(json['motsCles'] ?? json['keywords'] ?? json['tags'], defaultValue: ''),
            estPayant: json['estPayant'] ?? json['isPaid'] ?? json['payant'] ?? json['is_paid'] ?? false,
            prix: _extractString(json['prix'] ?? json['price'] ?? json['montant'], defaultValue: '0'),
            datePublication: _extractString(json['datePublication'] ?? json['date_publication'] ?? json['published_at'] ?? json['date_pub'], defaultValue: DateTime.now().toString()),
            nbPages: json['nbPages'] ?? json['nb_pages'] ?? json['pages'] ?? json['page_count'] ?? json['nombre_pages'] ?? 0,
            editeur: _extractString(json['editeur'] ?? json['publisher'] ?? json['editeur_name'], defaultValue: ''),
            isbn: _extractString(json['isbn'] ?? json['ISBN'], defaultValue: ''),
            resume: _extractString(json['resume'] ?? json['summary'] ?? json['abstract'] ?? json['excerpt'], defaultValue: ''),
            nbTelechargements: json['nbTelechargements'] ?? json['nb_telechargements'] ?? json['downloads'] ?? json['download_count'] ?? 0,
            nbVues: json['nbVues'] ?? json['nb_vues'] ?? json['views'] ?? json['view_count'] ?? 0,
            estDisponible: json['estDisponible'] ?? json['disponible'] ?? json['available'] ?? json['is_available'] ?? true,
            dateCreation: _extractString(json['dateCreation'] ?? json['date_creation'] ?? json['created_at'] ?? json['date_created'], defaultValue: DateTime.now().toString()),
            dateMiseAJour: _extractString(json['dateMiseAJour'] ?? json['date_mise_a_jour'] ?? json['updated_at'] ?? json['date_updated'], defaultValue: DateTime.now().toString()),
          );
        }).toList();
      } else {
        throw Exception('Failed to load library items: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error fetching library items: $e');
    }
  }

  Future<LibraryItem> fetchLibraryItemById(String id) async {
    try {
      // Use existing course endpoint as fallback
      String url = '${EnvironmentConfig.apiBaseUrl}/formations/$id';

      final response = await _networkUtils.makeRequest(
        Uri.parse(url),
        method: 'GET',
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body)['data'];

        // Extract title and type safely
        String titre = _extractString(data['titre'] ?? data['intitule'] ?? data['nom'], defaultValue: 'Document sans titre');
        String typeStr = _extractString(data['type'], defaultValue: '');

        // Convert course data to library item format
        String docType = 'Livre'; // Default type
        if (typeStr.toLowerCase().contains('fascicule') ||
            titre.toLowerCase().contains('fascicule') ||
            titre.toLowerCase().contains('exercice')) {
          docType = 'Fascicule';
        }

        return LibraryItem(
          id: data['id'] ?? 0,
          titre: titre,
          description: _extractString(data['description'] ?? data['descriptif'], defaultValue: ''),
          type: docType,
          auteur: _extractString(data['auteur'] ?? data['enseignant'] ?? data['instructeur'], defaultValue: 'Auteur inconnu'),
          lien: _extractString(data['lien_correction'] ?? data['lien'] ?? data['pdf_url'] ?? data['fichier'], defaultValue: ''),
          image: _extractString(data['image'] ?? data['img'] ?? data['icone'], defaultValue: ''),
          categorie: _extractString(data['categorie'] ?? data['category'] ?? data['domaine'], defaultValue: 'Non catégorisé'),
          annee: data['annee'] ?? data['year'] ?? DateTime.now().year,
          slug: _extractString(data['slug'], defaultValue: ''),
          langue: _extractString(data['langue'] ?? data['langue_formation'] ?? data['language'], defaultValue: 'Français'),
          niveau: _extractString(data['niveau'] ?? data['level'], defaultValue: 'Tous niveaux'),
          taille: data['taille'] ?? data['size'] ?? 0,
          format: _extractString(data['format'], defaultValue: 'PDF'),
          motsCles: _extractString(data['mots_cles'] ?? data['keywords'], defaultValue: ''),
          estPayant: data['est_payant'] ?? data['is_paid'] ?? data['gratuit'] == false,
          prix: _extractString(data['prix'] ?? data['price'], defaultValue: '0'),
          datePublication: _extractString(data['date_publication'] ?? data['published_at'], defaultValue: DateTime.now().toString()),
          nbPages: data['nb_pages'] ?? data['pages'] ?? data['page_count'] ?? 0,
          editeur: _extractString(data['editeur'] ?? data['publisher'], defaultValue: ''),
          isbn: _extractString(data['isbn'], defaultValue: ''),
          resume: _extractString(data['resume'] ?? data['summary'] ?? data['abstract'], defaultValue: ''),
          nbTelechargements: data['nb_telechargements'] ?? data['downloads'] ?? 0,
          nbVues: data['nb_vues'] ?? data['views'] ?? 0,
          estDisponible: data['est_disponible'] ?? data['available'] ?? true,
          dateCreation: _extractString(data['date_creation'] ?? data['created_at'], defaultValue: DateTime.now().toString()),
          dateMiseAJour: _extractString(data['date_mise_a_jour'] ?? data['updated_at'], defaultValue: DateTime.now().toString()),
        );
      } else {
        throw Exception('Failed to load library item: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error fetching library item: $e');
    }
  }

  Future<List<LibraryItem>> searchLibraryItems(String query) async {
    return await fetchLibraryItems(searchQuery: query);
  }

  // Deprecated: Use fetchLibraryCategories() instead which returns full category objects
  Future<List<String>> fetchLibraryCategoryNames() async {
    try {
      // Use the home/bibliotheque endpoint to get library categories from the backend API
      String url = '${EnvironmentConfig.apiBaseUrl}/home/bibliotheque';

      final response = await _networkUtils.makeRequest(
        Uri.parse(url),
        method: 'GET',
      );

      // Check if the response is HTML (indicating an error page)
      final responseBody = response.body;
      if (responseBody.startsWith('<!DOCTYPE html') ||
          responseBody.startsWith('<html') ||
          responseBody.contains('<head') ||
          responseBody.contains('<body')) {
        throw Exception('Server returned an error page instead of JSON data. Please check if the backend server is running and accessible.');
      }

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(responseBody);

        // The API might return categories in different formats
        List<dynamic> data;
        if (responseData.containsKey('data')) {
          // Standard format with 'data' wrapper
          data = responseData['data'];
        } else if (responseData.containsKey('categories_bibliotheque')) {
          // Specific format for library categories
          data = responseData['categories_bibliotheque'];
        } else {
          // Fallback to using the whole response if it's a list
          data = responseData.values.firstWhere((element) => element is List, orElse: () => []) as List<dynamic>;
        }

        // Extract category names from the response
        return data.map((category) {
          // Handle different possible field names for category names
          return _extractString(
            category['nom'] ?? category['name'] ?? category['intitule'] ?? category['titre'] ?? category['category_name'],
            defaultValue: 'Catégorie'
          );
        }).toList();
      } else {
        throw Exception('Failed to load categories: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error fetching categories: $e');
    }
  }

  Future<List<String>> fetchLibraryTypes() async {
    try {
      // Use the filieres endpoint for fascicule types from the backend API
      String url = '${EnvironmentConfig.apiBaseUrl}/filieres';

      final response = await _networkUtils.makeRequest(
        Uri.parse(url),
        method: 'GET',
      );

      // Check if the response is HTML (indicating an error page)
      final responseBody = response.body;
      if (responseBody.startsWith('<!DOCTYPE html') ||
          responseBody.startsWith('<html') ||
          responseBody.contains('<head') ||
          responseBody.contains('<body')) {
        throw Exception('Server returned an error page instead of JSON data. Please check if the backend server is running and accessible.');
      }

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(responseBody);

        // The API might return data in different formats
        List<dynamic> data;
        if (responseData.containsKey('data')) {
          data = responseData['data'];
        } else {
          // Fallback to using the whole response if it's a list
          data = responseData.values.firstWhere((element) => element is List, orElse: () => []) as List<dynamic>;
        }

        // Extract filiere names as library types
        return data.map((filiere) {
          return _extractString(
            filiere['intitule'] ?? filiere['nom'] ?? filiere['name'] ?? filiere['titre'] ?? filiere['filiere_name'],
            defaultValue: 'Filière'
          );
        }).toList();
      } else {
        throw Exception('Failed to load types: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error fetching types: $e');
    }
  }

  Future<bool> downloadDocument(String documentId) async {
    try {
      // Use existing download endpoint as fallback
      String url = '${EnvironmentConfig.apiBaseUrl}/formations/$documentId/download';

      final response = await _networkUtils.makeRequest(
        Uri.parse(url),
        method: 'POST',
      );

      return response.statusCode == 200;
    } catch (e) {
      throw Exception('Error downloading document: $e');
    }
  }

  Future<bool> markAsViewed(String documentId) async {
    try {
      // Use existing view endpoint as fallback
      String url = '${EnvironmentConfig.apiBaseUrl}/formations/$documentId/view';

      final response = await _networkUtils.makeRequest(
        Uri.parse(url),
        method: 'POST',
      );

      return response.statusCode == 200;
    } catch (e) {
      throw Exception('Error marking document as viewed: $e');
    }
  }

  // Get library categories with item counts (for Books)
  Future<List<LibraryCategory>> fetchLibraryCategories() async {
    try {
      String url = '${EnvironmentConfig.apiBaseUrl}/bibliotheque';

      final response = await _networkUtils.makeRequest(
        Uri.parse(url),
        method: 'GET',
      );

      // Check if the response is HTML (indicating an error page)
      final responseBody = response.body;
      if (responseBody.startsWith('<!DOCTYPE html') ||
          responseBody.startsWith('<html') ||
          responseBody.contains('<head') ||
          responseBody.contains('<body')) {
        throw Exception('Server returned an error page instead of JSON data.');
      }

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(responseBody);

        // Extract categories
        List<dynamic> data = [];
        if (responseData.containsKey('categories')) {
          var categoriesData = responseData['categories'];
          if (categoriesData is Map && categoriesData.containsKey('data')) {
            data = categoriesData['data'];
          } else if (categoriesData is List) {
            data = categoriesData;
          }
        }

        // Convert to LibraryCategory objects
        return data.map((json) => LibraryCategory.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load library categories: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error fetching library categories: $e');
    }
  }

  // Get fascicule filieres with counts
  Future<List<FasciculeFiliere>> fetchFasciculeFilieres() async {
    try {
      String url = '${EnvironmentConfig.apiBaseUrl}/filieres';

      final response = await _networkUtils.makeRequest(
        Uri.parse(url),
        method: 'GET',
      );

      // Check if the response is HTML (indicating an error page)
      final responseBody = response.body;
      if (responseBody.startsWith('<!DOCTYPE html') ||
          responseBody.startsWith('<html') ||
          responseBody.contains('<head') ||
          responseBody.contains('<body')) {
        throw Exception('Server returned an error page instead of JSON data.');
      }

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(responseBody);

        // Extract filieres
        List<dynamic> data = [];
        if (responseData.containsKey('filieres')) {
          var filieresData = responseData['filieres'];
          if (filieresData is Map && filieresData.containsKey('data')) {
            data = filieresData['data'];
          } else if (filieresData is List) {
            data = filieresData;
          }
        }

        // Convert to FasciculeFiliere objects
        return data.map((json) => FasciculeFiliere.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load fascicule filieres: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error fetching fascicule filieres: $e');
    }
  }

  // Get library items by category slug
  Future<List<LibraryItem>> fetchLibraryItemsByCategory(String categorySlug) async {
    try {
      String url = '${EnvironmentConfig.apiBaseUrl}/livres_by_category/$categorySlug';

      final response = await _networkUtils.makeRequest(
        Uri.parse(url),
        method: 'GET',
      );

      if (response.statusCode == 200) {
        final responseBody = response.body;
        final Map<String, dynamic> responseData = json.decode(responseBody);

        List<dynamic> data = [];

        // Handle paginated response structure
        if (responseData.containsKey('livres')) {
          var livresData = responseData['livres'];
          if (livresData is Map && livresData.containsKey('data')) {
            // Paginated structure: livres.data
            data = livresData['data'];
          } else if (livresData is List) {
            // Direct list
            data = livresData;
          }
        } else if (responseData.containsKey('data')) {
          data = responseData['data'];
        }

        // Convert API data to LibraryItem objects
        return data.map((json) {
          String titre = _extractString(json['titre'] ?? json['intitule'], defaultValue: 'Document sans titre');

          return LibraryItem(
            id: json['id'] ?? 0,
            titre: titre,
            description: _extractString(json['description'], defaultValue: ''),
            type: 'Livre',
            auteur: _extractString(json['auteur'], defaultValue: 'Auteur inconnu'),
            lien: _extractString(json['lien'], defaultValue: ''),
            image: _extractString(json['image'] ?? json['img'], defaultValue: ''),
            categorie: _extractString(json['categorie'], defaultValue: 'Non catégorisé'),
            annee: json['annee'] ?? DateTime.now().year,
            slug: _extractString(json['slug'], defaultValue: ''),
            langue: _extractString(json['langue_formation'], defaultValue: 'Français'),
            niveau: _extractString(json['niveau'], defaultValue: 'Tous niveaux'),
            taille: json['taille'] ?? 0,
            format: _extractString(json['format'], defaultValue: 'PDF'),
            motsCles: _extractString(json['motsCles'], defaultValue: ''),
            estPayant: json['estPayant'] ?? false,
            prix: _extractString(json['prix'], defaultValue: '0'),
            datePublication: _extractString(json['date_publication'], defaultValue: DateTime.now().toString()),
            nbPages: json['nbPages'] ?? 0,
            editeur: _extractString(json['editeur'], defaultValue: ''),
            isbn: _extractString(json['isbn'], defaultValue: ''),
            resume: _extractString(json['resume'], defaultValue: ''),
            nbTelechargements: json['nbTelechargements'] ?? 0,
            nbVues: json['nbVues'] ?? 0,
            estDisponible: json['estDisponible'] ?? true,
            dateCreation: _extractString(json['created_at'], defaultValue: DateTime.now().toString()),
            dateMiseAJour: _extractString(json['updated_at'], defaultValue: DateTime.now().toString()),
          );
        }).toList();
      } else {
        throw Exception('Failed to load library items by category');
      }
    } catch (e) {
      throw Exception('Error fetching library items by category: $e');
    }
  }

  // Get fascicule series by filiere slug
  Future<List<FasciculeSerie>> fetchSeriesByFiliere(String filiereSlug) async {
    try {
      String url = '${EnvironmentConfig.apiBaseUrl}/series_filiere/$filiereSlug';

      final response = await _networkUtils.makeRequest(
        Uri.parse(url),
        method: 'GET',
      );

      // Check if the response is HTML (indicating an error page)
      final responseBody = response.body;
      if (responseBody.startsWith('<!DOCTYPE html') ||
          responseBody.startsWith('<html') ||
          responseBody.contains('<head') ||
          responseBody.contains('<body')) {
        throw Exception('Server returned an error page instead of JSON data.');
      }

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(responseBody);

        List<dynamic> data = [];

        // Handle paginated response structure
        if (responseData.containsKey('series_filiere')) {
          var seriesData = responseData['series_filiere'];
          if (seriesData is Map && seriesData.containsKey('data')) {
            // Paginated structure: series_filiere.data
            data = seriesData['data'];
          } else if (seriesData is List) {
            // Direct list
            data = seriesData;
          }
        } else if (responseData.containsKey('data')) {
          data = responseData['data'];
        }

        // Convert to FasciculeSerie objects
        return data.map((json) => FasciculeSerie.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load fascicule series: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error fetching fascicule series: $e');
    }
  }

  // Get fascicule categories by serie slug
  Future<List<LibraryCategory>> fetchCategoriesBySerie(String serieSlug) async {
    try {
      String url = '${EnvironmentConfig.apiBaseUrl}/categories_fascicule/$serieSlug';

      final response = await _networkUtils.makeRequest(
        Uri.parse(url),
        method: 'GET',
      );

      // Check if the response is HTML (indicating an error page)
      final responseBody = response.body;
      if (responseBody.startsWith('<!DOCTYPE html') ||
          responseBody.startsWith('<html') ||
          responseBody.contains('<head') ||
          responseBody.contains('<body')) {
        throw Exception('Server returned an error page instead of JSON data.');
      }

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(responseBody);

        List<dynamic> data = [];

        // Handle paginated response structure
        if (responseData.containsKey('categories_fascicule')) {
          var categoriesData = responseData['categories_fascicule'];
          if (categoriesData is Map && categoriesData.containsKey('data')) {
            // Paginated structure: categories_fascicule.data
            data = categoriesData['data'];
          } else if (categoriesData is List) {
            // Direct list
            data = categoriesData;
          }
        } else if (responseData.containsKey('data')) {
          data = responseData['data'];
        }

        // Convert to LibraryCategory objects
        return data.map((json) => LibraryCategory.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load fascicule categories: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error fetching fascicule categories: $e');
    }
  }

  // Get fascicules by category slug
  Future<List<LibraryItem>> fetchFasciculesByCategory(String categorySlug) async {
    try {
      String url = '${EnvironmentConfig.apiBaseUrl}/fascicules_categorie/$categorySlug';

      final response = await _networkUtils.makeRequest(
        Uri.parse(url),
        method: 'GET',
      );

      if (response.statusCode == 200) {
        final responseBody = response.body;
        final Map<String, dynamic> responseData = json.decode(responseBody);

        List<dynamic> data = [];

        // Handle paginated response structure
        if (responseData.containsKey('fascicules')) {
          var fasciculesData = responseData['fascicules'];
          if (fasciculesData is Map && fasciculesData.containsKey('data')) {
            // Paginated structure: fascicules.data
            data = fasciculesData['data'];
          } else if (fasciculesData is List) {
            // Direct list
            data = fasciculesData;
          }
        } else if (responseData.containsKey('data')) {
          data = responseData['data'];
        }

        // Convert API data to LibraryItem objects
        return data.map((json) {
          String titre = _extractString(json['titre'] ?? json['intitule'], defaultValue: 'Document sans titre');

          return LibraryItem(
            id: json['id'] ?? 0,
            titre: titre,
            description: _extractString(json['description'], defaultValue: ''),
            type: 'Fascicule',
            auteur: _extractString(json['auteur'], defaultValue: 'Auteur inconnu'),
            lien: _extractString(json['lien'] ?? json['correction_link'], defaultValue: ''),
            image: _extractString(json['image'] ?? json['img'], defaultValue: ''),
            categorie: _extractString(json['categorie'], defaultValue: 'Non catégorisé'),
            annee: json['annee'] ?? DateTime.now().year,
            slug: _extractString(json['slug'], defaultValue: ''),
            langue: _extractString(json['langue_formation'], defaultValue: 'Français'),
            niveau: _extractString(json['niveau'], defaultValue: 'Tous niveaux'),
            taille: json['taille'] ?? 0,
            format: _extractString(json['format'], defaultValue: 'PDF'),
            motsCles: _extractString(json['motsCles'], defaultValue: ''),
            estPayant: json['estPayant'] ?? false,
            prix: _extractString(json['prix'], defaultValue: '0'),
            datePublication: _extractString(json['date_publication'] ?? json['date'], defaultValue: DateTime.now().toString()),
            nbPages: json['nbPages'] ?? json['nombre_de_points'] ?? 0,
            editeur: _extractString(json['editeur'], defaultValue: ''),
            isbn: _extractString(json['isbn'], defaultValue: ''),
            resume: _extractString(json['resume'], defaultValue: ''),
            nbTelechargements: json['nbTelechargements'] ?? 0,
            nbVues: json['nbVues'] ?? 0,
            estDisponible: json['estDisponible'] ?? json['etat'] == 1 ?? true,
            dateCreation: _extractString(json['created_at'], defaultValue: DateTime.now().toString()),
            dateMiseAJour: _extractString(json['updated_at'], defaultValue: DateTime.now().toString()),
          );
        }).toList();
      } else {
        throw Exception('Failed to load fascicules by category');
      }
    } catch (e) {
      throw Exception('Error fetching fascicules by category: $e');
    }
  }

  // Get all fascicule categories (type = 3)
  Future<List<LibraryCategory>> fetchFasciculeCategories({int page = 1, int perPage = 20}) async {
    try {
      String url = '${EnvironmentConfig.apiBaseUrl}/categories_fascicule?per_page=$perPage&page=$page';

      final response = await _networkUtils.makeRequest(
        Uri.parse(url),
        method: 'GET',
      );

      final responseBody = response.body;
      if (responseBody.startsWith('<!DOCTYPE html') ||
          responseBody.startsWith('<html') ||
          responseBody.startsWith('<!doctype html')) {
        throw Exception('Received HTML error page instead of JSON');
      }

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(responseBody);

        List<dynamic> data = [];

        // Handle paginated response structure
        if (responseData.containsKey('categories_fascicule')) {
          var categoriesData = responseData['categories_fascicule'];
          if (categoriesData is Map && categoriesData.containsKey('data')) {
            // Paginated structure: categories_fascicule.data
            data = categoriesData['data'];
          } else if (categoriesData is List) {
            // Direct list
            data = categoriesData;
          }
        } else if (responseData.containsKey('data')) {
          data = responseData['data'];
        }

        // Convert API data to LibraryCategory objects
        return data.map((json) {
          String intitule = _extractString(json['intitule'], defaultValue: 'Catégorie sans nom');

          return LibraryCategory(
            id: json['id'] ?? 0,
            nom: intitule,
            slug: _extractString(json['slug'], defaultValue: ''),
            itemCount: json['fascicules_count'] ?? 0,
            image: _extractString(json['img'], defaultValue: ''),
          );
        }).toList();
      } else {
        throw Exception('Failed to load fascicule categories: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching fascicule categories: $e');
    }
  }
}