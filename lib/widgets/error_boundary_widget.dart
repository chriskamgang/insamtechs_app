import 'package:flutter/material.dart';
import '../services/logger_service.dart';

/// Widget wrapper qui capture et log les erreurs de widgets enfants
class ErrorBoundaryWidget extends StatefulWidget {
  final Widget child;
  final String screenName;
  final Widget? fallbackWidget;
  final void Function(Object error, StackTrace stackTrace)? onError;

  const ErrorBoundaryWidget({
    super.key,
    required this.child,
    required this.screenName,
    this.fallbackWidget,
    this.onError,
  });

  @override
  State<ErrorBoundaryWidget> createState() => _ErrorBoundaryWidgetState();
}

class _ErrorBoundaryWidgetState extends State<ErrorBoundaryWidget> {
  final LoggerService _logger = LoggerService.instance;
  Object? _error;
  StackTrace? _stackTrace;

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return widget.fallbackWidget ?? _buildDefaultErrorWidget();
    }

    // Wrap child in error catching widget
    return _ErrorCatchingWidget(
      screenName: widget.screenName,
      onError: (error, stackTrace) {
        _logger.logError(
          'Runtime error in ${widget.screenName}',
          screen: widget.screenName,
          error: error,
          stackTrace: stackTrace,
        );

        widget.onError?.call(error, stackTrace);

        if (mounted) {
          setState(() {
            _error = error;
            _stackTrace = stackTrace;
          });
        }
      },
      child: widget.child,
    );
  }

  Widget _buildDefaultErrorWidget() {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Erreur'),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red,
              ),
              const SizedBox(height: 16),
              const Text(
                'Une erreur inattendue s\'est produite',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Écran: ${widget.screenName}',
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
              if (_stackTrace != null) ...[
                const SizedBox(height: 8),
                Text(
                  'Erreur: ${_error.toString()}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  _logger.logUserGesture('tap', 'error_retry_button', screen: widget.screenName);
                  setState(() {
                    _error = null;
                    _stackTrace = null;
                  });
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Réessayer'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E3A8A),
                  foregroundColor: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: () {
                  _logger.logUserGesture('tap', 'error_back_button', screen: widget.screenName);
                  Navigator.of(context).pop();
                },
                icon: const Icon(Icons.arrow_back),
                label: const Text('Retour'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Widget interne qui capture les erreurs runtime
class _ErrorCatchingWidget extends StatelessWidget {
  final Widget child;
  final String screenName;
  final void Function(Object error, StackTrace stackTrace) onError;

  const _ErrorCatchingWidget({
    required this.child,
    required this.screenName,
    required this.onError,
  });

  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (context) {
        try {
          return child;
        } catch (error, stackTrace) {
          onError(error, stackTrace);
          rethrow;
        }
      },
    );
  }
}

/// Extension pour faciliter l'utilisation d'ErrorBoundaryWidget
extension WidgetErrorBoundary on Widget {
  Widget withErrorBoundary({
    required String screenName,
    Widget? fallbackWidget,
    void Function(Object error, StackTrace stackTrace)? onError,
  }) {
    return ErrorBoundaryWidget(
      screenName: screenName,
      fallbackWidget: fallbackWidget,
      onError: onError,
      child: this,
    );
  }
}