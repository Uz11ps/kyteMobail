part of 'chat_bloc.dart';

abstract class ChatState extends Equatable {
  const ChatState();

  @override
  List<Object> get props => [];
}

class ChatInitial extends ChatState {}

class ChatLoading extends ChatState {}

class ChatsLoaded extends ChatState {
  final List<ChatModel> chats;

  const ChatsLoaded({required this.chats});

  @override
  List<Object> get props => [chats];
}

class MessagesLoaded extends ChatState {
  final List<MessageModel> messages;

  const MessagesLoaded({required this.messages});

  @override
  List<Object> get props => [messages];
}

class GroupCreated extends ChatState {
  final ChatModel group;

  const GroupCreated({required this.group});

  @override
  List<Object> get props => [group];
}

class GroupJoined extends ChatState {
  final ChatModel group;

  const GroupJoined({required this.group});

  @override
  List<Object> get props => [group];
}

class ChatError extends ChatState {
  final String message;

  const ChatError({required this.message});

  @override
  List<Object> get props => [message];
}

