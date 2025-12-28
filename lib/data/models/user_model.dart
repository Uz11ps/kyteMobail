import 'package:json_annotation/json_annotation.dart';

part 'user_model.g.dart';

@JsonSerializable()
class UserModel {
  final String id;
  final String? email;
  final String? phone;
  final String? name;
  final String? nickname;
  final String? about;
  final DateTime? birthday;
  final String? avatarUrl;

  UserModel({
    required this.id,
    this.email,
    this.phone,
    this.name,
    this.nickname,
    this.about,
    this.birthday,
    this.avatarUrl,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    try {
      // Поддержка _id из MongoDB
      if (json.containsKey('_id') && !json.containsKey('id')) {
        final idValue = json['_id'];
        if (idValue != null) {
          json['id'] = idValue.toString();
        }
      }
      
      // Проверка обязательных полей
      if (!json.containsKey('id') && !json.containsKey('_id')) {
        throw Exception('Поле "id" отсутствует в ответе сервера. Данные: $json');
      }
      
      final idValue = json['id'] ?? json['_id'];
      if (idValue == null || idValue.toString().isEmpty) {
        throw Exception('Поле "id" равно null или пустое в ответе сервера. Данные: $json');
      }
      
      return _$UserModelFromJson(json);
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Ошибка парсинга UserModel: ${e.toString()}. Данные: $json');
    }
  }

  Map<String, dynamic> toJson() => _$UserModelToJson(this);
}

