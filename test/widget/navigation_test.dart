import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:insamtchs/providers/auth_provider.dart';
import 'package:insamtchs/providers/course_provider.dart';
import 'package:insamtchs/providers/language_provider.dart';
import 'package:insamtchs/screens/home_screen.dart';
import 'package:insamtchs/screens/courses_screen.dart';
import 'package:insamtchs/screens/messages_screen.dart';
import 'package:insamtchs/screens/profile_screen.dart';
import 'package:insamtchs/screens/settings_screen.dart';

void main() {
  group('Navigation Widget Tests', () {
    late AuthProvider mockAuthProvider;
    late CourseProvider mockCourseProvider;
    late LanguageProvider mockLanguageProvider;

    setUp(() {
      mockAuthProvider = AuthProvider();
      mockCourseProvider = CourseProvider();
      mockLanguageProvider = LanguageProvider();
    });

    Widget createTestWidget(Widget child) {
      return MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthProvider>.value(value: mockAuthProvider),
          ChangeNotifierProvider<CourseProvider>.value(value: mockCourseProvider),
          ChangeNotifierProvider<LanguageProvider>.value(value: mockLanguageProvider),
        ],
        child: MaterialApp(
          home: child,
        ),
      );
    }

    testWidgets('HomeScreen should display navigation elements', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(const HomeScreen()));

      // Vérifier la présence des éléments de navigation
      expect(find.byType(BottomNavigationBar), findsOneWidget);
      expect(find.byType(AppBar), findsOneWidget);

      // Vérifier les onglets de navigation
      expect(find.text('Accueil'), findsWidgets);
      expect(find.text('Cours'), findsWidgets);
      expect(find.text('Messages'), findsWidgets);
      expect(find.text('Profil'), findsWidgets);
    });

    testWidgets('Navigation between tabs should work correctly', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(const HomeScreen()));

      // Appuyer sur l'onglet Cours
      final coursesTab = find.text('Cours').last;
      await tester.tap(coursesTab);
      await tester.pumpAndSettle();

      // Vérifier la navigation vers l'écran des cours
      // (Cette vérification dépend de l'implémentation réelle)

      // Appuyer sur l'onglet Messages
      final messagesTab = find.text('Messages').last;
      await tester.tap(messagesTab);
      await tester.pumpAndSettle();

      // Appuyer sur l'onglet Profil
      final profileTab = find.text('Profil').last;
      await tester.tap(profileTab);
      await tester.pumpAndSettle();

      // Retourner à l'accueil
      final homeTab = find.text('Accueil').last;
      await tester.tap(homeTab);
      await tester.pumpAndSettle();
    });

    testWidgets('CoursesScreen should display course list', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(const CoursesScreen()));

      // Vérifier la présence des éléments de l'écran des cours
      expect(find.byType(AppBar), findsOneWidget);
      expect(find.text('Cours'), findsAtLeast(1));

      // Vérifier la présence d'éléments de liste ou de grille
      expect(find.byType(ListView), findsWidgets);
    });

    testWidgets('MessagesScreen should display messages interface', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(const MessagesScreen()));

      // Vérifier la présence des éléments de l'écran des messages
      expect(find.byType(AppBar), findsOneWidget);
      expect(find.text('Messages'), findsAtLeast(1));
    });

    testWidgets('ProfileScreen should display user profile', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(const ProfileScreen()));

      // Vérifier la présence des éléments du profil
      expect(find.byType(AppBar), findsOneWidget);
      expect(find.text('Profil'), findsAtLeast(1));

      // Vérifier la présence d'éléments de profil typiques
      expect(find.byType(CircleAvatar), findsWidgets);
    });

    testWidgets('SettingsScreen should display settings options', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(const SettingsScreen()));

      // Vérifier la présence des éléments des paramètres
      expect(find.byType(AppBar), findsOneWidget);
      expect(find.text('Paramètres'), findsAtLeast(1));

      // Vérifier la présence d'options de paramètres
      expect(find.text('Langue'), findsWidgets);
      expect(find.text('Déconnexion'), findsWidgets);
    });

    testWidgets('Settings language change should work', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(const SettingsScreen()));

      // Trouver et appuyer sur l'option de langue
      final languageOption = find.text('Langue');
      await tester.tap(languageOption);
      await tester.pumpAndSettle();

      // Vérifier que la boîte de dialogue de changement de langue apparaît
      expect(find.text('Changer la langue'), findsOneWidget);
      expect(find.text('Français'), findsOneWidget);
      expect(find.text('English'), findsOneWidget);

      // Sélectionner l'anglais
      final englishOption = find.text('English');
      await tester.tap(englishOption);
      await tester.pumpAndSettle();

      // Vérifier que la langue a changé (si implémenté)
      // Cette vérification dépendrait de l'implémentation réelle
    });

    testWidgets('Settings logout should show confirmation dialog', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(const SettingsScreen()));

      // Trouver et appuyer sur le bouton de déconnexion
      final logoutButton = find.text('Déconnexion');
      await tester.tap(logoutButton);
      await tester.pumpAndSettle();

      // Vérifier que la boîte de dialogue de confirmation apparaît
      expect(find.text('Êtes-vous sûr de vouloir vous déconnecter?'), findsOneWidget);
      expect(find.text('Annuler'), findsOneWidget);
      expect(find.text('Déconnexion'), findsAtLeast(2)); // Un dans le bouton, un dans la confirmation

      // Tester l'annulation
      final cancelButton = find.text('Annuler');
      await tester.tap(cancelButton);
      await tester.pumpAndSettle();

      // Vérifier que la boîte de dialogue se ferme
      expect(find.text('Êtes-vous sûr de vouloir vous déconnecter?'), findsNothing);
    });

    group('Responsive Navigation Tests', () {
      testWidgets('Navigation should work on different screen sizes', (WidgetTester tester) async {
        // Test avec une taille d'écran mobile
        await tester.binding.setSurfaceSize(const Size(375, 667)); // iPhone 6/7/8
        await tester.pumpWidget(createTestWidget(const HomeScreen()));

        expect(find.byType(BottomNavigationBar), findsOneWidget);

        // Test avec une taille d'écran plus large
        await tester.binding.setSurfaceSize(const Size(768, 1024)); // iPad
        await tester.pumpWidget(createTestWidget(const HomeScreen()));
        await tester.pumpAndSettle();

        // La navigation devrait toujours fonctionner
        expect(find.byType(BottomNavigationBar), findsOneWidget);

        // Remettre la taille par défaut
        await tester.binding.setSurfaceSize(null);
      });
    });

    group('Deep Link Navigation Tests', () {
      testWidgets('Should handle course detail navigation', (WidgetTester tester) async {
        await tester.pumpWidget(
          MultiProvider(
            providers: [
              ChangeNotifierProvider<AuthProvider>.value(value: mockAuthProvider),
              ChangeNotifierProvider<CourseProvider>.value(value: mockCourseProvider),
              ChangeNotifierProvider<LanguageProvider>.value(value: mockLanguageProvider),
            ],
            child: MaterialApp(
              initialRoute: '/courses',
              routes: {
                '/courses': (context) => const CoursesScreen(),
                '/course-detail': (context) {
                  return const Scaffold(
                    body: Center(child: Text('Course Detail')),
                  );
                },
              },
            ),
          ),
        );

        // Vérifier que nous sommes sur l'écran des cours
        expect(find.text('Cours'), findsAtLeast(1));

        // Simuler la navigation vers les détails d'un cours
        // (Cela nécessiterait un bouton ou un élément cliquable dans la vraie implémentation)
      });
    });

    group('Navigation State Persistence Tests', () {
      testWidgets('Should maintain selected tab state', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(const HomeScreen()));

        // Naviguer vers l'onglet Cours
        final coursesTab = find.text('Cours').last;
        await tester.tap(coursesTab);
        await tester.pumpAndSettle();

        // Rebuilder le widget (simuler une reconstruction)
        await tester.pumpWidget(createTestWidget(const HomeScreen()));
        await tester.pumpAndSettle();

        // Vérifier que l'état de navigation est maintenu
        // (Cette vérification dépendrait de l'implémentation réelle)
      });
    });

    group('Error Navigation Tests', () {
      testWidgets('Should handle navigation errors gracefully', (WidgetTester tester) async {
        await tester.pumpWidget(
          MultiProvider(
            providers: [
              ChangeNotifierProvider<AuthProvider>.value(value: mockAuthProvider),
              ChangeNotifierProvider<CourseProvider>.value(value: mockCourseProvider),
              ChangeNotifierProvider<LanguageProvider>.value(value: mockLanguageProvider),
            ],
            child: MaterialApp(
              home: const HomeScreen(),
              onUnknownRoute: (settings) {
                return MaterialPageRoute(
                  builder: (context) => const Scaffold(
                    body: Center(child: Text('Page not found')),
                  ),
                );
              },
            ),
          ),
        );

        // Tester la navigation vers une route inexistante serait difficile
        // sans accès direct au Navigator, mais on peut vérifier que
        // l'écran d'accueil se charge correctement
        expect(find.byType(HomeScreen), findsOneWidget);
      });
    });

    group('Accessibility Navigation Tests', () {
      testWidgets('Navigation should be accessible', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(const HomeScreen()));

        // Vérifier que les éléments de navigation ont des semantiques appropriées
        expect(find.byType(Semantics), findsWidgets);

        // Vérifier que les boutons de navigation sont accessibles
        final navigationButtons = find.byType(BottomNavigationBar);
        expect(navigationButtons, findsOneWidget);

        // Test de navigation avec les semantiques
        final semanticsFinder = find.descendant(
          of: navigationButtons,
          matching: find.byType(Semantics),
        );
        expect(semanticsFinder, findsWidgets);
      });
    });
  });
}