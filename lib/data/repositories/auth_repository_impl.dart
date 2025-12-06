import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../domain/repositories/auth_repository.dart';
import '../models/user_model.dart';
import '../../core/constants/api_endpoints.dart';
import '../../core/utils/storage_keys.dart';

class AuthRepositoryImpl implements AuthRepository {
  final Dio _dio;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  AuthRepositoryImpl(this._dio);

  @override
  Future<UserModel> login(String email, String password) async {
    // Демо-режим: тестовый пользователь
    if (email == '123@mail.ru' && password == '123123') {
      final demoUser = UserModel(
        id: 'demo-user-123',
        email: email,
        name: 'Тестовый пользователь',
      );
      
      await _storage.write(
        key: StorageKeys.accessToken,
        value: 'demo-token-${DateTime.now().millisecondsSinceEpoch}',
      );
      await _storage.write(
        key: StorageKeys.refreshToken,
        value: 'demo-refresh-token',
      );
      await _storage.write(
        key: StorageKeys.userId,
        value: demoUser.id,
      );
      await _storage.write(
        key: StorageKeys.userEmail,
        value: demoUser.email,
      );

      return demoUser;
    }

    try {
      final response = await _dio.post(
        ApiEndpoints.login,
        data: {
          'email': email,
          'password': password,
        },
      );

      final user = UserModel.fromJson(response.data['user']);
      await _storage.write(
        key: StorageKeys.accessToken,
        value: response.data['accessToken'],
      );
      await _storage.write(
        key: StorageKeys.refreshToken,
        value: response.data['refreshToken'],
      );
      await _storage.write(
        key: StorageKeys.userId,
        value: user.id,
      );
      await _storage.write(
        key: StorageKeys.userEmail,
        value: user.email,
      );

      return user;
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout || 
          e.type == DioExceptionType.connectionError) {
        throw Exception('Не удалось подключиться к серверу. Проверьте подключение к интернету.');
      }
      throw Exception(e.response?.data['message'] ?? 'Ошибка входа');
    } catch (e) {
      throw Exception('Ошибка подключения: ${e.toString()}');
    }
  }

  @override
  Future<UserModel> loginWithPhone(String phone, String code) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.login,
        data: {
          'phone': phone,
          'code': code,
        },
      );

      final user = UserModel.fromJson(response.data['user']);
      await _storage.write(
        key: StorageKeys.accessToken,
        value: response.data['accessToken'],
      );
      await _storage.write(
        key: StorageKeys.refreshToken,
        value: response.data['refreshToken'],
      );
      await _storage.write(
        key: StorageKeys.userId,
        value: user.id,
      );

      return user;
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Ошибка входа');
    }
  }

  @override
  Future<UserModel> register(String email, String password, {String? name}) async {
    // Демо-режим: автоматическая регистрация
    final demoUser = UserModel(
      id: 'demo-user-${DateTime.now().millisecondsSinceEpoch}',
      email: email,
      name: name ?? 'Пользователь',
    );
    
    await _storage.write(
      key: StorageKeys.accessToken,
      value: 'demo-token-${DateTime.now().millisecondsSinceEpoch}',
    );
    await _storage.write(
      key: StorageKeys.refreshToken,
      value: 'demo-refresh-token',
    );
    await _storage.write(
      key: StorageKeys.userId,
      value: demoUser.id,
    );
    await _storage.write(
      key: StorageKeys.userEmail,
      value: demoUser.email,
    );

    return demoUser;

    // Раскомментируйте для реального backend:
    /*
    try {
      final response = await _dio.post(
        ApiEndpoints.register,
        data: {
          'email': email,
          'password': password,
          if (name != null) 'name': name,
        },
      );

      final user = UserModel.fromJson(response.data['user']);
      await _storage.write(
        key: StorageKeys.accessToken,
        value: response.data['accessToken'],
      );
      await _storage.write(
        key: StorageKeys.refreshToken,
        value: response.data['refreshToken'],
      );
      await _storage.write(
        key: StorageKeys.userId,
        value: user.id,
      );
      await _storage.write(
        key: StorageKeys.userEmail,
        value: user.email,
      );

      return user;
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Ошибка регистрации');
    }
    */
  }

  @override
  Future<void> logout() async {
    await _storage.deleteAll();
  }

  @override
  Future<UserModel?> getCurrentUser() async {
    final userId = await _storage.read(key: StorageKeys.userId);
    final email = await _storage.read(key: StorageKeys.userEmail);
    
    if (userId == null || email == null) {
      return null;
    }

    return UserModel(
      id: userId,
      email: email,
    );
  }

  @override
  Future<bool> isAuthenticated() async {
    try {
      final token = await _storage.read(key: StorageKeys.accessToken);
      return token != null && token.isNotEmpty;
    } catch (e) {
      return false;
    }
  }
}

