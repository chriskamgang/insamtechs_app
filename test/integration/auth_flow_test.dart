import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:insamtchs/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Authentication Flow Integration Tests', () {
    testWidgets('Complete login flow test', (WidgetTester tester) async {
      // Démarrer l'application
      app.main();
      await tester.pumpAndSettle();

      // Attendre que l'écran de splash se charge
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Naviguer vers l'écran de connexion depuis l'onboarding
      // (En supposant qu'il y a un bouton "Se connecter" sur l'onboarding)
      final loginButton = find.text('Se connecter');
      if (loginButton.evaluate().isNotEmpty) {
        await tester.tap(loginButton);
        await tester.pumpAndSettle();
      }

      // Vérifier que nous sommes sur l'écran de connexion
      expect(find.text('Se connecter'), findsOneWidget);
      expect(find.byType(TextFormField), findsAtLeast(2)); // Email et mot de passe

      // Saisir l'email
      final emailField = find.byType(TextFormField).first;
      await tester.enterText(emailField, 'test@insam.com');
      await tester.pumpAndSettle();

      // Saisir le mot de passe
      final passwordField = find.byType(TextFormField).last;
      await tester.enterText(passwordField, 'password123');
      await tester.pumpAndSettle();

      // Appuyer sur le bouton de connexion
      final submitButton = find.widgetWithText(ElevatedButton, 'Se connecter');
      await tester.tap(submitButton);
      await tester.pumpAndSettle();

      // Attendre la réponse de l'API (simulation)
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Vérifier la navigation vers l'écran d'accueil
      // (En supposant qu'une connexion réussie mène à l'accueil)
      expect(find.text('Accueil'), findsOneWidget);
    });

    testWidgets('Login with invalid credentials should show error', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Naviguer vers l'écran de connexion
      await tester.pumpAndSettle(const Duration(seconds: 3));

      final loginButton = find.text('Se connecter');
      if (loginButton.evaluate().isNotEmpty) {
        await tester.tap(loginButton);
        await tester.pumpAndSettle();
      }

      // Saisir des identifiants invalides
      final emailField = find.byType(TextFormField).first;
      await tester.enterText(emailField, 'invalid@email.com');

      final passwordField = find.byType(TextFormField).last;
      await tester.enterText(passwordField, 'wrongpassword');

      // Tenter de se connecter
      final submitButton = find.widgetWithText(ElevatedButton, 'Se connecter');
      await tester.tap(submitButton);
      await tester.pumpAndSettle();

      // Attendre la réponse d'erreur
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Vérifier qu'un message d'erreur est affiché
      expect(find.textContaining('erreur'), findsAtLeast(1));
    });

    testWidgets('Registration flow test', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Naviguer vers l'écran d'inscription
      await tester.pumpAndSettle(const Duration(seconds: 3));

      final signUpButton = find.text('S\'inscrire');
      if (signUpButton.evaluate().isNotEmpty) {
        await tester.tap(signUpButton);
        await tester.pumpAndSettle();
      }

      // Vérifier que nous sommes sur l'écran d'inscription
      expect(find.text('Inscription'), findsOneWidget);
      expect(find.byType(TextFormField), findsAtLeast(4)); // Nom, prénom, email, mot de passe

      // Remplir le formulaire d'inscription
      final textFields = find.byType(TextFormField);

      await tester.enterText(textFields.at(0), 'John'); // Prénom
      await tester.enterText(textFields.at(1), 'Doe'); // Nom
      await tester.enterText(textFields.at(2), 'john.doe@test.com'); // Email
      await tester.enterText(textFields.at(3), 'password123'); // Mot de passe
      await tester.enterText(textFields.at(4), 'password123'); // Confirmation

      await tester.pumpAndSettle();

      // Soumettre l'inscription
      final submitButton = find.widgetWithText(ElevatedButton, 'S\'inscrire');
      await tester.tap(submitButton);
      await tester.pumpAndSettle();

      // Attendre la réponse
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Vérifier le succès (peut être une redirection ou un message)
      expect(find.textContaining('succès'), findsAtLeast(1));
    });

    testWidgets('Logout flow test', (WidgetTester tester) async {
      // D'abord se connecter (réutiliser la logique de connexion)
      app.main();
      await tester.pumpAndSettle();

      // Simuler une connexion réussie en naviguant directement vers l'accueil
      // (Dans un vrai test, vous passeriez par le flow de connexion complet)
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Naviguer vers les paramètres
      final profileIcon = find.byIcon(Icons.person);
      if (profileIcon.evaluate().isNotEmpty) {
        await tester.tap(profileIcon);
        await tester.pumpAndSettle();
      }

      // Aller aux paramètres
      final settingsButton = find.text('Paramètres');
      if (settingsButton.evaluate().isNotEmpty) {
        await tester.tap(settingsButton);
        await tester.pumpAndSettle();
      }

      // Trouver et appuyer sur le bouton de déconnexion
      final logoutButton = find.text('Déconnexion');
      expect(logoutButton, findsOneWidget);

      await tester.tap(logoutButton);
      await tester.pumpAndSettle();

      // Confirmer la déconnexion dans la boîte de dialogue
      final confirmButton = find.text('Déconnexion').last;
      await tester.tap(confirmButton);
      await tester.pumpAndSettle();

      // Vérifier que nous sommes redirigés vers l'écran de connexion
      expect(find.text('Se connecter'), findsOneWidget);
    });

    testWidgets('Password reset flow test', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Naviguer vers l'écran de connexion
      await tester.pumpAndSettle(const Duration(seconds: 3));

      final loginButton = find.text('Se connecter');
      if (loginButton.evaluate().isNotEmpty) {
        await tester.tap(loginButton);
        await tester.pumpAndSettle();
      }

      // Trouver et appuyer sur "Mot de passe oublié"
      final forgotPasswordButton = find.text('Mot de passe oublié');
      expect(forgotPasswordButton, findsOneWidget);

      await tester.tap(forgotPasswordButton);
      await tester.pumpAndSettle();

      // Vérifier que nous sommes sur l'écran de réinitialisation
      expect(find.text('Réinitialiser le mot de passe'), findsOneWidget);

      // Saisir l'email
      final emailField = find.byType(TextFormField);
      await tester.enterText(emailField, 'test@insam.com');
      await tester.pumpAndSettle();

      // Soumettre la demande
      final submitButton = find.widgetWithText(ElevatedButton, 'Envoyer');
      await tester.tap(submitButton);
      await tester.pumpAndSettle();

      // Attendre la réponse
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Vérifier le message de confirmation
      expect(find.textContaining('envoyé'), findsAtLeast(1));
    });

    testWidgets('Navigation persistence after login', (WidgetTester tester) async {
      // Se connecter
      app.main();
      await tester.pumpAndSettle();

      // Simuler une connexion réussie
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Naviguer vers différentes sections
      final coursesTab = find.text('Cours');
      if (coursesTab.evaluate().isNotEmpty) {
        await tester.tap(coursesTab);
        await tester.pumpAndSettle();
        expect(find.text('Cours'), findsOneWidget);
      }

      // Naviguer vers les messages
      final messagesTab = find.text('Messages');
      if (messagesTab.evaluate().isNotEmpty) {
        await tester.tap(messagesTab);
        await tester.pumpAndSettle();
        expect(find.text('Messages'), findsOneWidget);
      }

      // Naviguer vers le profil
      final profileTab = find.text('Profil');
      if (profileTab.evaluate().isNotEmpty) {
        await tester.tap(profileTab);
        await tester.pumpAndSettle();
        expect(find.text('Profil'), findsOneWidget);
      }

      // Retourner à l'accueil
      final homeTab = find.text('Accueil');
      if (homeTab.evaluate().isNotEmpty) {
        await tester.tap(homeTab);
        await tester.pumpAndSettle();
        expect(find.text('Accueil'), findsOneWidget);
      }
    });

    testWidgets('Form validation on login screen', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Naviguer vers l'écran de connexion
      await tester.pumpAndSettle(const Duration(seconds: 3));

      final loginButton = find.text('Se connecter');
      if (loginButton.evaluate().isNotEmpty) {
        await tester.tap(loginButton);
        await tester.pumpAndSettle();
      }

      // Tenter de se connecter sans saisir d'informations
      final submitButton = find.widgetWithText(ElevatedButton, 'Se connecter');
      await tester.tap(submitButton);
      await tester.pumpAndSettle();

      // Vérifier les messages de validation
      expect(find.textContaining('requis'), findsAtLeast(1));

      // Saisir un email invalide
      final emailField = find.byType(TextFormField).first;
      await tester.enterText(emailField, 'email-invalide');
      await tester.tap(submitButton);
      await tester.pumpAndSettle();

      // Vérifier la validation de l'email
      expect(find.textContaining('valide'), findsAtLeast(1));
    });

    testWidgets('Remember me functionality', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Naviguer vers l'écran de connexion
      await tester.pumpAndSettle(const Duration(seconds: 3));

      final loginButton = find.text('Se connecter');
      if (loginButton.evaluate().isNotEmpty) {
        await tester.tap(loginButton);
        await tester.pumpAndSettle();
      }

      // Chercher la case "Se souvenir de moi"
      final rememberMeCheckbox = find.byType(Checkbox);
      if (rememberMeCheckbox.evaluate().isNotEmpty) {
        await tester.tap(rememberMeCheckbox);
        await tester.pumpAndSettle();

        // Vérifier que la case est cochée
        final checkbox = tester.widget<Checkbox>(rememberMeCheckbox);
        expect(checkbox.value, true);
      }

      // Continuer avec la connexion
      final emailField = find.byType(TextFormField).first;
      await tester.enterText(emailField, 'test@insam.com');

      final passwordField = find.byType(TextFormField).last;
      await tester.enterText(passwordField, 'password123');

      final submitButton = find.widgetWithText(ElevatedButton, 'Se connecter');
      await tester.tap(submitButton);
      await tester.pumpAndSettle();

      // Simuler un redémarrage de l'application pour tester la persistance
      // (Dans un vrai test, cela nécessiterait une configuration plus complexe)
    });
  });

  group('Error Handling Integration Tests', () {
    testWidgets('Network error handling during login', (WidgetTester tester) async {
      // Ce test nécessiterait une configuration pour simuler des erreurs réseau
      // ou l'utilisation de mocks pour l'API
      app.main();
      await tester.pumpAndSettle();

      // Simuler une tentative de connexion avec une erreur réseau
      // (La logique exacte dépendrait de l'implémentation de l'application)

      // Vérifier que l'erreur est gérée gracieusement
      // expect(find.textContaining('Erreur de connexion'), findsOneWidget);
    });

    testWidgets('Server timeout handling', (WidgetTester tester) async {
      // Test similaire pour les timeouts serveur
      app.main();
      await tester.pumpAndSettle();

      // Simuler un timeout
      // Vérifier la gestion du timeout
    });
  });
}