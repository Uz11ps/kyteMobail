import mongoose from 'mongoose';

const fileAttachmentSchema = new mongoose.Schema({
  chatId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Chat',
    required: true,
    index: true,
  },
  messageId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Message',
    sparse: true, // Может быть null для файлов без сообщения
  },
  uploadedBy: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true,
  },
  url: {
    type: String,
    required: true,
  },
  type: {
    type: String,
    enum: ['image', 'document', 'video', 'audio', 'other'],
    default: 'other',
  },
  name: {
    type: String,
    required: true,
  },
  size: {
    type: Number,
    default: 0,
  },
  mimeType: {
    type: String,
  },
  createdAt: {
    type: Date,
    default: Date.now,
    index: true,
  },
});

// Индекс для быстрого поиска файлов по чату
fileAttachmentSchema.index({ chatId: 1, createdAt: -1 });

export const FileAttachment = mongoose.model('FileAttachment', fileAttachmentSchema);



