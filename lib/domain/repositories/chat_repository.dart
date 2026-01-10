import '../../data/models/chat_model.dart';
import '../../data/models/message_model.dart';

abstract class ChatRepository {
  Future<List<ChatModel>> getChats();
  Future<List<MessageModel>> getMessages(String chatId, {int limit = 100});
  Future<MessageModel> sendMessage(
    String chatId,
    String content, {
    String? fileUrl,
    String? fileName,
    int? fileSize,
    MessageType type = MessageType.text,
  });
  Future<ChatModel> createGroup(String name, List<String> participantIds, {String? description});
  Future<ChatModel> joinGroup(String inviteCode);
}

