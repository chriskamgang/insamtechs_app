/// Utilitaire pour la gestion des requêtes réseau
/// Ce fichier fournit des méthodes pour effectuer des requêtes HTTP
/// avec gestion des erreurs et authentification

import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class NetworkUtils {
  static const String _tokenKey = 'auth_token';

  /// Effectue une requête HTTP avec gestion des erreurs
  Future<http.Response> makeRequest(
    Uri uri, {
    String method = 'GET',
    Map<String, String>? headers,
    dynamic body,
  }) async {
    try {
      // Récupérer le token d'authentification
      String? token = await _getToken();

      // Préparer les en-têtes
      Map<String, String> requestHeaders = {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
        ...?headers,
      };

      // Effectuer la requête selon la méthode
      http.Response response;
      switch (method.toUpperCase()) {
        case 'GET':
          response = await http.get(uri, headers: requestHeaders);
          break;
        case 'POST':
          response = await http.post(
            uri,
            headers: requestHeaders,
            body: body != null ? jsonEncode(body) : null,
          );
          break;
        case 'PUT':
          response = await http.put(
            uri,
            headers: requestHeaders,
            body: body != null ? jsonEncode(body) : null,
          );
          break;
        case 'DELETE':
          response = await http.delete(uri, headers: requestHeaders);
          break;
        default:
          throw Exception('Méthode HTTP non supportée: $method');
      }

      return response;
    } catch (e) {
      throw Exception('Erreur réseau: $e');
    }
  }

  /// Récupère le token d'authentification
  Future<String?> _getToken() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      return prefs.getString(_tokenKey);
    } catch (e) {
      print('Erreur lors de la récupération du token: $e');
      return null;
    }
  }

  /// Enregistre le token d'authentification
  Future<void> setToken(String token) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString(_tokenKey, token);
    } catch (e) {
      print('Erreur lors de l\'enregistrement du token: $e');
    }
  }

  /// Supprime le token d'authentification
  Future<void> clearToken() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.remove(_tokenKey);
    } catch (e) {
      print('Erreur lors de la suppression du token: $e');
    }
  }
}
