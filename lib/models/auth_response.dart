import 'package:json_annotation/json_annotation.dart';
import 'user.dart';

part 'auth_response.g.dart';

@JsonSerializable()
class AuthResponse {
  final String message;
  final String? token;
  final User? user;
  @JsonKey(includeIfNull: false)
  final String? type;

  AuthResponse({
    required this.message,
    this.token,
    this.user,
    this.type,
  });

  // Propriété calculée pour déterminer le succès
  bool get success => token != null && user != null;

  factory AuthResponse.fromJson(Map<String, dynamic> json) =>
      _$AuthResponseFromJson(json);
  Map<String, dynamic> toJson() => _$AuthResponseToJson(this);
}

@JsonSerializable()
class LoginRequest {
  @JsonKey(name: 'tel_1')
  final String telephone;
  final String password;

  LoginRequest({
    required this.telephone,
    required this.password,
  });

  factory LoginRequest.fromJson(Map<String, dynamic> json) =>
      _$LoginRequestFromJson(json);
  Map<String, dynamic> toJson() => _$LoginRequestToJson(this);
}

@JsonSerializable()
class RegisterRequest {
  final String nom;
  final String prenom;
  @JsonKey(includeIfNull: false)
  final String? email;
  @JsonKey(name: 'tel')
  final String telephone;
  final String password;
  @JsonKey(includeIfNull: false)
  final String? passwordConfirmation;
  @JsonKey(includeIfNull: false)
  final String? genre;
  @JsonKey(includeIfNull: false)
  final String? age;

  RegisterRequest({
    required this.nom,
    required this.prenom,
    this.email,
    required this.telephone,
    required this.password,
    this.passwordConfirmation,
    this.genre,
    this.age,
  });

  factory RegisterRequest.fromJson(Map<String, dynamic> json) =>
      _$RegisterRequestFromJson(json);
  Map<String, dynamic> toJson() => _$RegisterRequestToJson(this);
}