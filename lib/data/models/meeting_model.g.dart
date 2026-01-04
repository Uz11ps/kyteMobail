// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'meeting_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MeetingModel _$MeetingModelFromJson(Map<String, dynamic> json) => MeetingModel(
      id: json['id'] as String,
      summary: json['summary'] as String,
      description: json['description'] as String,
      start: DateTime.parse(json['start'] as String),
      end: DateTime.parse(json['end'] as String),
      location: json['location'] as String?,
      meetUrl: json['meetUrl'] as String?,
      htmlLink: json['htmlLink'] as String?,
      attendees: (json['attendees'] as List<dynamic>)
          .map((e) => AttendeeModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$MeetingModelToJson(MeetingModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'summary': instance.summary,
      'description': instance.description,
      'start': instance.start.toIso8601String(),
      'end': instance.end.toIso8601String(),
      'location': instance.location,
      'meetUrl': instance.meetUrl,
      'htmlLink': instance.htmlLink,
      'attendees': instance.attendees,
    };

AttendeeModel _$AttendeeModelFromJson(Map<String, dynamic> json) =>
    AttendeeModel(
      email: json['email'] as String,
      displayName: json['displayName'] as String?,
      responseStatus: json['responseStatus'] as String?,
    );

Map<String, dynamic> _$AttendeeModelToJson(AttendeeModel instance) =>
    <String, dynamic>{
      'email': instance.email,
      'displayName': instance.displayName,
      'responseStatus': instance.responseStatus,
    };
