import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:insamtchs/services/api_service.dart';
import 'package:insamtchs/config/environment.dart';

// Générer les mocks avec build_runner
@GenerateMocks([Dio])
import 'api_service_test.mocks.dart';

void main() {
  group('ApiService Tests', () {
    late ApiService apiService;
    late MockDio mockDio;

    setUp(() {
      mockDio = MockDio();
      apiService = ApiService();
      // Remplacer le Dio réel par le mock
      apiService.dio = mockDio;
    });

    group('Authentication Tests', () {
      test('login should return user data on success', () async {
        // Arrange
        const email = 'test@example.com';
        const password = 'password123';
        final expectedResponse = Response(
          data: {
            'success': true,
            'user': {
              'id': 1,
              'nom': 'Doe',
              'prenom': 'John',
              'email': email,
            },
            'token': 'fake_token_123',
          },
          statusCode: 200,
          requestOptions: RequestOptions(path: '/login'),
        );

        when(mockDio.post(
          '/login',
          data: {'email': email, 'password': password},
        )).thenAnswer((_) async => expectedResponse);

        // Act
        final result = await apiService.login(email, password);

        // Assert
        expect(result['success'], true);
        expect(result['user']['email'], email);
        expect(result['token'], 'fake_token_123');
        verify(mockDio.post(
          '/login',
          data: {'email': email, 'password': password},
        )).called(1);
      });

      test('login should throw exception on invalid credentials', () async {
        // Arrange
        const email = 'wrong@example.com';
        const password = 'wrongpassword';

        when(mockDio.post(
          '/login',
          data: {'email': email, 'password': password},
        )).thenThrow(DioException(
          requestOptions: RequestOptions(path: '/login'),
          response: Response(
            statusCode: 401,
            data: {'message': 'Invalid credentials'},
            requestOptions: RequestOptions(path: '/login'),
          ),
        ));

        // Act & Assert
        expect(
          () => apiService.login(email, password),
          throwsA(isA<Exception>()),
        );
      });

      test('register should create new user successfully', () async {
        // Arrange
        final userData = {
          'nom': 'Doe',
          'prenom': 'Jane',
          'email': 'jane@example.com',
          'password': 'password123',
          'password_confirmation': 'password123',
        };

        final expectedResponse = Response(
          data: {
            'success': true,
            'user': {
              'id': 2,
              'nom': 'Doe',
              'prenom': 'Jane',
              'email': 'jane@example.com',
            },
            'message': 'User created successfully',
          },
          statusCode: 201,
          requestOptions: RequestOptions(path: '/register'),
        );

        when(mockDio.post('/register', data: userData))
            .thenAnswer((_) async => expectedResponse);

        // Act
        final result = await apiService.register(userData);

        // Assert
        expect(result['success'], true);
        expect(result['user']['email'], 'jane@example.com');
        verify(mockDio.post('/register', data: userData)).called(1);
      });
    });

    group('Courses Tests', () {
      test('getCourses should return list of courses', () async {
        // Arrange
        final expectedResponse = Response(
          data: {
            'success': true,
            'data': [
              {
                'id': 1,
                'titre': 'Introduction à Flutter',
                'description': 'Cours d\'introduction',
                'instructeur': 'John Doe',
                'prix': '0',
              },
              {
                'id': 2,
                'titre': 'React Avancé',
                'description': 'Cours avancé',
                'instructeur': 'Jane Smith',
                'prix': '50000',
              },
            ],
          },
          statusCode: 200,
          requestOptions: RequestOptions(path: '/courses'),
        );

        when(mockDio.get('/courses')).thenAnswer((_) async => expectedResponse);

        // Act
        final result = await apiService.getCourses();

        // Assert
        expect(result['success'], true);
        expect(result['data'], isA<List>());
        expect(result['data'].length, 2);
        expect(result['data'][0]['titre'], 'Introduction à Flutter');
        verify(mockDio.get('/courses')).called(1);
      });

      test('getCourseDetails should return specific course data', () async {
        // Arrange
        const courseSlug = 'flutter-intro';
        final expectedResponse = Response(
          data: {
            'success': true,
            'data': {
              'id': 1,
              'titre': 'Introduction à Flutter',
              'description': 'Cours complet d\'introduction à Flutter',
              'instructeur': 'John Doe',
              'slug': courseSlug,
              'modules': [
                {'id': 1, 'titre': 'Installation'},
                {'id': 2, 'titre': 'Premier projet'},
              ],
            },
          },
          statusCode: 200,
          requestOptions: RequestOptions(path: '/courses/$courseSlug'),
        );

        when(mockDio.get('/courses/$courseSlug'))
            .thenAnswer((_) async => expectedResponse);

        // Act
        final result = await apiService.getCourseDetails(courseSlug);

        // Assert
        expect(result['success'], true);
        expect(result['data']['slug'], courseSlug);
        expect(result['data']['modules'], isA<List>());
        expect(result['data']['modules'].length, 2);
        verify(mockDio.get('/courses/$courseSlug')).called(1);
      });
    });

    group('Enrollment Tests', () {
      test('enrollInCourse should enroll user successfully', () async {
        // Arrange
        const courseId = 1;
        final expectedResponse = Response(
          data: {
            'success': true,
            'message': 'Inscription réussie',
            'enrollment': {
              'id': 1,
              'user_id': 1,
              'course_id': courseId,
              'enrolled_at': '2024-01-15T10:00:00Z',
            },
          },
          statusCode: 200,
          requestOptions: RequestOptions(path: '/enrollments'),
        );

        when(mockDio.post('/enrollments', data: {'course_id': courseId}))
            .thenAnswer((_) async => expectedResponse);

        // Act
        final result = await apiService.enrollInCourse(courseId);

        // Assert
        expect(result['success'], true);
        expect(result['enrollment']['course_id'], courseId);
        verify(mockDio.post('/enrollments', data: {'course_id': courseId}))
            .called(1);
      });

      test('getUserEnrollments should return user enrollments', () async {
        // Arrange
        final expectedResponse = Response(
          data: {
            'success': true,
            'data': [
              {
                'id': 1,
                'course': {
                  'id': 1,
                  'titre': 'Flutter Intro',
                },
                'progress': 75,
                'status': 'in_progress',
              },
              {
                'id': 2,
                'course': {
                  'id': 2,
                  'titre': 'React Avancé',
                },
                'progress': 100,
                'status': 'completed',
              },
            ],
          },
          statusCode: 200,
          requestOptions: RequestOptions(path: '/user/enrollments'),
        );

        when(mockDio.get('/user/enrollments'))
            .thenAnswer((_) async => expectedResponse);

        // Act
        final result = await apiService.getUserEnrollments();

        // Assert
        expect(result['success'], true);
        expect(result['data'], isA<List>());
        expect(result['data'].length, 2);
        expect(result['data'][0]['progress'], 75);
        expect(result['data'][1]['status'], 'completed');
        verify(mockDio.get('/user/enrollments')).called(1);
      });
    });

    group('Error Handling Tests', () {
      test('should handle network timeout', () async {
        // Arrange
        when(mockDio.get('/courses')).thenThrow(DioException(
          requestOptions: RequestOptions(path: '/courses'),
          type: DioExceptionType.connectionTimeout,
        ));

        // Act & Assert
        expect(
          () => apiService.getCourses(),
          throwsA(isA<Exception>()),
        );
      });

      test('should handle server error (500)', () async {
        // Arrange
        when(mockDio.get('/courses')).thenThrow(DioException(
          requestOptions: RequestOptions(path: '/courses'),
          response: Response(
            statusCode: 500,
            data: {'message': 'Internal Server Error'},
            requestOptions: RequestOptions(path: '/courses'),
          ),
        ));

        // Act & Assert
        expect(
          () => apiService.getCourses(),
          throwsA(isA<Exception>()),
        );
      });

      test('should handle unauthorized access (401)', () async {
        // Arrange
        when(mockDio.get('/user/profile')).thenThrow(DioException(
          requestOptions: RequestOptions(path: '/user/profile'),
          response: Response(
            statusCode: 401,
            data: {'message': 'Unauthorized'},
            requestOptions: RequestOptions(path: '/user/profile'),
          ),
        ));

        // Act & Assert
        expect(
          () => apiService.getUserProfile(),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('Headers and Configuration Tests', () {
      test('should include authorization header when token is set', () {
        // Arrange
        const token = 'Bearer fake_token_123';

        // Act
        apiService.setAuthToken(token);

        // Assert
        expect(apiService.dio.options.headers['Authorization'], token);
      });

      test('should use correct base URL from environment', () {
        // Assert
        expect(apiService.dio.options.baseUrl, EnvironmentConfig.apiBaseUrl);
      });

      test('should have correct timeout configuration', () {
        // Assert
        expect(apiService.dio.options.connectTimeout, Duration(seconds: 30));
        expect(apiService.dio.options.receiveTimeout, Duration(seconds: 30));
      });
    });

    group('Data Transformation Tests', () {
      test('should handle empty response data', () async {
        // Arrange
        final expectedResponse = Response(
          data: null,
          statusCode: 200,
          requestOptions: RequestOptions(path: '/test'),
        );

        when(mockDio.get('/test')).thenAnswer((_) async => expectedResponse);

        // Act & Assert
        expect(
          () => apiService.makeRequest('GET', '/test'),
          throwsA(isA<Exception>()),
        );
      });

      test('should handle malformed JSON response', () async {
        // Arrange
        when(mockDio.get('/test')).thenThrow(DioException(
          requestOptions: RequestOptions(path: '/test'),
          response: Response(
            statusCode: 200,
            data: 'invalid json',
            requestOptions: RequestOptions(path: '/test'),
          ),
        ));

        // Act & Assert
        expect(
          () => apiService.makeRequest('GET', '/test'),
          throwsA(isA<Exception>()),
        );
      });
    });
  });
}