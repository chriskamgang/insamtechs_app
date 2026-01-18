import 'dart:convert';
import 'lib/models/auth_response.dart';

void main() {
  // Test 1: LoginRequest avec un téléphone numérique
  final loginRequest1 = LoginRequest(
    telephone: '659339778',
    password: 'Messi1234.',
  );

  print('Test 1 - LoginRequest with numeric string:');
  print('telephone field value: ${loginRequest1.telephone}');
  print('telephone field type: ${loginRequest1.telephone.runtimeType}');

  final json1 = loginRequest1.toJson();
  print('toJson() result: $json1');
  print('tel_1 type in map: ${json1['tel_1'].runtimeType}');

  final encoded1 = jsonEncode(json1);
  print('jsonEncode() result: $encoded1');
  print('');

  // Test 2: LoginRequest avec un téléphone alphanumérique
  final loginRequest2 = LoginRequest(
    telephone: '06-21-23-45-67',
    password: 'Password123!',
  );

  print('Test 2 - LoginRequest with alphanumeric string:');
  print('telephone field value: ${loginRequest2.telephone}');
  print('telephone field type: ${loginRequest2.telephone.runtimeType}');

  final json2 = loginRequest2.toJson();
  print('toJson() result: $json2');
  print('tel_1 type in map: ${json2['tel_1'].runtimeType}');

  final encoded2 = jsonEncode(json2);
  print('jsonEncode() result: $encoded2');
}
