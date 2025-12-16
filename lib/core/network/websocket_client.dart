import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../config/app_config.dart';
import '../utils/storage_keys.dart';
import '../storage/storage_service.dart';

class WebSocketClient {
  WebSocketChannel? _channel;
  final StorageService _storage = StorageService.instance;
  StreamController<dynamic>? _messageController;
  Stream<dynamic>? _messageStream;

  Stream<dynamic> get messageStream {
    _messageController ??= StreamController<dynamic>.broadcast();
    if (_messageStream == null) {
      _messageStream = _messageController!.stream;
    }
    return _messageStream!;
  }

  Future<void> connect(String chatId) async {
    final token = await _storage.read(StorageKeys.accessToken);
    if (token == null) {
      throw Exception('No access token available');
    }

    // Для веб Socket.io использует HTTP polling вместо WebSocket
    // Временно отключаем WebSocket для веб, используем только HTTP polling через периодические запросы
    // TODO: Добавить socket_io_client для полноценной поддержки Socket.io
    
    // Пока WebSocket не работает на веб, просто создаем пустой стрим
    // Сообщения будут приходить через HTTP запросы
    debugPrint('⚠️ WebSocket подключение временно отключено для веб-платформы');
    debugPrint('   Сообщения будут обновляться через HTTP запросы');
  }

  void sendMessage(dynamic message) {
    _channel?.sink.add(message);
  }

  void disconnect() {
    _channel?.sink.close();
    _channel = null;
    _messageController?.close();
    _messageController = null;
    _messageStream = null;
  }

  bool get isConnected => _channel != null;
}

