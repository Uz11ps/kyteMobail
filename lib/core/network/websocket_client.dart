import 'dart:async';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/app_config.dart';
import '../utils/storage_keys.dart';

class WebSocketClient {
  WebSocketChannel? _channel;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
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
    final token = await _storage.read(key: StorageKeys.accessToken);
    if (token == null) {
      throw Exception('No access token available');
    }

    // Socket.io формат для backend
    final wsUrl = '${AppConfig.wsBaseUrl}/?chatId=$chatId&token=$token';
    
    _channel = WebSocketChannel.connect(Uri.parse(wsUrl));

    if (_channel != null) {
      _channel!.stream.listen(
        (message) {
          _messageController?.add(message);
        },
        onError: (error) {
          _messageController?.addError(error);
        },
        onDone: () {
          _messageController?.close();
        },
      );
    }
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

