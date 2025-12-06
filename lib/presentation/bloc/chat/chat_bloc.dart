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
    emit(ChatLoading());
    try {
      final chats = await chatRepository.getChats();
      emit(ChatsLoaded(chats: chats));
    } catch (e) {
      emit(ChatError(message: e.toString()));
    }
  }

  Future<void> _onMessagesLoadRequested(
    MessagesLoadRequested event,
    Emitter<ChatState> emit,
  ) async {
    emit(ChatLoading());
    try {
      final messages = await chatRepository.getMessages(event.chatId);
      emit(MessagesLoaded(messages: messages));
    } catch (e) {
      emit(ChatError(message: e.toString()));
    }
  }

  Future<void> _onMessageSent(
    MessageSent event,
    Emitter<ChatState> emit,
  ) async {
    try {
      final message = await chatRepository.sendMessage(event.chatId, event.content);
      // В демо-режиме сразу добавляем сообщение в список
      final currentState = state;
      if (currentState is MessagesLoaded) {
        emit(MessagesLoaded(messages: [...currentState.messages, message]));
      } else {
        add(MessagesLoadRequested(chatId: event.chatId));
      }
    } catch (e) {
      emit(ChatError(message: e.toString()));
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
    emit(ChatLoading());
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
    emit(ChatLoading());
    try {
      final group = await chatRepository.joinGroup(event.inviteCode);
      emit(GroupJoined(group: group));
    } catch (e) {
      emit(ChatError(message: e.toString()));
    }
  }
}

