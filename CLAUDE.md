# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

INSAM LMS (Learning Management System) - A Flutter mobile application with a Laravel backend for educational content delivery. The app provides courses, video libraries, digital library access, exams, and certificates.

## Architecture

### Flutter Frontend (Mobile App)

**State Management:** Provider pattern

- All providers in `lib/providers/` extend `ChangeNotifier`
- Initialized in `main.dart` via `MultiProvider`
- Key providers: `AuthProvider`, `CourseProvider`, `VideoProvider`, `LibraryProvider`, `ExamProvider`, `WishlistProvider`

**Network Layer:**

- `lib/services/api_service.dart` - Singleton Dio HTTP client with interceptors
- Authentication via Bearer tokens stored in `flutter_secure_storage`
- Automatic token injection via auth interceptor
- 401 responses trigger automatic logout

**Configuration System:**

- `lib/config/environment.dart` - Environment-based configuration (development/staging/production)
- `lib/config/backend_config.dart` - Backend IP/port configuration (change `BACKEND_IP` constant to point to your local backend)
- `lib/config/api_config.dart` - API endpoint definitions
- Default environment: `Environment.production` (set in `main.dart`)

**Models:**

- JSON serialization via `json_serializable` package
- Models in `lib/models/` with corresponding `.g.dart` generated files
- Key models: `Course`, `Chapter`, `User`, `Enrollment`, `Message`, `Order`, `LibraryItem`

**Routing:**

- Named routes defined in `main.dart` (lines 135-302)
- Route arguments passed via `ModalRoute.of(context)?.settings.arguments`

### Laravel Backend

Location: `insamtechs_backend/`

- Standard Laravel structure with API routes in `routes/`
- Controllers in `app/Http/Controllers/`
- Models in `app/Models/`
- Backend runs on configurable IP:port (default: `192.168.1.196:8001`)

## Common Development Commands

### Flutter App Development

**Initial Setup:**

```bash
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
```

**Running the App:**

```bash
# Run on connected device/simulator
flutter run

# Run with specific device
flutter devices
flutter run -d <device_id>

# Clean and rebuild
flutter clean
flutter pub get
flutter run
```

**Code Generation (for JSON serialization):**

```bash
# One-time build
flutter pub run build_runner build --delete-conflicting-outputs

# Watch mode (rebuilds on file changes)
flutter pub run build_runner watch --delete-conflicting-outputs
```

**Linting and Analysis:**

```bash
flutter analyze
```

**Testing:**

```bash
# Run all tests
flutter test

# Run specific test file
flutter test test/services/api_service_test.dart
```

### Backend Development

**Laravel Commands:**

```bash
cd insamtechs_backend

# Start development server
php artisan serve --host=0.0.0.0 --port=8001

# Run migrations
php artisan migrate

# Clear cache
php artisan cache:clear
php artisan config:clear
php artisan route:clear
```

## Key Integration Points

### Backend IP Configuration

To connect the Flutter app to your local backend:

1. Find your local IP address (run `ifconfig` on Mac/Linux or `ipconfig` on Windows)
2. Update `BACKEND_IP` in `lib/config/backend_config.dart`
3. Ensure backend is running: `cd insamtechs_backend && php artisan serve --host=0.0.0.0 --port=8001`
4. Restart Flutter app

### Authentication Flow

1. User login via `AuthService.login()` → stores token in secure storage
2. `ApiService` automatically loads token on initialization
3. Auth interceptor injects token into all API requests
4. 401 responses trigger `clearToken()` and redirect to login

### Video Playback

- Google Drive videos → `GoogleDriveVideoPlayer` (WebView-based)
- Direct video URLs → `VideoPlayerScreen` or `EnhancedVideoPlayerScreen` (video_player + chewie)
- Route detection in `main.dart` lines 176-206

### Digital Library

- Three content types: Books, Fascicules (in series), and Categories
- PDFs opened via `PDFViewerScreen` using WebView
- Library items fetched via `LibraryService` and managed by `LibraryProvider`

## Important Files

- `lib/main.dart` - App entry point, provider setup, routing configuration
- `lib/config/environment.dart` - Environment switching
- `lib/config/backend_config.dart` - Backend IP configuration (modify this frequently)
- `lib/services/api_service.dart` - HTTP client singleton with interceptors
- `lib/models/*.dart` - Data models (run code generation after modifying)
- `UI_IMPLEMENTATION_CHECKLIST.md` - Current implementation status (79.2% complete)

## Development Notes

- Firebase messaging and local notifications are installed but currently disabled in code (commented out in `main.dart`)
- App targets French (`fr`) as primary locale
- Default timeout: 300 seconds in development (5 minutes) for slow connections
- JSON serialization requires running build_runner after model changes
- Secure storage used for tokens; SharedPreferences for non-sensitive data
- Provider pattern: always call `notifyListeners()` after state changes
