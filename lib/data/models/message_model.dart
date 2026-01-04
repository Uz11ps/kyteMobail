import 'package:json_annotation/json_annotation.dart';

part 'message_model.g.dart';

enum MessageType {
  @JsonValue('text')
  text,
  @JsonValue('ai')
  ai,
  @JsonValue('system')
  system,
  @JsonValue('file')
  file,
  @JsonValue('image')
  image,
}

@JsonSerializable()
class MessageModel {
  final String id;
  final String chatId;
  final String userId;
  final String? userName;
  final String content;
  final MessageType type;
  final DateTime createdAt;
  final Map<String, dynamic>? metadata;
  final String? fileUrl;
  final String? fileName;
  final int? fileSize;

  MessageModel({
    required this.id,
    required this.chatId,
    required this.userId,
    required this.content,
    required this.type,
    required this.createdAt,
    this.userName,
    this.metadata,
    this.fileUrl,
    this.fileName,
    this.fileSize,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) =>
      _$MessageModelFromJson(json);

  Map<String, dynamic> toJson() => _$MessageModelToJson(this);

  bool get isAIMessage => type == MessageType.ai;
  bool get isSystemMessage => type == MessageType.system;
  bool get isFileMessage => type == MessageType.file;
  bool get isImageMessage => type == MessageType.image;
}

