import 'package:dio/dio.dart';
import '../../core/constants/api_endpoints.dart';
import '../../data/models/meeting_model.dart';
import '../../domain/repositories/meeting_repository.dart';

class MeetingRepositoryImpl implements MeetingRepository {
  final Dio _dio;

  MeetingRepositoryImpl(this._dio);

  @override
  Future<List<MeetingModel>> getCalendarEvents({String? chatId, DateTime? startDate, DateTime? endDate}) async {
    try {
      final response = await _dio.get(
        ApiEndpoints.calendarEvents,
        queryParameters: {
          if (chatId != null) 'chatId': chatId,
          if (startDate != null) 'startDate': startDate.toIso8601String(),
          if (endDate != null) 'endDate': endDate.toIso8601String(),
        },
      );

      final data = response.data['events'] as List;
      return data.map((json) => MeetingModel.fromJson(json)).toList();
    } catch (e) {
      print('❌ Error fetching calendar events: $e');
      throw Exception('Не удалось загрузить события календаря');
    }
  }

  @override
  Future<String> createMeeting({required String chatId}) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.createGoogleMeet,
        data: {'chatId': chatId},
      );
      
      if (response.data != null && response.data['meetUrl'] != null) {
        return response.data['meetUrl'];
      }
      throw Exception('Meet URL not found in response');
    } catch (e) {
      print('❌ Error creating meeting: $e');
      throw Exception('Не удалось создать встречу');
    }
  }
}

