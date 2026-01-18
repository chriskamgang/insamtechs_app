import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'config/environment.dart';
import 'services/api_service.dart';
import 'providers/auth_provider.dart';
import 'providers/course_provider.dart';
import 'providers/enrollment_provider.dart';
import 'providers/user_provider.dart';
import 'providers/analytics_provider.dart';
import 'providers/wishlist_provider.dart';
import 'providers/video_provider.dart';
import 'providers/library_provider.dart';
import 'providers/exam_provider.dart';
import 'providers/order_provider.dart';
import 'providers/message_provider.dart';
import 'providers/language_provider.dart';
// import 'services/notification_service.dart'; // Temporarily disabled
import 'screens/splash_screen.dart';
import 'screens/onboarding_screen_01.dart';
import 'screens/onboarding_screen_02.dart';
import 'screens/onboarding_screen_03.dart';
import 'screens/onboarding_screen_04.dart';
import 'screens/onboarding_screen_05.dart';
import 'screens/sign_in_screen.dart';
import 'screens/sign_up_screen.dart';
import 'screens/reset_password_screen.dart';
import 'screens/reset_password_done_screen.dart';
import 'screens/home_screen.dart';
import 'screens/courses_screen.dart';
import 'screens/messages_screen.dart';
import 'screens/notifications_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/course_detail_screen.dart';
import 'screens/get_enroll_1_screen.dart';
import 'screens/get_enroll_2_screen.dart';
import 'screens/get_enroll_3_screen.dart';
import 'screens/get_enroll_4_screen.dart';
import 'screens/edit_profile_screen.dart';
import 'screens/my_courses_screen.dart';
import 'screens/wishlist_screen.dart';
import 'screens/video_library_screen.dart';
import 'screens/video_player_screen.dart';
import 'screens/video_history_screen.dart';
import 'screens/enhanced_video_player_screen.dart';
import 'screens/video_category_screen.dart';
import 'screens/digital_library_screen.dart';
import 'screens/library_screen.dart';
import 'screens/books_category_screen.dart';
import 'screens/fascicules_category_screen.dart';
import 'screens/fascicules_series_screen.dart';
import 'screens/fascicules_categories_screen.dart';
import 'screens/pdf_viewer_screen.dart';
import 'screens/downloads_screen.dart';
import 'screens/exam_detail_screen.dart';
import 'screens/exam_taking_screen.dart';
import 'screens/exam_result_screen.dart';
import 'screens/certificate_screen.dart';
import 'screens/my_certificates_screen.dart';
import 'screens/qr_generator_screen.dart';
import 'screens/qr_scanner_screen.dart';
import 'screens/export_data_screen.dart';
import 'screens/my_orders_screen.dart';
import 'screens/google_drive_video_player.dart';
import 'screens/course_categories_screen.dart';
import 'screens/course_by_category_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Configure environment
  EnvironmentConfig.setEnvironment(Environment.production);

  // Initialize API service
  await ApiService().initialize();

  // Initialize notification service (temporarily disabled)
  // try {
  //   await NotificationService().initialize();
  // } catch (e) {
  //   print('Warning: Could not initialize notification service: $e');
  // }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()..initialize()),
        ChangeNotifierProvider(create: (_) => CourseProvider()..initialize()),
        ChangeNotifierProvider(create: (_) => EnrollmentProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => AnalyticsProvider()),
        ChangeNotifierProvider(create: (_) => WishlistProvider()),
        ChangeNotifierProvider(create: (_) => VideoProvider()),
        ChangeNotifierProvider(create: (_) => LibraryProvider()),
        ChangeNotifierProvider(create: (_) => ExamProvider()),
        ChangeNotifierProvider(create: (_) => OrderProvider()),
        ChangeNotifierProvider(create: (_) => MessageProvider()),
        ChangeNotifierProvider(create: (_) => LanguageProvider()),
      ],
      child: Consumer<LanguageProvider>(
        builder: (context, languageProvider, child) {
          return MaterialApp(
            title: 'INSAM LMS',
            debugShowCheckedModeBanner: false,
            locale: const Locale('fr'),
            localizationsDelegates: [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: [
              const Locale('fr'),
              const Locale('en'),
            ],
            theme: ThemeData(
              primarySwatch: Colors.blue,
              primaryColor: const Color(0xFF1E3A8A),
              colorScheme: ColorScheme.fromSeed(
                seedColor: const Color(0xFF1E3A8A),
                primary: const Color(0xFF1E3A8A),
                secondary: const Color(0xFF3B82F6),
              ),
              useMaterial3: true,
              fontFamily: 'Roboto',
            ),
            home: const SplashScreen(),
            routes: {
              '/splash': (context) => const SplashScreen(),
              '/onboarding1': (context) => const OnboardingScreen01(),
              '/onboarding2': (context) => const OnboardingScreen02(),
              '/onboarding3': (context) => const OnboardingScreen03(),
              '/onboarding4': (context) => const OnboardingScreen04(),
              '/onboarding5': (context) => const OnboardingScreen05(),
              '/signin': (context) => const SignInScreen(),
              '/reset-password': (context) => const ResetPasswordScreen(),
              '/reset-password-done': (context) => const ResetPasswordDoneScreen(),
              '/signup': (context) => const SignUpScreen(),
              '/home': (context) => const HomeScreen(),
              '/courses': (context) => const CoursesScreen(),
              '/messages': (context) => const MessagesScreen(),
              '/notifications': (context) => const NotificationsScreen(),
              '/profile': (context) => const ProfileScreen(),
              '/settings': (context) => const SettingsScreen(),
              '/course-detail': (context) {
                final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
                return CourseDetailScreen(
                  courseTitle: args?['courseTitle'] ?? 'Cours',
                  instructor: args?['instructor'] ?? 'Instructeur',
                  rating: args?['rating'] ?? 5.0,
                  price: args?['price'] ?? '0',
                  description: args?['description'] ?? '',
                  slug: args?['slug'],
                );
              },
              '/get-enroll-1': (context) => const GetEnroll1Screen(),
              '/get-enroll-2': (context) => const GetEnroll2Screen(),
              '/get-enroll-3': (context) => const GetEnroll3Screen(),
              '/get-enroll-4': (context) => const GetEnroll4Screen(),
              '/edit-profile': (context) => const EditProfileScreen(),
              '/my-courses': (context) => const MyCoursesScreen(),
              '/wishlist': (context) => const WishlistScreen(),
              '/video-library': (context) => const VideoLibraryScreen(),
              '/video-player': (context) {
                final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
                // Vérifier si la vidéo provient de Google Drive
                final video = args?['video'] ?? {};
                final videoUrl = video['lien'] ?? video.url;

                if (videoUrl != null && videoUrl.contains('drive.google.com')) {
                  return GoogleDriveVideoPlayer(
                    video: video,
                    title: args?['title'] ?? 'Vidéo',
                  );
                } else {
                  return VideoPlayerScreen(
                    video: video,
                    title: args?['title'] ?? 'Vidéo',
                  );
                }
              },
              '/enhanced-video-player': (context) {
                final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
                // Vérifier si la vidéo provient de Google Drive
                final video = args?['video'] ?? {};
                final videoUrl = video['lien'] ?? video.url;

                if (videoUrl != null && videoUrl.contains('drive.google.com')) {
                  return GoogleDriveVideoPlayer(
                    video: video,
                    title: args?['title'] ?? 'Vidéo',
                  );
                } else {
                  return EnhancedVideoPlayerScreen(
                    video: video,
                    title: args?['title'] ?? 'Vidéo',
                  );
                }
              },
              '/video-history': (context) => const VideoHistoryScreen(),
              '/video-category': (context) {
                final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
                return VideoCategoryScreen(
                  slug: args?['slug'] ?? '',
                  title: args?['title'] ?? 'Catégorie',
                );
              },
              '/courses-categories': (context) => CourseCategoriesScreen(),
              '/courses-by-category': (context) {
                final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
                return CourseByCategoryScreen(
                  slug: args?['slug'] ?? '',
                  title: args?['title'] ?? 'Cours',
                );
              },
              '/library': (context) => const LibraryScreen(),
              '/digital-library': (context) => const DigitalLibraryScreen(),
              '/books-category': (context) {
                final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
                return BooksCategoryScreen(
                  slug: args?['slug'] ?? '',
                  title: args?['title'] ?? 'Livres',
                );
              },
              '/fascicules-series': (context) {
                final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
                return FasciculesSeriesScreen(
                  slug: args?['slug'] ?? '',
                  title: args?['title'] ?? 'Séries',
                );
              },
              '/fascicules-categories': (context) {
                final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
                return FasciculesCategoriesScreen(
                  slug: args?['slug'] ?? '',
                  title: args?['title'] ?? 'Catégories',
                );
              },
              '/fascicules-category': (context) {
                final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
                return FasciculesCategoryScreen(
                  slug: args?['slug'] ?? '',
                  title: args?['title'] ?? 'Fascicules',
                );
              },
              '/pdf-viewer': (context) {
                final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
                return PDFViewerScreen(
                  url: args?['url'] ?? '',
                  title: args?['title'] ?? 'Document PDF',
                );
              },
              '/downloads': (context) => const DownloadsScreen(),
              '/exam-detail': (context) {
                final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
                return ExamDetailScreen(
                  formationId: args?['formationId'] ?? 0,
                  formationTitle: args?['formationTitle'] ?? 'Formation',
                );
              },
              '/exam-taking': (context) {
                final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
                return ExamTakingScreen(
                  formationId: args?['formationId'] ?? 0,
                  formationTitle: args?['formationTitle'] ?? 'Formation',
                );
              },
              '/exam-result': (context) {
                final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
                return ExamResultScreen(
                  tentativeId: args?['tentativeId'] ?? 0,
                  formationTitle: args?['formationTitle'] ?? 'Formation',
                );
              },
              '/certificate': (context) {
                final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
                return CertificateScreen(
                  tentativeId: args?['tentativeId'] ?? 0,
                  formationTitle: args?['formationTitle'] ?? 'Formation',
                );
              },
              '/my-certificates': (context) => const MyCertificatesScreen(),
              '/qr-generator': (context) {
                final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
                return QRGeneratorScreen(
                  courseSlug: args?['courseSlug'] ?? '',
                  courseTitle: args?['courseTitle'] ?? 'Cours',
                  instructorName: args?['instructorName'] ?? 'Instructeur',
                  price: args?['price'],
                );
              },
              '/qr-scanner': (context) => const QRScannerScreen(),
              '/export-data': (context) => const ExportDataScreen(),
              '/my-orders': (context) => _buildMyOrdersScreen(context),
            },
          );
        },
      ),
    );
  }

  static Widget _buildMyOrdersScreen(BuildContext context) {
    return MyOrdersScreen();
  }
}