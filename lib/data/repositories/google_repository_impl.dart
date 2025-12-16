import 'package:dio/dio.dart';
import '../../domain/repositories/google_repository.dart';
import '../../core/constants/api_endpoints.dart';
import '../../core/utils/storage_keys.dart';
import '../../core/storage/storage_service.dart';

class GoogleRepositoryImpl implements GoogleRepository {
  final Dio _dio;
  final StorageService _storage = StorageService.instance;

  GoogleRepositoryImpl(this._dio);

  @override
  Future<void> submitGmailToken(String token) async {
    try {
      await _dio.post(
        ApiEndpoints.submitGmailToken,
        data: {'token': token},
      );
      await _storage.write(StorageKeys.gmailOAuthToken, token);
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Ошибка отправки токена');
    }
  }

  @override
  Future<String?> getGmailToken() async {
    return await _storage.read(StorageKeys.gmailOAuthToken);
  }

  @override
  Future<String> createGoogleMeet() async {
    try {
      final response = await _dio.post(
        ApiEndpoints.createGoogleMeet,
        data: {},
      );
      return response.data['meetUrl'] as String;
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Ошибка создания Google Meet');
    }
  }
}

