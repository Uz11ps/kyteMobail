import 'package:json_annotation/json_annotation.dart';

part 'meeting_model.g.dart';

@JsonSerializable()
class MeetingModel {
  final String id;
  final String summary;
  final String description;
  final DateTime start;
  final DateTime end;
  final String? location;
  final String? meetUrl;
  final String? htmlLink;
  final List<AttendeeModel> attendees;

  MeetingModel({
    required this.id,
    required this.summary,
    required this.description,
    required this.start,
    required this.end,
    this.location,
    this.meetUrl,
    this.htmlLink,
    required this.attendees,
  });

  factory MeetingModel.fromJson(Map<String, dynamic> json) =>
      _$MeetingModelFromJson(json);

  Map<String, dynamic> toJson() => _$MeetingModelToJson(this);
}

@JsonSerializable()
class AttendeeModel {
  final String email;
  final String? displayName;
  final String? responseStatus;

  AttendeeModel({
    required this.email,
    this.displayName,
    this.responseStatus,
  });

  factory AttendeeModel.fromJson(Map<String, dynamic> json) =>
      _$AttendeeModelFromJson(json);

  Map<String, dynamic> toJson() => _$AttendeeModelToJson(this);
}






