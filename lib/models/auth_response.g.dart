// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AuthResponse _$AuthResponseFromJson(Map<String, dynamic> json) => AuthResponse(
  message: json['message'] as String,
  token: json['token'] as String?,
  user: json['user'] == null
      ? null
      : User.fromJson(json['user'] as Map<String, dynamic>),
  type: json['type'] as String?,
);

Map<String, dynamic> _$AuthResponseToJson(AuthResponse instance) =>
    <String, dynamic>{
      'message': instance.message,
      'token': instance.token,
      'user': instance.user,
      'type': ?instance.type,
    };

LoginRequest _$LoginRequestFromJson(Map<String, dynamic> json) => LoginRequest(
  telephone: json['tel_1'] as String,
  password: json['password'] as String,
);

Map<String, dynamic> _$LoginRequestToJson(LoginRequest instance) =>
    <String, dynamic>{
      'tel_1': instance.telephone,
      'password': instance.password,
    };

RegisterRequest _$RegisterRequestFromJson(Map<String, dynamic> json) =>
    RegisterRequest(
      nom: json['nom'] as String,
      prenom: json['prenom'] as String,
      email: json['email'] as String?,
      telephone: json['tel'] as String,
      password: json['password'] as String,
      passwordConfirmation: json['passwordConfirmation'] as String?,
      genre: json['genre'] as String?,
      age: json['age'] as String?,
    );

Map<String, dynamic> _$RegisterRequestToJson(RegisterRequest instance) =>
    <String, dynamic>{
      'nom': instance.nom,
      'prenom': instance.prenom,
      'email': ?instance.email,
      'tel': instance.telephone,
      'password': instance.password,
      'passwordConfirmation': ?instance.passwordConfirmation,
      'genre': ?instance.genre,
      'age': ?instance.age,
    };
