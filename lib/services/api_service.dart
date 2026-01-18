import 'package:dio/dio.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/api_config.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  late Dio _dio;
  String? _token;
  late FlutterSecureStorage _secureStorage;

  static const String _tokenKey = 'auth_token';
  static const String _userIdKey = 'user_id';

  Future<void> initialize() async {
    _secureStorage = const FlutterSecureStorage();

    // Load token from secure storage on initialization
    await _loadToken();

    _dio = Dio(BaseOptions(
      baseUrl: ApiConfig.baseUrl,
      connectTimeout: Duration(milliseconds: ApiConfig.connectTimeout),
      receiveTimeout: Duration(milliseconds: ApiConfig.receiveTimeout),
      sendTimeout: Duration(milliseconds: ApiConfig.sendTimeout),
      headers: ApiConfig.defaultHeaders,
    ));

    // Add interceptors
    _dio.interceptors.add(_getAuthInterceptor());
    _dio.interceptors.add(_getLoggingInterceptor());
    _dio.interceptors.add(_getErrorInterceptor());
  }

  // Load token from secure storage
  Future<void> _loadToken() async {
    try {
      _token = await _secureStorage.read(key: _tokenKey);
    } catch (e) {
      _token = null;
    }
  }

  // Auth interceptor to automatically add token to requests
  Interceptor _getAuthInterceptor() {
    return InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await getToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (error, handler) async {
        if (error.response?.statusCode == 401) {
          // Token expired or invalid
          await clearToken();
          // You might want to redirect to login screen here
        }
        handler.next(error);
      },
    );
  }

  // Logging interceptor for debugging
  Interceptor _getLoggingInterceptor() {
    return LogInterceptor(
      requestBody: true,
      responseBody: true,
      requestHeader: true,
      responseHeader: false,
      error: true,
    );
  }

  // Error interceptor for handling network errors
  Interceptor _getErrorInterceptor() {
    return InterceptorsWrapper(
      onError: (error, handler) async {
        if (error.type == DioExceptionType.connectionTimeout ||
            error.type == DioExceptionType.receiveTimeout ||
            error.type == DioExceptionType.sendTimeout) {
          throw ApiException('Connection timeout', 408);
        }

        if (error.type == DioExceptionType.connectionError) {
          final connectivityResult = await Connectivity().checkConnectivity();
          if (connectivityResult == ConnectivityResult.none) {
            throw ApiException('No internet connection', 0);
          }
          throw ApiException('Network error', 0);
        }

        if (error.response != null) {
          final statusCode = error.response!.statusCode ?? 0;
          final path = error.requestOptions.path;

          // Pour les endpoints d'authentification, ne pas lancer d'exception
          // Laisser la réponse passer pour que AuthService puisse la gérer
          if ((path.contains('/login') || path.contains('/register')) &&
              (statusCode == 401 || statusCode == 422)) {
            // Retourner la réponse telle quelle sans lancer d'exception
            handler.resolve(error.response!);
            return;
          }

          // Pour logout, ne pas lancer d'exception (l'app se déconnecte localement de toute façon)
          if (path.contains('/logout')) {
            print('⚠️ Logout endpoint failed, but continuing with local logout');
            handler.resolve(error.response!);
            return;
          }

          String message = 'Unknown error';
          if (error.response!.data is Map<String, dynamic>) {
            message = error.response!.data['message'] ?? 'Server error';
          } else {
            message = 'Server error occurred';
          }
          throw ApiException(message, statusCode);
        }

        throw ApiException('Unknown error occurred', 0);
      },
    );
  }

  // Token management with secure storage
  Future<String?> getToken() async {
    // Return cached token if available
    if (_token != null) {
      return _token;
    }

    // Try to load from secure storage
    try {
      _token = await _secureStorage.read(key: _tokenKey);
      return _token;
    } catch (e) {
      return null;
    }
  }

  Future<void> setToken(String token) async {
    _token = token;
    try {
      await _secureStorage.write(key: _tokenKey, value: token);
    } catch (e) {
      // If secure storage fails, at least keep in memory
      print('Error saving token to secure storage: $e');
    }
  }

  Future<void> clearToken() async {
    _token = null;
    try {
      await _secureStorage.delete(key: _tokenKey);
      await _secureStorage.delete(key: _userIdKey);
    } catch (e) {
      print('Error clearing token from secure storage: $e');
    }
  }

  // Save user ID for quick access
  Future<void> saveUserId(int userId) async {
    try {
      await _secureStorage.write(key: _userIdKey, value: userId.toString());
    } catch (e) {
      print('Error saving user ID: $e');
    }
  }

  // Get saved user ID
  Future<int?> getUserId() async {
    try {
      final userIdStr = await _secureStorage.read(key: _userIdKey);
      return userIdStr != null ? int.tryParse(userIdStr) : null;
    } catch (e) {
      return null;
    }
  }

  // HTTP Methods
  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return await _dio.get(
      path,
      queryParameters: queryParameters,
      options: options,
    );
  }

  Future<Response> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return await _dio.post(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }

  Future<Response> put(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return await _dio.put(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }

  Future<Response> delete(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return await _dio.delete(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }

  // Utility methods
  Future<bool> hasValidToken() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  Future<void> clearAllData() async {
    await clearToken();
  }
}

// Custom exception class
class ApiException implements Exception {
  final String message;
  final int statusCode;

  ApiException(this.message, this.statusCode);

  @override
  String toString() => 'ApiException: $message (Status: $statusCode)';
}