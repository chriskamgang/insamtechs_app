import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';

// Types de logs
enum LogLevel {
  debug('DEBUG', '🔍'),
  info('INFO', '💡'),
  warning('WARNING', '⚠️'),
  error('ERROR', '❌'),
  success('SUCCESS', '✅'),
  navigation('NAV', '🧭'),
  userAction('USER', '👤'),
  apiCall('API', '🌐'),
  stateChange('STATE', '🔄');

  const LogLevel(this.name, this.emoji);
  final String name;
  final String emoji;
}

/// Service de logging centralisé pour l'application
/// Permet de tracer toutes les actions utilisateur et événements système
class LoggerService {
  static const String _tag = 'INSAMTCHS';

  // Instance singleton
  static LoggerService? _instance;
  static LoggerService get instance => _instance ??= LoggerService._();
  LoggerService._();

  /// Log générique
  void log(
    String message, {
    LogLevel level = LogLevel.info,
    String? screen,
    String? action,
    Map<String, dynamic>? data,
    Object? error,
    StackTrace? stackTrace,
  }) {
    if (kDebugMode) {
      final timestamp = DateTime.now().toIso8601String();
      final screenInfo = screen != null ? ' [$screen]' : '';
      final actionInfo = action != null ? ' [$action]' : '';

      String logMessage = '${level.emoji} [$_tag]$screenInfo$actionInfo - $message';

      if (data != null && data.isNotEmpty) {
        logMessage += '\n📊 Data: ${data.toString()}';
      }

      if (error != null) {
        logMessage += '\n💥 Error: ${error.toString()}';
      }

      // Utilisation de developer.log pour une meilleure intégration avec les outils de debug
      developer.log(
        logMessage,
        time: DateTime.now(),
        level: _getLevelInt(level),
        name: _tag,
        error: error,
        stackTrace: stackTrace,
      );

      // Aussi afficher dans la console pour le développement
      print('[$timestamp] $logMessage');
    }
  }

  /// Log d'action utilisateur
  void logUserAction(
    String action, {
    String? screen,
    Map<String, dynamic>? data,
  }) {
    log(
      action,
      level: LogLevel.userAction,
      screen: screen,
      action: action,
      data: data,
    );
  }

  /// Log de navigation
  void logNavigation(
    String from,
    String to, {
    Map<String, dynamic>? arguments,
  }) {
    log(
      'Navigation from $from to $to',
      level: LogLevel.navigation,
      data: arguments,
    );
  }

  /// Log d'appel API
  void logApiCall(
    String method,
    String endpoint, {
    Map<String, dynamic>? requestData,
    int? statusCode,
    Map<String, dynamic>? responseData,
    Duration? duration,
  }) {
    final data = <String, dynamic>{
      'method': method,
      'endpoint': endpoint,
      if (requestData != null) 'request': requestData,
      if (statusCode != null) 'statusCode': statusCode,
      if (responseData != null) 'response': responseData,
      if (duration != null) 'duration': '${duration.inMilliseconds}ms',
    };

    log(
      '$method $endpoint ${statusCode != null ? '($statusCode)' : ''}',
      level: LogLevel.apiCall,
      data: data,
    );
  }

  /// Log de changement d'état
  void logStateChange(
    String component,
    String from,
    String to, {
    String? screen,
    Map<String, dynamic>? data,
  }) {
    log(
      '$component state changed: $from → $to',
      level: LogLevel.stateChange,
      screen: screen,
      data: data,
    );
  }

  /// Log d'information
  void logInfo(
    String message, {
    String? screen,
    Map<String, dynamic>? data,
  }) {
    log(message, level: LogLevel.info, screen: screen, data: data);
  }

  /// Log de succès
  void logSuccess(
    String message, {
    String? screen,
    Map<String, dynamic>? data,
  }) {
    log(message, level: LogLevel.success, screen: screen, data: data);
  }

  /// Log d'erreur
  void logError(
    String message, {
    String? screen,
    Object? error,
    StackTrace? stackTrace,
    Map<String, dynamic>? data,
  }) {
    log(
      message,
      level: LogLevel.error,
      screen: screen,
      error: error,
      stackTrace: stackTrace,
      data: data,
    );
  }

  /// Log de warning
  void logWarning(
    String message, {
    String? screen,
    Map<String, dynamic>? data,
  }) {
    log(message, level: LogLevel.warning, screen: screen, data: data);
  }

  /// Log de debug
  void logDebug(
    String message, {
    String? screen,
    Map<String, dynamic>? data,
  }) {
    log(message, level: LogLevel.debug, screen: screen, data: data);
  }

  /// Convertit le niveau de log en entier pour developer.log
  int _getLevelInt(LogLevel level) {
    switch (level) {
      case LogLevel.debug:
        return 500;
      case LogLevel.info:
        return 800;
      case LogLevel.warning:
        return 900;
      case LogLevel.error:
        return 1000;
      default:
        return 800;
    }
  }

  /// Log de démarrage d'écran
  void logScreenStart(String screenName, {Map<String, dynamic>? arguments}) {
    logNavigation('previous', screenName, arguments: arguments);
    logInfo('Screen started: $screenName', screen: screenName, data: arguments);
  }

  /// Log de fin d'écran
  void logScreenEnd(String screenName) {
    logInfo('Screen ended: $screenName', screen: screenName);
  }

  /// Log de geste/interaction utilisateur
  void logUserGesture(
    String gesture,
    String element, {
    String? screen,
    Map<String, dynamic>? data,
  }) {
    logUserAction('$gesture on $element', screen: screen, data: data);
  }

  /// Log de formulaire
  void logFormAction(
    String formName,
    String action, {
    String? screen,
    Map<String, dynamic>? formData,
    List<String>? errors,
  }) {
    final data = <String, dynamic>{
      'form': formName,
      'action': action,
      if (formData != null) 'formData': formData,
      if (errors != null && errors.isNotEmpty) 'errors': errors,
    };

    logUserAction('Form $action: $formName', screen: screen, data: data);
  }
}

/// Extension pour faciliter l'utilisation du logger dans les widgets
extension LoggerExtension on Object {
  LoggerService get logger => LoggerService.instance;

  String get loggerTag => runtimeType.toString();
}