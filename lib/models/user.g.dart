// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

User _$UserFromJson(Map<String, dynamic> json) => User(
  id: (json['id'] as num).toInt(),
  nom: json['nom'] as String,
  prenom: json['prenom'] as String,
  email: json['email'] as String?,
  telephone: User._phoneFromJson(json['tel_1']),
  genre: json['genre'] as String?,
  age: json['age'] as String?,
  photo: json['photo'] as String?,
  role: json['role'] as String?,
  droits: (json['droits'] as num?)?.toInt(),
  about: json['about'] as String?,
  skills: User._skillsFromJson(json['skills']),
  commanders: json['commanders'] as List<dynamic>?,
  createdAt: json['created_at'] as String?,
  updatedAt: json['updated_at'] as String?,
);

Map<String, dynamic> _$UserToJson(User instance) => <String, dynamic>{
  'id': instance.id,
  'nom': instance.nom,
  'prenom': instance.prenom,
  'email': instance.email,
  'tel_1': User._phoneToJson(instance.telephone),
  'genre': instance.genre,
  'age': instance.age,
  'photo': instance.photo,
  'role': instance.role,
  'droits': instance.droits,
  'about': instance.about,
  'skills': User._skillsToJson(instance.skills),
  'commanders': instance.commanders,
  'created_at': instance.createdAt,
  'updated_at': instance.updatedAt,
};
