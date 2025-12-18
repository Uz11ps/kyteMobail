import 'package:json_annotation/json_annotation.dart';

part 'user_model.g.dart';

@JsonSerializable()
class UserModel {
  final String id;
  final String email;
  final String? phone;
  final String? name;
  final String? nickname;
  final String? about;
  final DateTime? birthday;
  final String? avatarUrl;

  UserModel({
    required this.id,
    required this.email,
    this.phone,
    this.name,
    this.nickname,
    this.about,
    this.birthday,
    this.avatarUrl,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    // Поддержка _id из MongoDB
    if (json.containsKey('_id') && !json.containsKey('id')) {
      json['id'] = json['_id'].toString();
    }
    
    // Проверка обязательных полей
    if (!json.containsKey('id') || json['id'] == null) {
      throw Exception('Поле "id" отсутствует или равно null в ответе сервера');
    }
    if (!json.containsKey('email') || json['email'] == null) {
      throw Exception('Поле "email" отсутствует или равно null в ответе сервера');
    }
    
    return _$UserModelFromJson(json);
  }

  Map<String, dynamic> toJson() => _$UserModelToJson(this);
}

