import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../domain/repositories/ai_repository.dart';
import '../../../data/models/message_model.dart';

part 'ai_event.dart';
part 'ai_state.dart';

class AIBloc extends Bloc<AIEvent, AIState> {
  final AIRepository aiRepository;

  AIBloc({required this.aiRepository}) : super(AIInitial()) {
    on<AskAIRequested>(_onAskAIRequested);
    on<AISuggestionsRequested>(_onAISuggestionsRequested);
  }

  Future<void> _onAskAIRequested(
    AskAIRequested event,
    Emitter<AIState> emit,
  ) async {
    emit(AILoading());
    try {
      final message = await aiRepository.askAI(event.chatId, event.question);
      emit(AIResponseReceived(message: message));
    } catch (e) {
      emit(AIError(message: e.toString()));
    }
  }

  Future<void> _onAISuggestionsRequested(
    AISuggestionsRequested event,
    Emitter<AIState> emit,
  ) async {
    emit(AILoading());
    try {
      final suggestions = await aiRepository.getAISuggestions(event.chatId);
      emit(AISuggestionsReceived(suggestions: suggestions));
    } catch (e) {
      emit(AIError(message: e.toString()));
    }
  }
}

