import '../services/logger_service.dart';

/// Mixin pour faciliter l'ajout de logs dans les widgets et providers
mixin LoggingMixin {
  LoggerService get logger => LoggerService.instance;

  String get loggerTag => runtimeType.toString();

  /// Log spécialisé pour les appels HTTP avec timing
  void logHttpCall(
    String method,
    String url, {
    Map<String, dynamic>? requestData,
    Map<String, dynamic>? headers,
    int? statusCode,
    Map<String, dynamic>? responseData,
    Duration? duration,
    String? errorMessage,
  }) {
    final endpoint = _extractEndpoint(url);
    final isSuccess = statusCode != null && statusCode >= 200 && statusCode < 300;

    if (isSuccess) {
      logger.logSuccess('$method $endpoint ($statusCode)',
          screen: loggerTag,
          data: {
            'method': method,
            'url': url,
            'statusCode': statusCode,
            if (requestData != null) 'request': requestData,
            if (headers != null) 'headers': headers,
            if (responseData != null) 'response': responseData,
            if (duration != null) 'duration': '${duration.inMilliseconds}ms',
          });
    } else {
      logger.logError('$method $endpoint failed',
          screen: loggerTag,
          data: {
            'method': method,
            'url': url,
            if (statusCode != null) 'statusCode': statusCode,
            if (requestData != null) 'request': requestData,
            if (headers != null) 'headers': headers,
            if (responseData != null) 'response': responseData,
            if (duration != null) 'duration': '${duration.inMilliseconds}ms',
            if (errorMessage != null) 'error': errorMessage,
          });
    }
  }

  /// Log pour les changements d'état dans les providers
  void logProviderStateChange(
    String from,
    String to, {
    Map<String, dynamic>? data,
  }) {
    logger.logStateChange(loggerTag, from, to, screen: loggerTag, data: data);
  }

  /// Log pour les erreurs dans les providers
  void logProviderError(
    String operation,
    Object error, {
    StackTrace? stackTrace,
    Map<String, dynamic>? data,
  }) {
    logger.logError(
      'Error in $operation',
      screen: loggerTag,
      error: error,
      stackTrace: stackTrace,
      data: data,
    );
  }

  /// Log pour les opérations réussies dans les providers
  void logProviderSuccess(
    String operation, {
    Map<String, dynamic>? data,
  }) {
    logger.logSuccess(
      operation,
      screen: loggerTag,
      data: data,
    );
  }

  /// Log pour les informations dans les providers
  void logProviderInfo(
    String message, {
    Map<String, dynamic>? data,
  }) {
    logger.logInfo(
      message,
      screen: loggerTag,
      data: data,
    );
  }

  /// Extrait l'endpoint d'une URL complète
  String _extractEndpoint(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.path;
    } catch (e) {
      return url;
    }
  }
}