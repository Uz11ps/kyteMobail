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
    try {
      print('🔐 Attempting login for: $email');
      
      final response = await _dio.post(
        ApiEndpoints.login,
        data: {
          'email': email,
          'password': password,
        },
      );

      print('✅ Login successful, response: ${response.data}');

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
      print('❌ Login error: ${e.type}');
      print('   Status: ${e.response?.statusCode}');
      print('   Data: ${e.response?.data}');
      print('   Message: ${e.message}');
      
      if (e.type == DioExceptionType.connectionTimeout || 
          e.type == DioExceptionType.connectionError) {
        throw Exception('Не удалось подключиться к серверу. Проверьте подключение к интернету.');
      }
      final errorMessage = e.response?.data is Map 
          ? e.response?.data['message'] 
          : e.response?.data?.toString() ?? 'Ошибка входа';
      throw Exception(errorMessage);
    } catch (e) {
      print('❌ Unexpected login error: $e');
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
    try {
      print('📝 Attempting registration for: $email');
      
      final response = await _dio.post(
        ApiEndpoints.register,
        data: {
          'email': email,
          'password': password,
          if (name != null) 'name': name,
        },
      );

      print('✅ Registration successful, response: ${response.data}');

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
      print('❌ Registration error: ${e.type}');
      print('   Status: ${e.response?.statusCode}');
      print('   Data: ${e.response?.data}');
      print('   Message: ${e.message}');
      
      final errorMessage = e.response?.data is Map 
          ? e.response?.data['message'] 
          : e.response?.data?.toString() ?? 'Ошибка регистрации';
      throw Exception(errorMessage);
    } catch (e) {
      print('❌ Unexpected registration error: $e');
      throw Exception('Ошибка подключения: ${e.toString()}');
    }
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

