# 📋 Système de Logging INSAMTCHS

Ce document explique comment utiliser le système de logging centralisé implémenté dans l'application Flutter INSAMTCHS.

## 🎯 Vue d'ensemble

Le système de logging permet de tracer :
- ✅ Actions utilisateur (clics, gestes, formulaires)
- ✅ Navigation entre écrans
- ✅ Appels API et réponses
- ✅ Changements d'état des providers
- ✅ Erreurs et exceptions
- ✅ Performances et timings

## 📁 Structure des fichiers

```
lib/
├── services/
│   ├── logger_service.dart            # Service principal de logging
│   ├── navigation_service.dart        # Navigation avec logs automatiques
│   └── http_logging_interceptor.dart  # Intercepteur HTTP pour Dio
├── utils/
│   └── logging_mixin.dart            # Mixin pour les providers
└── widgets/
    └── error_boundary_widget.dart    # Capture d'erreurs avec logs
```

## 🚀 Utilisation rapide

### 1. Logging basique dans un widget

```dart
import '../services/logger_service.dart';

class MyWidget extends StatefulWidget with LoggingMixin {
  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () {
        // Log d'action utilisateur
        logger.logUserGesture('tap', 'submit_button', screen: 'MyWidget', data: {
          'formValid': true,
          'userId': currentUserId,
        });

        // Action du bouton...
      },
      child: Text('Envoyer'),
    );
  }
}
```

### 2. Logging dans un provider

```dart
import '../utils/logging_mixin.dart';

class MyProvider extends ChangeNotifier with LoggingMixin {
  Future<void> loadData() async {
    logProviderInfo('Starting data load');
    logProviderStateChange('idle', 'loading');

    try {
      final data = await apiService.getData();
      logProviderSuccess('Data loaded successfully', data: {
        'itemCount': data.length,
      });
      logProviderStateChange('loading', 'loaded');
    } catch (e) {
      logProviderError('loadData', e);
      logProviderStateChange('loading', 'error');
    }
  }
}
```

### 3. Navigation avec logs automatiques

```dart
import '../services/navigation_service.dart';

// Au lieu de Navigator.pushNamed
NavigationService.instance.pushNamed(
  context,
  '/course-detail',
  arguments: {'courseId': 123},
  fromScreen: 'CourseList',
);

// Au lieu de Navigator.pop
NavigationService.instance.pop(context, result: 'completed');
```

### 4. Protection contre les erreurs

```dart
import '../widgets/error_boundary_widget.dart';

class MyScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: MyContent().withErrorBoundary(
        screenName: 'MyScreen',
        onError: (error, stackTrace) {
          // Action personnalisée en cas d'erreur
        },
      ),
    );
  }
}
```

## 📊 Types de logs disponibles

### Niveaux de logs
- `DEBUG` 🔍 - Informations de débogage
- `INFO` 💡 - Informations générales
- `WARNING` ⚠️ - Avertissements
- `ERROR` ❌ - Erreurs
- `SUCCESS` ✅ - Opérations réussies
- `NAVIGATION` 🧭 - Navigation entre écrans
- `USER_ACTION` 👤 - Actions utilisateur
- `API_CALL` 🌐 - Appels API
- `STATE_CHANGE` 🔄 - Changements d'état

### Méthodes principales

```dart
final logger = LoggerService.instance;

// Logs généraux
logger.logInfo('Message info', screen: 'ScreenName', data: {...});
logger.logError('Message erreur', error: exception, stackTrace: trace);
logger.logSuccess('Opération réussie', data: {...});
logger.logWarning('Attention', data: {...});

// Logs spécialisés
logger.logUserAction('button_click', screen: 'ScreenName', data: {...});
logger.logNavigation('FromScreen', 'ToScreen', arguments: {...});
logger.logStateChange('Component', 'oldState', 'newState');
logger.logApiCall('POST', '/api/endpoint', requestData: {...}, statusCode: 200);
```

## 🔧 Configuration

### 1. Intercepteur HTTP (dans votre service API)

```dart
import 'package:dio/dio.dart';
import '../services/http_logging_interceptor.dart';

final dio = Dio();
dio.interceptors.add(HttpLoggingInterceptor());
```

### 2. Gestion globale des erreurs (dans main.dart)

```dart
import 'package:flutter/material.dart';
import 'services/logger_service.dart';

void main() {
  // Capture les erreurs Flutter non gérées
  FlutterError.onError = (FlutterErrorDetails details) {
    LoggerService.instance.logError(
      'Flutter Error',
      error: details.exception,
      stackTrace: details.stack,
    );
  };

  runApp(MyApp());
}
```

## 📋 Format des logs

Les logs apparaissent dans la console avec le format suivant :

```
[2024-01-15T10:30:45.123Z] 👤 [INSAMTCHS] [CourseDetailScreen] [tap] - User tapped enrollment_button
📊 Data: {isEnrolled: false, courseId: 123, buttonAction: enroll}
```

### Structure d'un log :
- `[Timestamp]` - Horodatage ISO 8601
- `[Emoji]` - Emoji correspondant au type de log
- `[INSAMTCHS]` - Tag de l'application
- `[ScreenName]` - Nom de l'écran (optionnel)
- `[Action]` - Nom de l'action (optionnel)
- `Message` - Description de l'événement
- `📊 Data:` - Données contextuelles (optionnel)

## 🎯 Bonnes pratiques

### 1. Nommage des écrans
```dart
// ✅ Bon
logger.logScreenStart('CourseDetailScreen');

// ❌ Éviter
logger.logScreenStart('course_detail');
```

### 2. Données contextuelles
```dart
// ✅ Inclure des données utiles
logger.logUserAction('form_submit', screen: 'SignupScreen', data: {
  'email': email,
  'hasProfilePicture': profilePicture != null,
  'referralCode': referralCode,
});

// ❌ Éviter les données sensibles
logger.logUserAction('login', data: {
  'password': password, // ❌ NE PAS FAIRE
});
```

### 3. Gestion des erreurs
```dart
// ✅ Log complet avec contexte
try {
  await operation();
} catch (e, stackTrace) {
  logger.logError(
    'Failed to complete operation',
    screen: 'CurrentScreen',
    error: e,
    stackTrace: stackTrace,
    data: {'operationId': operationId},
  );
}
```

## 🔍 Debugging

### Voir les logs en développement
Les logs apparaissent automatiquement dans :
- Console Flutter/Dart
- Debug console de votre IDE
- Logs système (via `flutter logs`)

### Filtrage des logs
```bash
# Voir seulement les logs de l'app
flutter logs | grep INSAMTCHS

# Voir seulement les erreurs
flutter logs | grep "❌"

# Voir les actions utilisateur
flutter logs | grep "👤"
```

## 📈 Métriques et analytics

Le système de logging peut être étendu pour inclure :
- Envoi vers des services d'analytics (Firebase, Amplitude, etc.)
- Stockage local pour les logs offline
- Agrégation de métriques de performance
- Rapports d'erreurs automatiques

## 🚨 Sécurité

- ❌ Ne jamais logger de mots de passe
- ❌ Ne jamais logger de tokens d'authentification
- ❌ Ne jamais logger de données personnelles sensibles
- ✅ Utiliser `[REDACTED]` pour les données sensibles
- ✅ Logger uniquement en mode debug pour les données sensibles

## 🔄 Migration des print() existants

```dart
// ❌ Ancien code
print('User clicked button');

// ✅ Nouveau code
logger.logUserGesture('tap', 'button_name', screen: 'ScreenName');
```

## 📚 Exemples d'usage complets

Voir le fichier `lib/screens/course_detail_screen.dart` pour un exemple complet d'intégration du système de logging dans un écran complexe.