import 'package:dio/dio.dart';
import '../../domain/repositories/chat_repository.dart';
import '../models/chat_model.dart';
import '../models/message_model.dart';
import '../../core/constants/api_endpoints.dart';
import '../../core/utils/storage_keys.dart';
import '../../core/storage/storage_service.dart';

class ChatRepositoryImpl implements ChatRepository {
  final Dio _dio;
  final StorageService _storage = StorageService.instance;

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
      print('📋 Loading chats...');
      final response = await _dio.get(ApiEndpoints.chats);
      print('✅ Chats response: ${response.statusCode}');
      print('   Data: ${response.data}');
      
      if (response.data == null) {
        print('⚠️ Response data is null');
        return [];
      }
      
      final data = _extractList(response.data, key: 'chats');
      print('📋 Extracted ${data.length} chats');
      
      final chats = data
          .whereType<Map<String, dynamic>>()
          .map((json) {
            try {
              return ChatModel.fromJson(json);
            } catch (e) {
              print('❌ Error parsing chat: $e, json: $json');
              return null;
            }
          })
          .whereType<ChatModel>()
          .toList();
      
      print('✅ Parsed ${chats.length} chats successfully');
      return chats;
    } on DioException catch (e) {
      print('❌ DioException loading chats: ${e.type}');
      print('   Status: ${e.response?.statusCode}');
      print('   Data: ${e.response?.data}');
      print('   Message: ${e.message}');
      throw Exception(
        _extractErrorMessage(e.response?.data, 'Ошибка загрузки чатов'),
      );
    } catch (e) {
      print('❌ Unexpected error loading chats: $e');
      throw Exception('Ошибка загрузки чатов: ${e.toString()}');
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
      if (response.data == null || response.data['message'] == null) {
        throw Exception('Ответ сервера не содержит данных сообщения');
      }
      return MessageModel.fromJson(response.data['message']);
    } on DioException catch (e) {
      throw Exception(
        _extractErrorMessage(e.response?.data, 'Ошибка отправки сообщения'),
      );
    } catch (e) {
      throw Exception('Ошибка отправки сообщения: ${e.toString()}');
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
      if (response.data == null || response.data['group'] == null) {
        throw Exception('Ответ сервера не содержит данных группы');
      }
      return ChatModel.fromJson(response.data['group']);
    } on DioException catch (e) {
      throw Exception(
        _extractErrorMessage(e.response?.data, 'Ошибка создания группы'),
      );
    } catch (e) {
      throw Exception('Ошибка создания группы: ${e.toString()}');
    }
  }

  @override
  Future<ChatModel> joinGroup(String inviteCode) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.joinGroup,
        data: {'inviteCode': inviteCode},
      );
      if (response.data == null || response.data['group'] == null) {
        throw Exception('Ответ сервера не содержит данных группы');
      }
      return ChatModel.fromJson(response.data['group']);
    } on DioException catch (e) {
      throw Exception(
        _extractErrorMessage(e.response?.data, 'Ошибка присоединения к группе'),
      );
    } catch (e) {
      throw Exception('Ошибка присоединения к группе: ${e.toString()}');
    }
  }
}

