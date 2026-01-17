import 'dart:convert';
import 'package:json_annotation/json_annotation.dart';

part 'user.g.dart';

@JsonSerializable()
class User {
  final int id;
  final String nom;
  final String prenom;
  final String? email;
  @JsonKey(name: 'tel_1', fromJson: _phoneFromJson, toJson: _phoneToJson)
  final String? telephone;
  final String? genre;
  final String? age;
  final String? photo;
  final String? role;
  final int? droits;
  final String? about;
  @JsonKey(fromJson: _skillsFromJson, toJson: _skillsToJson)
  final List<String>? skills;
  final List<dynamic>? commanders;
  @JsonKey(name: 'created_at')
  final String? createdAt;
  @JsonKey(name: 'updated_at')
  final String? updatedAt;

  User({
    required this.id,
    required this.nom,
    required this.prenom,
    this.email,
    this.telephone,
    this.genre,
    this.age,
    this.photo,
    this.role,
    this.droits,
    this.about,
    this.skills,
    this.commanders,
    this.createdAt,
    this.updatedAt,
  });

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
  Map<String, dynamic> toJson() => _$UserToJson(this);

  // Convenience getters
  String get fullName => '$prenom $nom';
  String get displayName => fullName.trim().isEmpty ? (email ?? 'Utilisateur') : fullName;

  // Copy with method for updating user data
  User copyWith({
    int? id,
    String? nom,
    String? prenom,
    String? email,
    String? telephone,
    String? genre,
    String? age,
    String? photo,
    String? role,
    int? droits,
    String? about,
    List<String>? skills,
    List<dynamic>? commanders,
    String? createdAt,
    String? updatedAt,
  }) {
    return User(
      id: id ?? this.id,
      nom: nom ?? this.nom,
      prenom: prenom ?? this.prenom,
      email: email ?? this.email,
      telephone: telephone ?? this.telephone,
      genre: genre ?? this.genre,
      age: age ?? this.age,
      photo: photo ?? this.photo,
      role: role ?? this.role,
      droits: droits ?? this.droits,
      about: about ?? this.about,
      skills: skills ?? this.skills,
      commanders: commanders ?? this.commanders,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Helper functions for phone number conversion
  static String? _phoneFromJson(dynamic value) {
    if (value == null) return null;
    if (value is String) return value;
    if (value is int) return value.toString();
    return value.toString();
  }

  static dynamic _phoneToJson(String? value) {
    return value;
  }

  // Helper functions for skills conversion
  static List<String>? _skillsFromJson(dynamic value) {
    if (value == null) return null;
    if (value is List) {
      return value.map((e) => e.toString()).toList();
    }
    if (value is String) {
      // Si c'est une chaîne JSON, essayer de la décoder
      try {
        final List<dynamic> decoded = jsonDecode(value);
        return decoded.map((e) => e.toString()).toList();
      } catch (e) {
        // Si ce n'est pas du JSON, retourner une liste avec la valeur
        return [value];
      }
    }
    return null;
  }

  static dynamic _skillsToJson(List<String>? value) {
    return value;
  }
}