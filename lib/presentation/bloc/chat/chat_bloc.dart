import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../domain/repositories/chat_repository.dart';
import '../../../data/models/chat_model.dart';
import '../../../data/models/message_model.dart';

part 'chat_event.dart';
part 'chat_state.dart';

class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final ChatRepository chatRepository;

  ChatBloc({required this.chatRepository}) : super(ChatInitial()) {
    on<ChatsLoadRequested>(_onChatsLoadRequested);
    on<MessagesLoadRequested>(_onMessagesLoadRequested);
    on<MessageSent>(_onMessageSent);
    on<MessageReceived>(_onMessageReceived);
    on<GroupCreateRequested>(_onGroupCreateRequested);
    on<GroupJoinRequested>(_onGroupJoinRequested);
  }

  Future<void> _onChatsLoadRequested(
    ChatsLoadRequested event,
    Emitter<ChatState> emit,
  ) async {
    emit(ChatsLoading());
    try {
      final chats = await chatRepository.getChats();
      emit(ChatsLoaded(chats: chats));
    } catch (e) {
      // Если backend недоступен, возвращаем тестовый чат
      print('⚠️ Backend недоступен, используем тестовый чат');
      final testChat = ChatModel(
        id: 'test-chat-001',
        name: 'Тестовый чат',
        type: ChatType.group,
        participantIds: ['test-user-001'],
        createdAt: DateTime.now(),
        lastMessageAt: DateTime.now().subtract(const Duration(minutes: 5)),
        lastMessage: 'Добро пожаловать в тестовый чат!',
        unreadCount: 0,
        likesCount: 0,
        meetingsCount: 0,
      );
      emit(ChatsLoaded(chats: [testChat]));
    }
  }

  Future<void> _onMessagesLoadRequested(
    MessagesLoadRequested event,
    Emitter<ChatState> emit,
  ) async {
    emit(MessagesLoading());
    try {
      print('🔄 Loading messages for chat: ${event.chatId}');
      final messages = await chatRepository.getMessages(event.chatId);
      print('✅ Loaded ${messages.length} messages');
      emit(MessagesLoaded(messages: messages));
    } catch (e) {
      print('❌ Error loading messages: $e');
      // Если это тестовый чат, возвращаем тестовые сообщения
      if (event.chatId == 'test-chat-001') {
        print('📝 Используем тестовые сообщения для тестового чата');
        final testMessages = [
          MessageModel(
            id: 'msg-001',
            chatId: event.chatId,
            userId: 'system',
            userName: 'Система',
            content: 'Добро пожаловать в тестовый чат!',
            createdAt: DateTime.now().subtract(const Duration(hours: 1)),
            type: MessageType.text,
          ),
          MessageModel(
            id: 'msg-002',
            chatId: event.chatId,
            userId: 'test-user',
            userName: 'Тестовый пользователь',
            content: 'Это тестовый чат для демонстрации работы приложения без backend.',
            createdAt: DateTime.now().subtract(const Duration(minutes: 30)),
            type: MessageType.text,
          ),
          MessageModel(
            id: 'msg-003',
            chatId: event.chatId,
            userId: 'system',
            userName: 'Система',
            content: 'Вы можете отправлять сообщения, но они не будут сохранены без подключения к backend.',
            createdAt: DateTime.now().subtract(const Duration(minutes: 5)),
            type: MessageType.text,
          ),
        ];
        emit(MessagesLoaded(messages: testMessages));
      } else {
        emit(ChatError(message: e.toString()));
      }
    }
  }

  Future<void> _onMessageSent(
    MessageSent event,
    Emitter<ChatState> emit,
  ) async {
    try {
      // Если это тестовый чат, просто добавляем сообщение локально
      if (event.chatId == 'test-chat-001') {
        final currentState = state;
        if (currentState is MessagesLoaded) {
          final testMessage = MessageModel(
            id: 'msg-${DateTime.now().millisecondsSinceEpoch}',
            chatId: event.chatId,
            userId: 'current-user',
            userName: 'Вы',
            content: event.content,
            createdAt: DateTime.now(),
            type: event.type,
            fileUrl: event.fileUrl,
            fileName: event.fileName,
            fileSize: event.fileSize,
          );
          emit(MessagesLoaded(messages: [...currentState.messages, testMessage]));
        } else {
          add(MessagesLoadRequested(chatId: event.chatId));
        }
        return;
      }
      
      final message = await chatRepository.sendMessage(
        event.chatId,
        event.content,
        fileUrl: event.fileUrl,
        fileName: event.fileName,
        fileSize: event.fileSize,
        type: event.type,
      );
      // Добавляем сообщение в список и перезагружаем историю для синхронизации
      final currentState = state;
      if (currentState is MessagesLoaded) {
        // Временно добавляем сообщение для мгновенного отображения
        emit(MessagesLoaded(messages: [...currentState.messages, message]));
        // Затем перезагружаем всю историю для синхронизации
        final messages = await chatRepository.getMessages(event.chatId);
        emit(MessagesLoaded(messages: messages));
      } else {
        // Если состояние не MessagesLoaded, просто загружаем сообщения
        add(MessagesLoadRequested(chatId: event.chatId));
      }
    } catch (e) {
      // Для тестового чата не показываем ошибку, просто добавляем сообщение локально
      if (event.chatId == 'test-chat-001') {
        final currentState = state;
        if (currentState is MessagesLoaded) {
          final testMessage = MessageModel(
            id: 'msg-${DateTime.now().millisecondsSinceEpoch}',
            chatId: event.chatId,
            userId: 'current-user',
            userName: 'Вы',
            content: event.content,
            createdAt: DateTime.now(),
            type: event.type,
            fileUrl: event.fileUrl,
            fileName: event.fileName,
            fileSize: event.fileSize,
          );
          emit(MessagesLoaded(messages: [...currentState.messages, testMessage]));
        }
      } else {
        emit(ChatError(message: e.toString()));
      }
    }
  }

  void _onMessageReceived(
    MessageReceived event,
    Emitter<ChatState> emit,
  ) {
    final currentState = state;
    if (currentState is MessagesLoaded) {
      emit(MessagesLoaded(messages: [...currentState.messages, event.message]));
    }
  }

  Future<void> _onGroupCreateRequested(
    GroupCreateRequested event,
    Emitter<ChatState> emit,
  ) async {
    emit(GroupCreateLoading());
    try {
      final group = await chatRepository.createGroup(
        event.name,
        event.participantIds,
      );
      emit(GroupCreated(group: group));
    } catch (e) {
      emit(ChatError(message: e.toString()));
    }
  }

  Future<void> _onGroupJoinRequested(
    GroupJoinRequested event,
    Emitter<ChatState> emit,
  ) async {
    emit(GroupJoinLoading());
    try {
      final group = await chatRepository.joinGroup(event.inviteCode);
      emit(GroupJoined(group: group));
    } catch (e) {
      emit(ChatError(message: e.toString()));
    }
  }
}

