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
  final String? fileUrl;
  final String? fileName;
  final int? fileSize;
  final MessageType type;

  const MessageSent({
    required this.chatId,
    required this.content,
    this.fileUrl,
    this.fileName,
    this.fileSize,
    this.type = MessageType.text,
  });

  @override
  List<Object> get props => [
        chatId,
        content,
        fileUrl ?? '',
        fileName ?? '',
        fileSize ?? 0,
        type,
      ];
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
  final String? description;

  const GroupCreateRequested({
    required this.name,
    required this.participantIds,
    this.description,
  });

  @override
  List<Object> get props => [name, participantIds, description ?? ''];
}

class GroupJoinRequested extends ChatEvent {
  final String inviteCode;

  const GroupJoinRequested({required this.inviteCode});

  @override
  List<Object> get props => [inviteCode];
}

