import 'package:dio/dio.dart';
import 'logger_service.dart';

/// Intercepteur Dio pour logger automatiquement tous les appels HTTP
class HttpLoggingInterceptor extends Interceptor {
  final LoggerService _logger = LoggerService.instance;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final startTime = DateTime.now();
    options.extra['startTime'] = startTime;

    _logger.logApiCall(
      options.method,
      options.path,
      requestData: _sanitizeData(options.data),
    );

    _logger.logInfo('HTTP Request started', data: {
      'method': options.method,
      'url': options.uri.toString(),
      'headers': _sanitizeHeaders(options.headers),
      'queryParameters': options.queryParameters,
      'contentType': options.contentType,
    });

    super.onRequest(options, handler);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    final startTime = response.requestOptions.extra['startTime'] as DateTime?;
    final duration = startTime != null ? DateTime.now().difference(startTime) : null;

    _logger.logApiCall(
      response.requestOptions.method,
      response.requestOptions.path,
      statusCode: response.statusCode,
      responseData: _sanitizeData(response.data),
      duration: duration,
    );

    _logger.logSuccess('HTTP Request completed', data: {
      'method': response.requestOptions.method,
      'url': response.requestOptions.uri.toString(),
      'statusCode': response.statusCode,
      'statusMessage': response.statusMessage,
      'duration': duration != null ? '${duration.inMilliseconds}ms' : 'unknown',
      'responseSize': _getResponseSize(response.data),
    });

    super.onResponse(response, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final startTime = err.requestOptions.extra['startTime'] as DateTime?;
    final duration = startTime != null ? DateTime.now().difference(startTime) : null;

    final statusCode = err.response?.statusCode;
    final responseData = err.response?.data;

    _logger.logError('HTTP Request failed', error: err, data: {
      'method': err.requestOptions.method,
      'url': err.requestOptions.uri.toString(),
      'statusCode': statusCode,
      'statusMessage': err.response?.statusMessage,
      'errorType': err.type.toString(),
      'errorMessage': err.message,
      'duration': duration != null ? '${duration.inMilliseconds}ms' : 'unknown',
      'responseData': _sanitizeData(responseData),
    });

    // Log specific error types
    switch (err.type) {
      case DioExceptionType.connectionTimeout:
        _logger.logWarning('HTTP connection timeout', data: {
          'url': err.requestOptions.uri.toString(),
          'timeout': err.requestOptions.connectTimeout?.inMilliseconds,
        });
        break;
      case DioExceptionType.sendTimeout:
        _logger.logWarning('HTTP send timeout', data: {
          'url': err.requestOptions.uri.toString(),
          'timeout': err.requestOptions.sendTimeout?.inMilliseconds,
        });
        break;
      case DioExceptionType.receiveTimeout:
        _logger.logWarning('HTTP receive timeout', data: {
          'url': err.requestOptions.uri.toString(),
          'timeout': err.requestOptions.receiveTimeout?.inMilliseconds,
        });
        break;
      case DioExceptionType.badResponse:
        _logger.logError('HTTP bad response', data: {
          'url': err.requestOptions.uri.toString(),
          'statusCode': statusCode,
          'responseData': _sanitizeData(responseData),
        });
        break;
      case DioExceptionType.cancel:
        _logger.logInfo('HTTP request cancelled', data: {
          'url': err.requestOptions.uri.toString(),
        });
        break;
      case DioExceptionType.connectionError:
        _logger.logError('HTTP connection error', error: err, data: {
          'url': err.requestOptions.uri.toString(),
        });
        break;
      case DioExceptionType.unknown:
        _logger.logError('HTTP unknown error', error: err, data: {
          'url': err.requestOptions.uri.toString(),
        });
        break;
      case DioExceptionType.badCertificate:
        _logger.logError('HTTP bad certificate', error: err, data: {
          'url': err.requestOptions.uri.toString(),
        });
        break;
    }

    super.onError(err, handler);
  }

  /// Sanitize sensitive data from logs
  Map<String, dynamic>? _sanitizeData(dynamic data) {
    if (data == null) return null;

    if (data is Map<String, dynamic>) {
      final sanitized = <String, dynamic>{};
      data.forEach((key, value) {
        if (_isSensitiveKey(key)) {
          sanitized[key] = '[REDACTED]';
        } else {
          sanitized[key] = value;
        }
      });
      return sanitized;
    }

    if (data is String) {
      // For string data, just return the length info
      return {
        'type': 'string',
        'length': data.length,
        'preview': data.length > 100 ? '${data.substring(0, 100)}...' : data,
      };
    }

    if (data is List) {
      return {
        'type': 'list',
        'length': data.length,
        'preview': data.take(3).toList(),
      };
    }

    return {'type': data.runtimeType.toString(), 'value': data.toString()};
  }

  /// Sanitize sensitive headers
  Map<String, dynamic> _sanitizeHeaders(Map<String, dynamic> headers) {
    final sanitized = <String, dynamic>{};
    headers.forEach((key, value) {
      if (_isSensitiveKey(key)) {
        sanitized[key] = '[REDACTED]';
      } else {
        sanitized[key] = value;
      }
    });
    return sanitized;
  }

  /// Check if a key contains sensitive information
  bool _isSensitiveKey(String key) {
    final lowerKey = key.toLowerCase();
    return lowerKey.contains('password') ||
        lowerKey.contains('token') ||
        lowerKey.contains('auth') ||
        lowerKey.contains('secret') ||
        lowerKey.contains('key') ||
        lowerKey.contains('pin') ||
        lowerKey.contains('otp') ||
        lowerKey.contains('credential');
  }

  /// Get response size for logging
  String _getResponseSize(dynamic data) {
    if (data == null) return '0 bytes';

    if (data is String) {
      final bytes = data.length;
      return _formatBytes(bytes);
    }

    if (data is Map || data is List) {
      final jsonString = data.toString();
      return _formatBytes(jsonString.length);
    }

    return 'unknown';
  }

  /// Format bytes to human readable format
  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}