part of 'ai_bloc.dart';

abstract class AIState extends Equatable {
  const AIState();

  @override
  List<Object> get props => [];
}

class AIInitial extends AIState {}

class AILoading extends AIState {}

class AIResponseReceived extends AIState {
  final MessageModel message;

  const AIResponseReceived({required this.message});

  @override
  List<Object> get props => [message];
}

class AISuggestionsReceived extends AIState {
  final List<MessageModel> suggestions;

  const AISuggestionsReceived({required this.suggestions});

  @override
  List<Object> get props => [suggestions];
}

class AIError extends AIState {
  final String message;

  const AIError({required this.message});

  @override
  List<Object> get props => [message];
}

