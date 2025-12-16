import { FileAttachment } from '../models/FileAttachment.js';
import { Chat } from '../models/Chat.js';
import { Message } from '../models/Message.js';
import { getFileType } from '../middleware/upload.js';
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

// Получение списка файлов чата
export const getChatFiles = async (req, res) => {
  try {
    const { chatId } = req.params;
    const userId = req.user._id;

    // Проверка доступа к чату
    const chat = await Chat.findOne({
      _id: chatId,
      participants: userId,
    });

    if (!chat) {
      return res.status(403).json({ message: 'Доступ запрещен' });
    }

    const files = await FileAttachment.find({ chatId })
      .populate('uploadedBy', 'email name')
      .sort({ createdAt: -1 })
      .lean();

    const formattedFiles = files.map(file => ({
      id: file._id.toString(),
      chatId: file.chatId.toString(),
      messageId: file.messageId?.toString() || null,
      uploadedBy: file.uploadedBy._id.toString(),
      uploadedByName: file.uploadedBy.name || file.uploadedBy.email,
      url: file.url,
      type: file.type,
      name: file.name,
      size: file.size,
      mimeType: file.mimeType,
      createdAt: file.createdAt,
    }));

    res.json({ files: formattedFiles });
  } catch (error) {
    console.error('Ошибка получения файлов:', error);
    res.status(500).json({ message: 'Ошибка сервера' });
  }
};

// Загрузка файла
export const uploadFile = async (req, res) => {
  try {
    const { chatId } = req.params;
    const userId = req.user._id;
    const file = req.file;

    if (!file) {
      return res.status(400).json({ message: 'Файл не загружен' });
    }

    // Проверка доступа к чату
    const chat = await Chat.findOne({
      _id: chatId,
      participants: userId,
    });

    if (!chat) {
      // Удаляем загруженный файл если нет доступа
      const fs = await import('fs-extra');
      await fs.remove(file.path);
      return res.status(403).json({ message: 'Доступ запрещен' });
    }

    // Определяем тип файла
    const fileType = getFileType(file.mimetype, file.originalname);

    // Формируем URL файла (в продакшене должен быть через CDN или статический сервер)
    const fileUrl = `/uploads/${file.filename}`;

    // Создаем запись о файле
    const fileAttachment = new FileAttachment({
      chatId,
      uploadedBy: userId,
      url: fileUrl,
      type: fileType,
      name: file.originalname,
      size: file.size,
      mimeType: file.mimetype,
    });

    await fileAttachment.save();

    // Если есть messageId в запросе, привязываем файл к сообщению
    const { messageId } = req.body;
    if (messageId) {
      const message = await Message.findById(messageId);
      if (message && message.chatId.toString() === chatId) {
        message.attachments.push({
          url: fileUrl,
          type: fileType,
          name: file.originalname,
          size: file.size,
        });
        await message.save();
        fileAttachment.messageId = messageId;
        await fileAttachment.save();
      }
    }

    const populatedFile = await FileAttachment.findById(fileAttachment._id)
      .populate('uploadedBy', 'email name')
      .lean();

    const formattedFile = {
      id: populatedFile._id.toString(),
      chatId: populatedFile.chatId.toString(),
      messageId: populatedFile.messageId?.toString() || null,
      uploadedBy: populatedFile.uploadedBy._id.toString(),
      uploadedByName: populatedFile.uploadedBy.name || populatedFile.uploadedBy.email,
      url: populatedFile.url,
      type: populatedFile.type,
      name: populatedFile.name,
      size: populatedFile.size,
      mimeType: populatedFile.mimeType,
      createdAt: populatedFile.createdAt,
    };

    res.status(201).json({ file: formattedFile });
  } catch (error) {
    console.error('Ошибка загрузки файла:', error);
    res.status(500).json({ message: 'Ошибка сервера' });
  }
};

// Удаление файла
export const deleteFile = async (req, res) => {
  try {
    const { fileId } = req.params;
    const userId = req.user._id;

    const fileAttachment = await FileAttachment.findById(fileId)
      .populate('chatId');

    if (!fileAttachment) {
      return res.status(404).json({ message: 'Файл не найден' });
    }

    // Проверка доступа (только загрузивший или участник чата)
    const chat = fileAttachment.chatId;
    const isParticipant = chat.participants.some(
      p => p.toString() === userId.toString()
    );
    const isUploader = fileAttachment.uploadedBy.toString() === userId.toString();

    if (!isParticipant) {
      return res.status(403).json({ message: 'Доступ запрещен' });
    }

    // Удаляем физический файл
    const fs = await import('fs-extra');
    const filePath = path.join(__dirname, '../../uploads', path.basename(fileAttachment.url));
    try {
      await fs.remove(filePath);
    } catch (err) {
      console.error('Ошибка удаления файла:', err);
    }

    // Удаляем из сообщений если привязан
    if (fileAttachment.messageId) {
      await Message.updateOne(
        { _id: fileAttachment.messageId },
        { $pull: { attachments: { url: fileAttachment.url } } }
      );
    }

    // Удаляем запись
    await FileAttachment.findByIdAndDelete(fileId);

    res.json({ message: 'Файл удален' });
  } catch (error) {
    console.error('Ошибка удаления файла:', error);
    res.status(500).json({ message: 'Ошибка сервера' });
  }
};

