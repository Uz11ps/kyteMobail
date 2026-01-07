import '../../data/models/meeting_model.dart';

abstract class MeetingRepository {
  Future<List<MeetingModel>> getCalendarEvents({String? chatId, DateTime? startDate, DateTime? endDate});
  Future<String> createMeeting({required String chatId});
}






