part of 'ai_bloc.dart';

abstract class AIEvent extends Equatable {
  const AIEvent();

  @override
  List<Object> get props => [];
}

class AskAIRequested extends AIEvent {
  final String chatId;
  final String question;

  const AskAIRequested({
    required this.chatId,
    required this.question,
  });

  @override
  List<Object> get props => [chatId, question];
}

class AISuggestionsRequested extends AIEvent {
  final String chatId;

  const AISuggestionsRequested({required this.chatId});

  @override
  List<Object> get props => [chatId];
}

