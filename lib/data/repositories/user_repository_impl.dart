import 'dart:io';
import 'package:dio/dio.dart';
import '../../domain/repositories/user_repository.dart';
import '../models/user_model.dart';
import '../../core/constants/api_endpoints.dart';

class UserRepositoryImpl implements UserRepository {
  final Dio _dio;

  UserRepositoryImpl(this._dio);

  @override
  Future<UserModel> getCurrentUser() async {
    try {
      final response = await _dio.get(ApiEndpoints.getCurrentUser);
      if (response.data == null || response.data['user'] == null) {
        throw Exception('Данные пользователя не получены');
      }
      return UserModel.fromJson(response.data['user']);
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Ошибка получения профиля');
    }
  }

  @override
  Future<UserModel> updateProfile({
    String? name,
    String? nickname,
    String? phone,
    String? email,
    String? about,
    DateTime? birthday,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (name != null) data['name'] = name;
      if (nickname != null) data['nickname'] = nickname;
      if (phone != null) data['phone'] = phone;
      if (email != null) data['email'] = email;
      if (about != null) data['about'] = about;
      if (birthday != null) data['birthday'] = birthday.toIso8601String();

      final response = await _dio.put(
        ApiEndpoints.updateProfile,
        data: data,
      );

      if (response.data == null || response.data['user'] == null) {
        throw Exception('Данные пользователя не получены');
      }
      return UserModel.fromJson(response.data['user']);
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Ошибка обновления профиля');
    }
  }

  @override
  Future<UserModel> getUserById(String id) async {
    try {
      final response = await _dio.get(ApiEndpoints.getUserById(id));
      if (response.data == null || response.data['user'] == null) {
        throw Exception('Данные пользователя не получены');
      }
      return UserModel.fromJson(response.data['user']);
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Ошибка получения данных пользователя');
    }
  }

  @override
  Future<UserModel?> findUserByIdentifier(String identifier) async {
    try {
      final response = await _dio.get('/user/find', queryParameters: {'identifier': identifier});
      if (response.data == null || response.data['user'] == null) {
        return null;
      }
      return UserModel.fromJson(response.data['user']);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return null;
      }
      throw Exception(e.response?.data['message'] ?? 'Ошибка поиска пользователя');
    }
  }

  @override
  Future<String> uploadAvatar(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        throw Exception('Файл не найден');
      }

      final formData = FormData.fromMap({
        'avatar': await MultipartFile.fromFile(filePath),
      });

      final response = await _dio.post(
        ApiEndpoints.uploadAvatar,
        data: formData,
      );

      if (response.data == null || response.data['avatarUrl'] == null) {
        throw Exception('URL аватара не получен');
      }
      return response.data['avatarUrl'] as String;
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Ошибка загрузки аватара');
    }
  }
}



