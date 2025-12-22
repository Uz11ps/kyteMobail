import { Message } from '../models/Message.js';
import { Chat } from '../models/Chat.js';
import { io } from '../server.js';

// Поставить/убрать лайк на сообщение
export const toggleLike = async (req, res) => {
  try {
    const { messageId } = req.params;
    const userId = req.user._id;

    const message = await Message.findById(messageId)
      .populate('chatId');

    if (!message) {
      return res.status(404).json({ message: 'Сообщение не найдено' });
    }

    // Проверка доступа к чату
    const chat = message.chatId;
    const isParticipant = chat.participants.some(
      p => p.toString() === userId.toString()
    );

    if (!isParticipant) {
      return res.status(403).json({ message: 'Доступ запрещен' });
    }

    // Проверяем, есть ли уже лайк от этого пользователя
    const likeIndex = message.likes.findIndex(
      like => like.toString() === userId.toString()
    );

    if (likeIndex > -1) {
      // Убираем лайк
      message.likes.splice(likeIndex, 1);
    } else {
      // Добавляем лайк
      message.likes.push(userId);
    }

    await message.save();

    // Отправляем обновление через WebSocket
    const populatedMessage = await Message.findById(messageId)
      .populate('userId', 'email name')
      .lean();

    const formattedMessage = {
      id: populatedMessage._id.toString(),
      chatId: populatedMessage.chatId.toString(),
      userId: populatedMessage.userId._id.toString(),
      userName: populatedMessage.userId.name || populatedMessage.userId.email,
      content: populatedMessage.content,
      type: populatedMessage.type,
      likes: populatedMessage.likes.map(id => id.toString()),
      likesCount: populatedMessage.likes.length,
      createdAt: populatedMessage.createdAt,
      metadata: populatedMessage.metadata ? Object.fromEntries(populatedMessage.metadata) : null,
    };

    io.to(`chat:${message.chatId}`).emit('message_liked', formattedMessage);

    res.json({
      message: formattedMessage,
      liked: likeIndex === -1, // true если лайк добавлен, false если убран
    });
  } catch (error) {
    console.error('Ошибка обработки лайка:', error);
    res.status(500).json({ message: 'Ошибка сервера' });
  }
};

// Отметить сообщения как прочитанные
export const markAsRead = async (req, res) => {
  try {
    const { chatId } = req.params;
    const userId = req.user._id;
    const { lastMessageId } = req.body;

    // Проверка доступа к чату
    const chat = await Chat.findOne({
      _id: chatId,
      participants: userId,
    });

    if (!chat) {
      return res.status(403).json({ message: 'Доступ запрещен' });
    }

    // Обновляем или добавляем запись о прочтении
    const readIndex = chat.readBy.findIndex(
      read => read.userId.toString() === userId.toString()
    );

    const readData = {
      userId,
      lastReadMessageId: lastMessageId || null,
      lastReadAt: new Date(),
    };

    if (readIndex > -1) {
      chat.readBy[readIndex] = readData;
    } else {
      chat.readBy.push(readData);
    }

    await chat.save();

    res.json({ success: true });
  } catch (error) {
    console.error('Ошибка отметки сообщений как прочитанных:', error);
    res.status(500).json({ message: 'Ошибка сервера' });
  }
};



