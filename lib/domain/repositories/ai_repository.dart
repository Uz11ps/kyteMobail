import '../../data/models/message_model.dart';

abstract class AIRepository {
  Future<MessageModel> askAI(String chatId, String question);
  Future<List<MessageModel>> getAISuggestions(String chatId);
}

