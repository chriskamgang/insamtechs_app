import 'package:flutter/material.dart';
import 'logger_service.dart';

/// Service de navigation centralisé avec logging automatique
/// Permet de tracer toutes les navigations dans l'application
class NavigationService {
  static NavigationService? _instance;
  static NavigationService get instance => _instance ??= NavigationService._();
  NavigationService._();

  final LoggerService _logger = LoggerService.instance;

  // Stack de navigation pour tracker l'historique
  final List<String> _navigationStack = [];

  /// Get current route from navigation stack
  String? get currentRoute => _navigationStack.isNotEmpty ? _navigationStack.last : null;

  /// Get navigation history
  List<String> get navigationHistory => List.unmodifiable(_navigationStack);

  /// Navigate to named route with automatic logging
  Future<T?> pushNamed<T extends Object?>(
    BuildContext context,
    String routeName, {
    Object? arguments,
    String? fromScreen,
  }) async {
    final from = fromScreen ?? currentRoute ?? 'unknown';

    _logger.logNavigation(from, routeName, arguments: arguments is Map<String, dynamic>
        ? arguments
        : arguments != null
            ? {'arguments': arguments.toString()}
            : null);

    _navigationStack.add(routeName);

    try {
      final result = await Navigator.pushNamed<T>(
        context,
        routeName,
        arguments: arguments,
      );

      _logger.logSuccess('Navigation completed', data: {
        'from': from,
        'to': routeName,
        'hasResult': result != null,
      });

      return result;
    } catch (e) {
      _logger.logError('Navigation failed', error: e, data: {
        'from': from,
        'to': routeName,
        'arguments': arguments.toString(),
      });
      rethrow;
    }
  }

  /// Replace current route with new one
  Future<T?> pushReplacementNamed<T extends Object?, TO extends Object?>(
    BuildContext context,
    String routeName, {
    Object? arguments,
    TO? result,
    String? fromScreen,
  }) async {
    final from = fromScreen ?? currentRoute ?? 'unknown';

    _logger.logNavigation('$from (replacement)', routeName, arguments: arguments is Map<String, dynamic>
        ? arguments
        : arguments != null
            ? {'arguments': arguments.toString()}
            : null);

    // Update stack
    if (_navigationStack.isNotEmpty) {
      _navigationStack.removeLast();
    }
    _navigationStack.add(routeName);

    try {
      final navResult = await Navigator.pushReplacementNamed<T, TO>(
        context,
        routeName,
        arguments: arguments,
        result: result,
      );

      _logger.logSuccess('Replacement navigation completed', data: {
        'from': from,
        'to': routeName,
        'hasResult': navResult != null,
      });

      return navResult;
    } catch (e) {
      _logger.logError('Replacement navigation failed', error: e, data: {
        'from': from,
        'to': routeName,
      });
      rethrow;
    }
  }

  /// Navigate and clear all previous routes
  Future<T?> pushNamedAndRemoveUntil<T extends Object?>(
    BuildContext context,
    String routeName,
    RoutePredicate predicate, {
    Object? arguments,
    String? fromScreen,
  }) async {
    final from = fromScreen ?? currentRoute ?? 'unknown';

    _logger.logNavigation('$from (clear stack)', routeName, arguments: arguments is Map<String, dynamic>
        ? arguments
        : arguments != null
            ? {'arguments': arguments.toString()}
            : null);

    // Clear stack and add new route
    _navigationStack.clear();
    _navigationStack.add(routeName);

    try {
      final result = await Navigator.pushNamedAndRemoveUntil<T>(
        context,
        routeName,
        predicate,
        arguments: arguments,
      );

      _logger.logSuccess('Stack clearing navigation completed', data: {
        'from': from,
        'to': routeName,
        'stackCleared': true,
      });

      return result;
    } catch (e) {
      _logger.logError('Stack clearing navigation failed', error: e, data: {
        'from': from,
        'to': routeName,
      });
      rethrow;
    }
  }

  /// Pop current route
  void pop<T extends Object?>(
    BuildContext context, {
    T? result,
    String? fromScreen,
  }) {
    final from = fromScreen ?? currentRoute ?? 'unknown';

    // Determine destination
    String destination = 'unknown';
    if (_navigationStack.length > 1) {
      destination = _navigationStack[_navigationStack.length - 2];
    }

    _logger.logNavigation(from, destination, arguments: result != null
        ? {'result': result.toString()}
        : null);

    // Update stack
    if (_navigationStack.isNotEmpty) {
      _navigationStack.removeLast();
    }

    try {
      Navigator.pop<T>(context, result);

      _logger.logSuccess('Pop navigation completed', data: {
        'from': from,
        'to': destination,
        'hasResult': result != null,
      });
    } catch (e) {
      _logger.logError('Pop navigation failed', error: e, data: {
        'from': from,
        'to': destination,
      });
      rethrow;
    }
  }

  /// Pop until specific route
  void popUntil(
    BuildContext context,
    RoutePredicate predicate, {
    String? fromScreen,
  }) {
    final from = fromScreen ?? currentRoute ?? 'unknown';

    _logger.logNavigation('$from (pop until)', 'target route');

    try {
      Navigator.popUntil(context, predicate);

      // Update stack - this is approximate since we don't know exactly where we landed
      _navigationStack.clear();
      if (ModalRoute.of(context)?.settings.name != null) {
        _navigationStack.add(ModalRoute.of(context)!.settings.name!);
      }

      _logger.logSuccess('Pop until navigation completed', data: {
        'from': from,
        'currentRoute': currentRoute,
      });
    } catch (e) {
      _logger.logError('Pop until navigation failed', error: e, data: {
        'from': from,
      });
      rethrow;
    }
  }

  /// Check if can pop
  bool canPop(BuildContext context) {
    final canPopResult = Navigator.canPop(context);

    _logger.logDebug('Checked if can pop', data: {
      'canPop': canPopResult,
      'stackSize': _navigationStack.length,
      'currentRoute': currentRoute,
    });

    return canPopResult;
  }

  /// Update current route manually (for cases where automatic tracking might miss)
  void updateCurrentRoute(String routeName) {
    _logger.logDebug('Manually updating current route', data: {
      'from': currentRoute,
      'to': routeName,
    });

    if (_navigationStack.isEmpty || _navigationStack.last != routeName) {
      _navigationStack.add(routeName);
    }
  }

  /// Clear navigation history
  void clearHistory() {
    _logger.logInfo('Clearing navigation history', data: {
      'previousStackSize': _navigationStack.length,
      'previousStack': _navigationStack.toList(),
    });

    _navigationStack.clear();
  }

  /// Get navigation analytics
  Map<String, dynamic> getAnalytics() {
    return {
      'currentRoute': currentRoute,
      'stackSize': _navigationStack.length,
      'navigationHistory': _navigationStack.toList(),
      'totalNavigations': _navigationStack.length,
    };
  }
}