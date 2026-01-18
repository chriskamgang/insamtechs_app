import 'package:dio/dio.dart';
import 'dart:convert';

void main() async {
  final dio = Dio(BaseOptions(
    baseUrl: 'https://admin.insamtechs.com',
    headers: {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    },
  ));

  // Activer les logs
  dio.interceptors.add(LogInterceptor(
    requestBody: true,
    responseBody: true,
    requestHeader: true,
    responseHeader: false,
    error: true,
  ));

  print('========== Test 1: Login avec numéro comme string ==========');
  try {
    final response1 = await dio.post(
      '/api/login',
      data: {
        'tel_1': '0621234567',  // String
        'password': 'Password123!',
      },
    );
    print('✓ Success: ${response1.statusCode}');
    print('Response: ${response1.data}');
  } catch (e) {
    print('✗ Error: $e');
    if (e is DioException && e.response != null) {
      print('Status: ${e.response!.statusCode}');
      print('Response: ${e.response!.data}');
    }
  }

  print('\n========== Test 2: Login avec compte test (string) ==========');
  try {
    final response2 = await dio.post(
      '/api/login',
      data: {
        'tel_1': '659339778',  // String
        'password': 'Messi1234.',
      },
    );
    print('✓ Success: ${response2.statusCode}');
    print('Response: ${response2.data}');
  } catch (e) {
    print('✗ Error: $e');
    if (e is DioException && e.response != null) {
      print('Status: ${e.response!.statusCode}');
      print('Response: ${e.response!.data}');
    }
  }

  print('\n========== Test 3: Login avec numéro de type int dans le JSON ==========');
  try {
    // Créer manuellement un JSON avec un nombre
    final jsonData = '{"tel_1": 659339778, "password": "Messi1234."}';
    final response3 = await dio.post(
      '/api/login',
      data: jsonDecode(jsonData),
    );
    print('✓ Success: ${response3.statusCode}');
    print('Response: ${response3.data}');
  } catch (e) {
    print('✗ Error: $e');
    if (e is DioException && e.response != null) {
      print('Status: ${e.response!.statusCode}');
      print('Response: ${e.response!.data}');
    }
  }
}
