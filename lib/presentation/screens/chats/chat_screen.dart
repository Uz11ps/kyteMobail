import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../bloc/chat/chat_bloc.dart';
import '../../bloc/ai/ai_bloc.dart';
import '../../bloc/google/google_bloc.dart';
import '../../../data/models/message_model.dart';
import '../../../core/di/service_locator.dart';
import '../../../core/network/websocket_client.dart';
import '../../widgets/ai_meet_button.dart';
import 'dart:convert';

class ChatScreen extends StatefulWidget {
  final String chatId;
  final String chatName;

  const ChatScreen({
    super.key,
    required this.chatId,
    required this.chatName,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final WebSocketClient _wsClient = ServiceLocator().webSocketClient;
  List<MessageModel> _messages = [];
  bool _isAIMode = false;

  @override
  void initState() {
    super.initState();
    context.read<ChatBloc>().add(MessagesLoadRequested(chatId: widget.chatId));
    _connectWebSocket();
  }

  void _connectWebSocket() {
    _wsClient.connect(widget.chatId).then((_) {
      _wsClient.messageStream.listen((message) {
        try {
          // Socket.io отправляет JSON объекты напрямую
          Map<String, dynamic> data;
          if (message is String) {
            data = jsonDecode(message) as Map<String, dynamic>;
          } else if (message is Map) {
            data = message as Map<String, dynamic>;
          } else {
            return;
          }
          
          final messageModel = MessageModel.fromJson(data);
          context.read<ChatBloc>().add(MessageReceived(message: messageModel));
        } catch (e) {
          debugPrint('Ошибка парсинга WebSocket сообщения: $e');
        }
      });
    }).catchError((error) {
      debugPrint('Ошибка подключения WebSocket: $error');
      // В демо-режиме не показываем ошибку пользователю
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _wsClient.disconnect();
    super.dispose();
  }

  void _sendMessage() {
    final content = _messageController.text.trim();
    if (content.isEmpty) return;

    if (_isAIMode) {
      context.read<AIBloc>().add(AskAIRequested(
            chatId: widget.chatId,
            question: content,
          ));
    } else {
      context.read<ChatBloc>().add(MessageSent(
            chatId: widget.chatId,
            content: content,
          ));
    }

    _messageController.clear();
    _isAIMode = false;
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<GoogleBloc, GoogleState>(
      listener: (context, state) {
        if (state is GoogleMeetCreated) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Встреча создана'),
              action: SnackBarAction(
                label: 'Открыть',
                onPressed: () {
                  // Открыть ссылку на встречу
                },
              ),
            ),
          );
        } else if (state is GoogleError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Ошибка Google: ${state.message}')),
          );
        }
      },
      child: BlocListener<AIBloc, AIState>(
        listener: (context, state) {
          if (state is AIResponseReceived) {
            context.read<ChatBloc>().add(MessageReceived(message: state.message));
            
            // Проверка на рекомендацию создания Google Meet
            final metadata = state.message.metadata;
            if (metadata != null && metadata.containsKey('suggestMeet') && metadata['suggestMeet'] == true) {
              context.read<GoogleBloc>().add(GoogleMeetCreateRequested());
            }
          } else if (state is AIError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Ошибка AI: ${state.message}')),
            );
          }
        },
        child: BlocListener<ChatBloc, ChatState>(
          listener: (context, state) {
            if (state is MessagesLoaded) {
              setState(() {
                _messages = state.messages;
              });
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _scrollToBottom();
              });
            }
          },
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.chatName),
          actions: [
            IconButton(
              icon: Icon(_isAIMode ? Icons.smart_toy : Icons.smart_toy_outlined),
              onPressed: () {
                setState(() {
                  _isAIMode = !_isAIMode;
                });
                if (_isAIMode) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Режим AI активирован'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              },
              tooltip: 'Спросить AI',
            ),
          ],
        ),
        body: Column(
          children: [
            Expanded(
              child: BlocBuilder<ChatBloc, ChatState>(
                builder: (context, state) {
                  if (state is ChatLoading && _messages.isEmpty) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (_messages.isEmpty) {
                    return Center(
                      child: Text(
                        'Нет сообщений',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    );
                  }

                  return ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final message = _messages[index];
                      final hasMeetUrl = message.metadata?['meetUrl'] != null;
                      
                      return Column(
                        children: [
                          MessageBubble(message: message),
                          if (hasMeetUrl && message.isAIMessage)
                            Padding(
                              padding: const EdgeInsets.only(top: 8, bottom: 8),
                              child: AIMeetButton(
                                meetUrl: message.metadata!['meetUrl'] as String,
                              ),
                            ),
                        ],
                      );
                    },
                  );
                },
              ),
            ),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: _isAIMode ? 'Спросить AI...' : 'Введите сообщение...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                      ),
                      maxLines: null,
                      textCapitalization: TextCapitalization.sentences,
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: Icon(_isAIMode ? Icons.smart_toy : Icons.send),
                    onPressed: _sendMessage,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      ),
      ),
    );
  }
}

class MessageBubble extends StatelessWidget {
  final MessageModel message;

  const MessageBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final isAIMessage = message.isAIMessage;
    final isSystemMessage = message.isSystemMessage;

    if (isSystemMessage) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceVariant,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              message.content,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: isAIMessage
            ? MainAxisAlignment.start
            : MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (isAIMessage) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(16),
              ),
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.smart_toy,
                        size: 16,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'AI',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: Theme.of(context).colorScheme.onPrimaryContainer,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    message.content,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
          ] else ...[
            const SizedBox(width: 8),
            Flexible(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: BorderRadius.circular(16),
                ),
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.75,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (message.userName != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          message.userName!,
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: Theme.of(context).colorScheme.onPrimary,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ),
                    Text(
                      message.content,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onPrimary,
                          ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

