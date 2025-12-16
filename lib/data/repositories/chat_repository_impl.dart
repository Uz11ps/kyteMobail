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

  Future<bool> _isDemoMode() async {
    final token = await _storage.read(key: StorageKeys.accessToken);
    return token != null && token.startsWith('demo-token-');
  }

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
    // Демо-режим: если залогинены демо-токеном, не ходим на backend.
    if (await _isDemoMode()) {
      return _demoChats();
    }

    try {
      final response = await _dio.get(ApiEndpoints.chats);
      final data = _extractList(response.data, key: 'chats');
      return data
          .whereType<Map<String, dynamic>>()
          .map(ChatModel.fromJson)
          .toList();
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout || 
          e.type == DioExceptionType.connectionError) {
        // Демо-режим: возвращаем тестовые данные
        return _demoChats();
      }
      throw Exception(
        _extractErrorMessage(e.response?.data, 'Ошибка загрузки чатов'),
      );
    }
  }

  @override
  Future<List<MessageModel>> getMessages(String chatId, {int limit = 100}) async {
    // Демо-режим: если залогинены демо-токеном, не ходим на backend.
    if (await _isDemoMode()) {
      return _demoMessages(chatId);
    }

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
      if (e.type == DioExceptionType.connectionTimeout || 
          e.type == DioExceptionType.connectionError) {
        // Демо-режим: возвращаем тестовые сообщения
        return _demoMessages(chatId);
      }
      throw Exception(
        _extractErrorMessage(e.response?.data, 'Ошибка загрузки сообщений'),
      );
    }
  }

  @override
  Future<MessageModel> sendMessage(String chatId, String content) async {
    // Демо-режим: создаем mock сообщение
    if (await _isDemoMode()) {
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
      throw Exception(
        _extractErrorMessage(e.response?.data, 'Ошибка отправки сообщения'),
      );
    }
  }

  @override
  Future<ChatModel> createGroup(String name, List<String> participantIds) async {
    // Демо-режим: создаем mock группу
    if (await _isDemoMode()) {
      return ChatModel(
        id: 'group-${DateTime.now().millisecondsSinceEpoch}',
        name: name,
        type: ChatType.group,
        participantIds: ['demo-user-123', ...participantIds],
        inviteCode: 'DEMO${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
        createdAt: DateTime.now(),
      );
    }

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
      throw Exception(
        _extractErrorMessage(e.response?.data, 'Ошибка создания группы'),
      );
    }
  }

  @override
  Future<ChatModel> joinGroup(String inviteCode) async {
    // Демо-режим: создаем mock группу при присоединении
    if (await _isDemoMode()) {
      return ChatModel(
        id: 'group-joined-${DateTime.now().millisecondsSinceEpoch}',
        name: 'Присоединенная группа',
        type: ChatType.group,
        participantIds: ['demo-user-123'],
        inviteCode: inviteCode,
        createdAt: DateTime.now(),
      );
    }

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
      throw Exception(
        _extractErrorMessage(e.response?.data, 'Ошибка присоединения к группе'),
      );
    }
  }

  List<ChatModel> _demoChats() {
    return [
      ChatModel(
        id: 'demo-chat-1',
        name: 'Kyte.me MVP',
        type: ChatType.group,
        participantIds: ['demo-user-123', 'dmitry@example.com'],
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        lastMessageAt: DateTime.now().subtract(const Duration(minutes: 18)),
        lastMessage: 'Календарь и планирование: 📅 Google Calendar — синх…',
        inviteCode: 'DEMO123',
      ),
    ];
  }

  List<MessageModel> _demoMessages(String chatId) {
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
}

