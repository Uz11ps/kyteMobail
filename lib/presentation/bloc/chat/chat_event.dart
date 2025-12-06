part of 'chat_bloc.dart';

abstract class ChatEvent extends Equatable {
  const ChatEvent();

  @override
  List<Object> get props => [];
}

class ChatsLoadRequested extends ChatEvent {}

class MessagesLoadRequested extends ChatEvent {
  final String chatId;

  const MessagesLoadRequested({required this.chatId});

  @override
  List<Object> get props => [chatId];
}

class MessageSent extends ChatEvent {
  final String chatId;
  final String content;

  const MessageSent({
    required this.chatId,
    required this.content,
  });

  @override
  List<Object> get props => [chatId, content];
}

class MessageReceived extends ChatEvent {
  final MessageModel message;

  const MessageReceived({required this.message});

  @override
  List<Object> get props => [message];
}

class GroupCreateRequested extends ChatEvent {
  final String name;
  final List<String> participantIds;

  const GroupCreateRequested({
    required this.name,
    required this.participantIds,
  });

  @override
  List<Object> get props => [name, participantIds];
}

class GroupJoinRequested extends ChatEvent {
  final String inviteCode;

  const GroupJoinRequested({required this.inviteCode});

  @override
  List<Object> get props => [inviteCode];
}

