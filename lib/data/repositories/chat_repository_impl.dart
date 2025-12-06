import 'package:dio/dio.dart';
import '../../domain/repositories/chat_repository.dart';
import '../models/chat_model.dart';
import '../models/message_model.dart';
import '../../core/constants/api_endpoints.dart';

class ChatRepositoryImpl implements ChatRepository {
  final Dio _dio;

  ChatRepositoryImpl(this._dio);

  @override
  Future<List<ChatModel>> getChats() async {
    // Демо-режим: возвращаем тестовые чаты
    try {
      final response = await _dio.get(ApiEndpoints.chats);
      final List<dynamic> data = response.data['chats'] ?? [];
      return data.map((json) => ChatModel.fromJson(json)).toList();
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout || 
          e.type == DioExceptionType.connectionError) {
        // Демо-режим: возвращаем тестовые данные
        return [
          ChatModel(
            id: 'demo-chat-1',
            name: 'Демо чат 1',
            type: ChatType.group,
            participantIds: ['demo-user-123'],
            createdAt: DateTime.now().subtract(const Duration(days: 1)),
            lastMessageAt: DateTime.now().subtract(const Duration(hours: 2)),
            lastMessage: 'Привет! Это демо-сообщение',
            inviteCode: 'DEMO123',
          ),
          ChatModel(
            id: 'demo-chat-2',
            name: 'Демо чат 2',
            type: ChatType.direct,
            participantIds: ['demo-user-123', 'demo-user-456'],
            createdAt: DateTime.now().subtract(const Duration(days: 2)),
            lastMessageAt: DateTime.now().subtract(const Duration(minutes: 30)),
            lastMessage: 'Как дела?',
          ),
        ];
      }
      throw Exception(e.response?.data['message'] ?? 'Ошибка загрузки чатов');
    }
  }

  @override
  Future<List<MessageModel>> getMessages(String chatId, {int limit = 100}) async {
    // Демо-режим: возвращаем тестовые сообщения
    try {
      final response = await _dio.get(
        ApiEndpoints.messagesForChat(chatId),
        queryParameters: {'limit': limit},
      );
      final List<dynamic> data = response.data['messages'] ?? [];
      return data.map((json) => MessageModel.fromJson(json)).toList();
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout || 
          e.type == DioExceptionType.connectionError) {
        // Демо-режим: возвращаем тестовые сообщения
        return [
          MessageModel(
            id: 'msg-1',
            chatId: chatId,
            userId: 'demo-user-123',
            userName: 'Тестовый пользователь',
            content: 'Привет! Это демо-приложение.',
            type: MessageType.text,
            createdAt: DateTime.now().subtract(const Duration(hours: 2)),
          ),
          MessageModel(
            id: 'msg-2',
            chatId: chatId,
            userId: 'demo-user-456',
            userName: 'Другой пользователь',
            content: 'Отлично выглядит!',
            type: MessageType.text,
            createdAt: DateTime.now().subtract(const Duration(hours: 1)),
          ),
          MessageModel(
            id: 'msg-3',
            chatId: chatId,
            userId: 'ai-user',
            userName: 'AI',
            content: 'Я могу помочь с вопросами! Попробуйте нажать кнопку AI.',
            type: MessageType.ai,
            createdAt: DateTime.now().subtract(const Duration(minutes: 30)),
          ),
        ];
      }
      throw Exception(e.response?.data['message'] ?? 'Ошибка загрузки сообщений');
    }
  }

  @override
  Future<MessageModel> sendMessage(String chatId, String content) async {
    // Демо-режим: создаем mock сообщение
    try {
      final response = await _dio.post(
        ApiEndpoints.sendMessageToChat(chatId),
        data: {'content': content},
      );
      return MessageModel.fromJson(response.data['message']);
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout || 
          e.type == DioExceptionType.connectionError) {
        // Демо-режим: создаем mock сообщение
        return MessageModel(
          id: 'msg-${DateTime.now().millisecondsSinceEpoch}',
          chatId: chatId,
          userId: 'demo-user-123',
          userName: 'Тестовый пользователь',
          content: content,
          type: MessageType.text,
          createdAt: DateTime.now(),
        );
      }
      throw Exception(e.response?.data['message'] ?? 'Ошибка отправки сообщения');
    }
  }

  @override
  Future<ChatModel> createGroup(String name, List<String> participantIds) async {
    // Демо-режим: создаем mock группу
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
      if (e.type == DioExceptionType.connectionTimeout || 
          e.type == DioExceptionType.connectionError) {
        // Демо-режим: создаем mock группу
        return ChatModel(
          id: 'group-${DateTime.now().millisecondsSinceEpoch}',
          name: name,
          type: ChatType.group,
          participantIds: ['demo-user-123', ...participantIds],
          inviteCode: 'DEMO${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
          createdAt: DateTime.now(),
        );
      }
      throw Exception(e.response?.data['message'] ?? 'Ошибка создания группы');
    }
  }

  @override
  Future<ChatModel> joinGroup(String inviteCode) async {
    // Демо-режим: создаем mock группу при присоединении
    try {
      final response = await _dio.post(
        ApiEndpoints.joinGroup,
        data: {'inviteCode': inviteCode},
      );
      return ChatModel.fromJson(response.data['group']);
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout || 
          e.type == DioExceptionType.connectionError) {
        // Демо-режим: создаем mock группу
        return ChatModel(
          id: 'group-joined-${DateTime.now().millisecondsSinceEpoch}',
          name: 'Присоединенная группа',
          type: ChatType.group,
          participantIds: ['demo-user-123'],
          inviteCode: inviteCode,
          createdAt: DateTime.now(),
        );
      }
      throw Exception(e.response?.data['message'] ?? 'Ошибка присоединения к группе');
    }
  }
}

