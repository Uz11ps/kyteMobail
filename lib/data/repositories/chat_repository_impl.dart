import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../domain/repositories/chat_repository.dart';
import '../models/chat_model.dart';
import '../models/message_model.dart';
import '../../core/constants/api_endpoints.dart';
import '../../core/utils/storage_keys.dart';

class ChatRepositoryImpl implements ChatRepository {
  final Dio _dio;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  ChatRepositoryImpl(this._dio);

  List<dynamic> _extractList(dynamic data, {required String key}) {
    if (data is List) return data;
    if (data is Map) {
      final inner = data[key] ?? data['data'] ?? data['items'] ?? data['result'];
      if (inner is List) return inner;
    }
    return const [];
  }

  String _extractErrorMessage(dynamic data, String fallback) {
    if (data is Map && data['message'] != null) return data['message'].toString();
    if (data is String && data.trim().isNotEmpty) {
      final s = data.trim();
      final lower = s.toLowerCase();
      if (lower.contains('<!doctype html') ||
          lower.contains('<html') ||
          lower.contains('cannot get')) {
        return 'API недоступен по ожидаемому адресу. Проверьте, что baseUrl указывает на /api (например: http://10.0.2.2:3000/api).';
      }
      return s;
    }
    return fallback;
  }

  @override
  Future<List<ChatModel>> getChats() async {
    try {
      final response = await _dio.get(ApiEndpoints.chats);
      final data = _extractList(response.data, key: 'chats');
      return data
          .whereType<Map<String, dynamic>>()
          .map(ChatModel.fromJson)
          .toList();
    } on DioException catch (e) {
      throw Exception(
        _extractErrorMessage(e.response?.data, 'Ошибка загрузки чатов'),
      );
    }
  }

  @override
  Future<List<MessageModel>> getMessages(String chatId, {int limit = 100}) async {
    try {
      final response = await _dio.get(
        ApiEndpoints.messagesForChat(chatId),
        queryParameters: {'limit': limit},
      );
      final data = _extractList(response.data, key: 'messages');
      return data
          .whereType<Map<String, dynamic>>()
          .map(MessageModel.fromJson)
          .toList();
    } on DioException catch (e) {
      throw Exception(
        _extractErrorMessage(e.response?.data, 'Ошибка загрузки сообщений'),
      );
    }
  }

  @override
  Future<MessageModel> sendMessage(String chatId, String content) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.sendMessageToChat(chatId),
        data: {'content': content},
      );
      return MessageModel.fromJson(response.data['message']);
    } on DioException catch (e) {
      throw Exception(
        _extractErrorMessage(e.response?.data, 'Ошибка отправки сообщения'),
      );
    }
  }

  @override
  Future<ChatModel> createGroup(String name, List<String> participantIds) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.createGroup,
        data: {
          'name': name,
          'participantIds': participantIds,
        },
      );
      return ChatModel.fromJson(response.data['group']);
    } on DioException catch (e) {
      throw Exception(
        _extractErrorMessage(e.response?.data, 'Ошибка создания группы'),
      );
    }
  }

  @override
  Future<ChatModel> joinGroup(String inviteCode) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.joinGroup,
        data: {'inviteCode': inviteCode},
      );
      return ChatModel.fromJson(response.data['group']);
    } on DioException catch (e) {
      throw Exception(
        _extractErrorMessage(e.response?.data, 'Ошибка присоединения к группе'),
      );
    }
  }
}

