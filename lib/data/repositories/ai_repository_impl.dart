import 'package:dio/dio.dart';
import '../../domain/repositories/ai_repository.dart';
import '../models/message_model.dart';
import '../../core/constants/api_endpoints.dart';

class AIRepositoryImpl implements AIRepository {
  final Dio _dio;

  AIRepositoryImpl(this._dio);

  @override
  Future<MessageModel> askAI(String chatId, String question) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.askAI,
        data: {
          'chatId': chatId,
          'question': question,
        },
      );
      return MessageModel.fromJson(response.data['message']);
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Ошибка запроса к AI');
    }
  }

  @override
  Future<List<MessageModel>> getAISuggestions(String chatId) async {
    try {
      final response = await _dio.get(
        ApiEndpoints.aiSuggestions,
        queryParameters: {'chatId': chatId},
      );
      final List<dynamic> data = response.data['suggestions'] ?? [];
      return data.map((json) => MessageModel.fromJson(json)).toList();
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Ошибка получения предложений AI');
    }
  }
}

