import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/app_config.dart';
import '../constants/api_endpoints.dart';
import '../utils/storage_keys.dart';

class ApiClient {
  late final Dio _dio;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  Future<bool>? _refreshInFlight;

  ApiClient() {
    _dio = Dio(
      BaseOptions(
        baseUrl: _normalizeApiBaseUrl(AppConfig.apiBaseUrl),
        connectTimeout: const Duration(seconds: 10), // Уменьшено для быстрой отладки
        receiveTimeout: const Duration(seconds: 10), // Уменьшено для быстрой отладки
        headers: {
          'Content-Type': 'application/json',
        },
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Не добавляем токен для login и register запросов
          final isAuthRequest = options.path.contains('/auth/login') || 
                                options.path.contains('/auth/register');
          
          if (!isAuthRequest) {
            final token = await _storage.read(key: StorageKeys.accessToken);
            if (token != null) {
              options.headers['Authorization'] = 'Bearer $token';
            }
          }
          
          // Логирование для отладки
          final fullUrl = '${options.baseUrl}${options.path}';
          print('🌐 API Request: ${options.method} $fullUrl');
          if (options.data != null) {
            print('📦 Request Data: ${options.data}');
          }
          if (options.headers['Authorization'] != null) {
            print('🔑 Authorization: ${options.headers['Authorization']?.substring(0, 20)}...');
          }
          
          return handler.next(options);
        },
        onResponse: (response, handler) {
          print('✅ API Response: ${response.statusCode} ${response.requestOptions.path}');
          if (response.data != null) {
            print('📥 Response Data: ${response.data}');
          }
          return handler.next(response);
        },
        onError: (error, handler) async {
          // Логирование ошибок для отладки
          print('❌ API Error: ${error.requestOptions.method} ${error.requestOptions.baseUrl}${error.requestOptions.path}');
          print('   Status: ${error.response?.statusCode}');
          print('   Message: ${error.response?.data ?? error.message}');
          
          final isUnauthorized = error.response?.statusCode == 401;
          final isRefreshRequest = error.requestOptions.path.endsWith(ApiEndpoints.refreshToken);
          final skipRefresh = error.requestOptions.extra['skipAuthRefresh'] == true;

          if (isUnauthorized && !isRefreshRequest && !skipRefresh) {
            // Попытка обновить токен
            final refreshed = await (_refreshInFlight ??= _refreshToken());
            _refreshInFlight = null;
            if (refreshed) {
              final token = await _storage.read(key: StorageKeys.accessToken);
              if (token != null && token.isNotEmpty) {
                error.requestOptions.headers['Authorization'] = 'Bearer $token';
                return handler.resolve(await _dio.fetch(error.requestOptions));
              }
            }
          }
          return handler.next(error);
        },
      ),
    );
  }

  static String _normalizeApiBaseUrl(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return trimmed;

    Uri uri;
    try {
      uri = Uri.parse(trimmed);
    } catch (_) {
      return trimmed;
    }

    final segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();
    if (segments.isNotEmpty && segments.last == 'api') {
      return uri.toString();
    }

    final nextSegments = [...segments, 'api'];
    final normalized = uri.replace(pathSegments: nextSegments);
    return normalized.toString();
  }

  Future<bool> _refreshToken() async {
    try {
      final refreshToken = await _storage.read(key: StorageKeys.refreshToken);
      if (refreshToken == null) return false;

      final response = await _dio.post(
        ApiEndpoints.refreshToken,
        options: Options(extra: {'skipAuthRefresh': true}),
        data: {'refreshToken': refreshToken},
      );

      if (response.statusCode == 200) {
        final accessToken = response.data?['accessToken'];
        if (accessToken != null && accessToken.toString().isNotEmpty) {
          await _storage.write(
            key: StorageKeys.accessToken,
            value: accessToken.toString(),
          );
          return true;
        }
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Dio get dio => _dio;
}

