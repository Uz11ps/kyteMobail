import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../domain/repositories/google_repository.dart';
import '../../core/constants/api_endpoints.dart';
import '../../core/utils/storage_keys.dart';

class GoogleRepositoryImpl implements GoogleRepository {
  final Dio _dio;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  GoogleRepositoryImpl(this._dio);

  @override
  Future<void> submitGmailToken(String token) async {
    try {
      await _dio.post(
        ApiEndpoints.submitGmailToken,
        data: {'token': token},
      );
      await _storage.write(
        key: StorageKeys.gmailOAuthToken,
        value: token,
      );
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Ошибка отправки токена');
    }
  }

  @override
  Future<String?> getGmailToken() async {
    return await _storage.read(key: StorageKeys.gmailOAuthToken);
  }

  @override
  Future<String> createGoogleMeet() async {
    try {
      final response = await _dio.post(
        '/google/meet/create',
        data: {},
      );
      return response.data['meetUrl'] as String;
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Ошибка создания Google Meet');
    }
  }
}

