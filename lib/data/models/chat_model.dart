import 'package:json_annotation/json_annotation.dart';

part 'chat_model.g.dart';

enum ChatType {
  @JsonValue('direct')
  direct,
  @JsonValue('group')
  group,
}

@JsonSerializable()
class ChatModel {
  final String id;
  final String name;
  final ChatType type;
  final List<String> participantIds;
  final String? inviteCode;
  final DateTime createdAt;
  final DateTime? lastMessageAt;
  final String? lastMessage;
  final int? unreadCount;
  final int? likesCount;
  final int? meetingsCount;

  ChatModel({
    required this.id,
    required this.name,
    required this.type,
    required this.participantIds,
    required this.createdAt,
    this.inviteCode,
    this.lastMessageAt,
    this.lastMessage,
    this.unreadCount,
    this.likesCount,
    this.meetingsCount,
  });

  factory ChatModel.fromJson(Map<String, dynamic> json) =>
      _$ChatModelFromJson(json);

  Map<String, dynamic> toJson() => _$ChatModelToJson(this);
}

