import 'package:dio/dio.dart';
import '../../domain/repositories/auth_repository.dart';
import '../models/user_model.dart';
import '../../core/constants/api_endpoints.dart';
import '../../core/utils/storage_keys.dart';
import '../../core/storage/storage_service.dart';

class AuthRepositoryImpl implements AuthRepository {
  final Dio _dio;
  final StorageService _storage = StorageService.instance;

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

      // Проверяем наличие необходимых данных в ответе
      if (response.data == null) {
        throw Exception('Пустой ответ от сервера');
      }

      final userData = response.data['user'];
      final accessToken = response.data['accessToken'];
      final refreshToken = response.data['refreshToken'];

      if (userData == null) {
        throw Exception('Данные пользователя не получены');
      }
      if (accessToken == null || accessToken.toString().isEmpty) {
        throw Exception('Токен доступа не получен');
      }
      if (refreshToken == null || refreshToken.toString().isEmpty) {
        throw Exception('Токен обновления не получен');
      }

      final user = UserModel.fromJson(userData);
      
      await _storage.write(StorageKeys.accessToken, accessToken.toString());
      await _storage.write(StorageKeys.refreshToken, refreshToken.toString());
      await _storage.write(StorageKeys.userId, user.id);
      await _storage.write(StorageKeys.userEmail, user.email);

      print('✅ User data saved: id=${user.id}, email=${user.email}');
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
      // Детальная обработка ошибок
      String errorMessage = 'Ошибка входа';
      
      if (e.response != null) {
        if (e.response!.data is Map) {
          errorMessage = e.response!.data['message'] ?? 
                        e.response!.data['error'] ?? 
                        'Ошибка входа';
        } else if (e.response!.data is String) {
          errorMessage = e.response!.data;
        }
      } else {
        // Нет ответа от сервера
        if (e.type == DioExceptionType.connectionTimeout) {
          errorMessage = 'Превышено время ожидания. Сервер не отвечает.';
        } else if (e.type == DioExceptionType.connectionError) {
          errorMessage = 'Не удалось подключиться к серверу. Проверьте подключение к интернету.';
        } else {
          errorMessage = 'Ошибка подключения: ${e.message}';
        }
      }
      
      throw Exception(errorMessage);
    } catch (e) {
      print('❌ Unexpected login error: $e');
      String errorMessage = 'Неизвестная ошибка';
      try {
        if (e != null) {
          final errorStr = e.toString();
          if (errorStr.isNotEmpty) {
            errorMessage = errorStr;
          }
        }
      } catch (_) {
        // Используем сообщение по умолчанию
      }
      throw Exception('Ошибка подключения: $errorMessage');
    }
  }

  @override
  Future<UserModel> loginWithPhone(String phone, String code) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.verifyPhoneCode,
        data: {
          'phone': phone,
          'code': code,
        },
      );

      if (response.data == null || response.data['user'] == null) {
        throw Exception('Неполные данные ответа сервера');
      }

      final userData = response.data['user'];
      final newAccessToken = response.data['accessToken'];
      final newRefreshToken = response.data['refreshToken'];

      final user = UserModel.fromJson(userData);

      await _storage.write(StorageKeys.accessToken, newAccessToken.toString());
      await _storage.write(StorageKeys.refreshToken, newRefreshToken.toString());
      await _storage.write(StorageKeys.userId, user.id);
      await _storage.write(StorageKeys.userEmail, user.email);
      if (user.name != null) {
        await _storage.write(StorageKeys.userName, user.name!);
      }

      return user;
    } on DioException catch (e) {
      throw Exception(
        _extractErrorMessage(e.response?.data, 'Ошибка входа по телефону'),
      );
    } catch (e) {
      String errorMessage = 'Неизвестная ошибка';
      try {
        if (e != null) {
          errorMessage = e.toString();
        }
      } catch (_) {
        errorMessage = 'Ошибка входа по телефону';
      }
      throw Exception('Ошибка входа по телефону: $errorMessage');
    }
  }

  @override
  Future<void> sendPhoneVerificationCode(String phone) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.sendPhoneCode,
        data: {
          'phone': phone,
        },
      );

      if (response.data == null || !response.data['success']) {
        throw Exception(response.data?['message'] ?? 'Ошибка отправки кода');
      }
    } on DioException catch (e) {
      throw Exception(
        _extractErrorMessage(e.response?.data, 'Ошибка отправки SMS кода'),
      );
    } catch (e) {
      String errorMessage = 'Неизвестная ошибка';
      try {
        if (e != null) {
          errorMessage = e.toString();
        }
      } catch (_) {
        errorMessage = 'Ошибка отправки SMS кода';
      }
      throw Exception('Ошибка отправки SMS кода: $errorMessage');
    }
  }

  @override
  Future<UserModel> registerWithPhone(String phone, String code, {String? name}) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.verifyPhoneCode,
        data: {
          'phone': phone,
          'code': code,
          if (name != null) 'name': name,
        },
      );

      if (response.data == null || response.data['user'] == null) {
        throw Exception('Неполные данные ответа сервера при регистрации по телефону');
      }

      final userData = response.data['user'];
      final newAccessToken = response.data['accessToken'];
      final newRefreshToken = response.data['refreshToken'];

      final user = UserModel.fromJson(userData);

      await _storage.write(StorageKeys.accessToken, newAccessToken.toString());
      await _storage.write(StorageKeys.refreshToken, newRefreshToken.toString());
      await _storage.write(StorageKeys.userId, user.id);
      await _storage.write(StorageKeys.userEmail, user.email);
      if (user.name != null) {
        await _storage.write(StorageKeys.userName, user.name!);
      }

      return user;
    } on DioException catch (e) {
      throw Exception(
        _extractErrorMessage(e.response?.data, 'Ошибка регистрации по телефону'),
      );
    } catch (e) {
      String errorMessage = 'Неизвестная ошибка';
      try {
        if (e != null) {
          errorMessage = e.toString();
        }
      } catch (_) {
        errorMessage = 'Ошибка регистрации по телефону';
      }
      throw Exception('Ошибка регистрации по телефону: $errorMessage');
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

      // Проверяем наличие необходимых данных в ответе
      if (response.data == null) {
        throw Exception('Пустой ответ от сервера');
      }

      final userData = response.data['user'];
      final accessToken = response.data['accessToken'];
      final refreshToken = response.data['refreshToken'];

      if (userData == null) {
        throw Exception('Данные пользователя не получены');
      }
      if (accessToken == null || accessToken.toString().isEmpty) {
        throw Exception('Токен доступа не получен');
      }
      if (refreshToken == null || refreshToken.toString().isEmpty) {
        throw Exception('Токен обновления не получен');
      }

      // Проверяем наличие обязательных полей пользователя
      if (userData['id'] == null || userData['id'].toString().isEmpty) {
        throw Exception('ID пользователя не получен');
      }
      if (userData['email'] == null || userData['email'].toString().isEmpty) {
        throw Exception('Email пользователя не получен');
      }

      print('📋 Parsing user data: $userData');
      UserModel user;
      try {
        user = UserModel.fromJson(userData);
        print('✅ User parsed successfully: id=${user.id}, email=${user.email}');
      } catch (e) {
        print('❌ Error parsing user: $e');
        print('   User data: $userData');
        String parseErrorMessage = 'Неизвестная ошибка парсинга';
        try {
          if (e != null) {
            final errorStr = e.toString();
            if (errorStr.isNotEmpty) {
              parseErrorMessage = errorStr;
            }
          }
        } catch (_) {
          // Используем сообщение по умолчанию
        }
        throw Exception('Ошибка парсинга данных пользователя: $parseErrorMessage');
      }
      
      try {
        print('💾 Saving access token...');
        await _storage.write(StorageKeys.accessToken, accessToken.toString());
        print('✅ Access token saved');
        
        print('💾 Saving refresh token...');
        await _storage.write(StorageKeys.refreshToken, refreshToken.toString());
        print('✅ Refresh token saved');
        
        print('💾 Saving user ID...');
        await _storage.write(StorageKeys.userId, user.id);
        print('✅ User ID saved: ${user.id}');
        
        print('💾 Saving user email...');
        await _storage.write(StorageKeys.userEmail, user.email);
        print('✅ User email saved: ${user.email}');

        print('✅ All user data saved successfully');
      } catch (e) {
        print('❌ Error saving user data: $e');
        try {
          if (e != null) {
            print('   Error type: ${e.runtimeType}');
          }
        } catch (_) {
          // Игнорируем ошибки при получении типа
        }
        rethrow;
      }
      
      return user;
    } on DioException catch (e) {
      print('❌ Registration error: ${e.type}');
      print('   Status: ${e.response?.statusCode}');
      print('   Data: ${e.response?.data}');
      print('   Message: ${e.message}');
      
      // Детальная обработка ошибок
      String errorMessage = 'Ошибка регистрации';
      
      if (e.response != null) {
        if (e.response!.data is Map) {
          errorMessage = e.response!.data['message'] ?? 
                        e.response!.data['error'] ?? 
                        'Ошибка регистрации';
        } else if (e.response!.data is String) {
          errorMessage = e.response!.data;
        }
      } else {
        // Нет ответа от сервера
        if (e.type == DioExceptionType.connectionTimeout) {
          errorMessage = 'Превышено время ожидания. Сервер не отвечает.';
        } else if (e.type == DioExceptionType.connectionError) {
          errorMessage = 'Не удалось подключиться к серверу. Проверьте подключение к интернету.';
        } else {
          errorMessage = 'Ошибка подключения: ${e.message}';
        }
      }
      
      throw Exception(errorMessage);
    } catch (e) {
      print('❌ Unexpected registration error: $e');
      String errorMessage = 'Неизвестная ошибка';
      try {
        if (e != null) {
          final errorStr = e.toString();
          if (errorStr.isNotEmpty) {
            errorMessage = errorStr;
          }
        }
      } catch (_) {
        // Используем сообщение по умолчанию
      }
      throw Exception('Ошибка подключения: $errorMessage');
    }
  }

  @override
  Future<void> logout() async {
    await _storage.deleteAll();
  }

  @override
  Future<UserModel?> getCurrentUser() async {
    final userId = await _storage.read(StorageKeys.userId);
    final email = await _storage.read(StorageKeys.userEmail);
    
    if (userId == null || email == null) {
      return null;
    }

    return UserModel(
      id: userId,
      email: email,
    );
  }

  @override
  Future<UserModel> loginWithGoogle(String idToken, String accessToken, String email, String name, {String? picture, String? googleId}) async {
    try {
      print('🔐 Attempting Google login for: $email');
      
      final response = await _dio.post(
        ApiEndpoints.googleAuth,
        data: {
          'idToken': idToken,
          'accessToken': accessToken,
          'email': email,
          'name': name,
          if (picture != null) 'picture': picture,
          if (googleId != null) 'googleId': googleId,
        },
      );

      print('✅ Google login successful, response: ${response.data}');

      if (response.data == null) {
        throw Exception('Пустой ответ от сервера');
      }

      final userData = response.data['user'];
      final jwtAccessToken = response.data['accessToken'];
      final refreshToken = response.data['refreshToken'];

      if (userData == null) {
        throw Exception('Данные пользователя не получены');
      }
      if (jwtAccessToken == null || jwtAccessToken.toString().isEmpty) {
        throw Exception('Токен доступа не получен');
      }
      if (refreshToken == null || refreshToken.toString().isEmpty) {
        throw Exception('Токен обновления не получен');
      }

      // Проверяем наличие обязательных полей перед парсингом
      if (userData is! Map<String, dynamic>) {
        throw Exception('Данные пользователя имеют неверный формат');
      }
      
      if (!userData.containsKey('id') && !userData.containsKey('_id')) {
        throw Exception('ID пользователя отсутствует в ответе сервера');
      }
      if (!userData.containsKey('email') || userData['email'] == null) {
        throw Exception('Email пользователя отсутствует в ответе сервера');
      }

      UserModel user;
      try {
        print('📋 Parsing user data: $userData');
        user = UserModel.fromJson(userData as Map<String, dynamic>);
        print('✅ User parsed successfully: id=${user.id}, email=${user.email}');
      } catch (e) {
        print('❌ Error parsing user data: $e');
        try {
          if (e != null) {
            print('   Error type: ${e.runtimeType}');
          }
        } catch (_) {
          // Игнорируем ошибки при получении типа
        }
        print('   User data: $userData');
        try {
          if (userData != null) {
            print('   User data type: ${userData.runtimeType}');
          }
        } catch (_) {
          // Игнорируем ошибки при получении типа
        }
        rethrow;
      }
      
      try {
        print('💾 Saving access token...');
        await _storage.write(StorageKeys.accessToken, jwtAccessToken.toString());
        print('✅ Access token saved');
        
        print('💾 Saving refresh token...');
        await _storage.write(StorageKeys.refreshToken, refreshToken.toString());
        print('✅ Refresh token saved');
        
        print('💾 Saving user ID...');
        await _storage.write(StorageKeys.userId, user.id);
        print('✅ User ID saved: ${user.id}');
        
        print('💾 Saving user email...');
        await _storage.write(StorageKeys.userEmail, user.email);
        print('✅ User email saved: ${user.email}');
      } catch (e) {
        print('❌ Error saving user data: $e');
        try {
          if (e != null) {
            print('   Error type: ${e.runtimeType}');
          }
        } catch (_) {
          // Игнорируем ошибки при получении типа
        }
        rethrow;
      }

      print('✅ Google user data saved: id=${user.id}, email=${user.email}');
      return user;
    } on DioException catch (e) {
      print('❌ Google login error: ${e.type}');
      print('   Status: ${e.response?.statusCode}');
      print('   Data: ${e.response?.data}');
      print('   Message: ${e.message}');
      
      String errorMessage = 'Ошибка входа через Google';
      
      if (e.response != null) {
        if (e.response!.data is Map) {
          errorMessage = e.response!.data['message'] ?? 
                        e.response!.data['error'] ?? 
                        'Ошибка входа через Google';
        } else if (e.response!.data is String) {
          errorMessage = e.response!.data;
        }
      }
      
      throw Exception(errorMessage);
    } catch (e) {
      print('❌ Unexpected Google login error: $e');
      String errorMessage = 'Неизвестная ошибка';
      try {
        if (e != null) {
          final errorStr = e.toString();
          if (errorStr.isNotEmpty) {
            errorMessage = errorStr;
          }
        }
      } catch (_) {
        // Используем сообщение по умолчанию
      }
      throw Exception('Ошибка подключения: $errorMessage');
    }
  }

  @override
  Future<bool> isAuthenticated() async {
    try {
      final token = await _storage.read(StorageKeys.accessToken);
      return token != null && token.isNotEmpty;
    } catch (e) {
      return false;
    }
  }
}

