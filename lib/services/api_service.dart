import 'package:dio/dio.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../config/api_config.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  late Dio _dio;
  String? _token;

  void initialize() {
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

  // Token management (in-memory storage)
  Future<String?> getToken() async {
    return _token;
  }

  Future<void> setToken(String token) async {
    _token = token;
  }

  Future<void> clearToken() async {
    _token = null;
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
    _token = null;
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