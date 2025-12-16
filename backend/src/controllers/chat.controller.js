import { Chat } from '../models/Chat.js';
import { Message } from '../models/Message.js';
import { User } from '../models/User.js';
import { io } from '../server.js';
import { sendPushToChatParticipants } from '../services/push.service.js';

export const getChats = async (req, res) => {
  try {
    const userId = req.user._id;

    const chats = await Chat.find({
      participants: userId,
    })
      .populate('participants', 'email name avatarUrl')
      .populate('lastMessage')
      .sort({ lastMessageAt: -1, updatedAt: -1 })
      .lean();

    // Получаем статистику для каждого чата
    const formattedChats = await Promise.all(chats.map(async (chat) => {
      // Непрочитанные сообщения
      const userReadData = chat.readBy?.find(
        read => read.userId.toString() === userId.toString()
      );
      const lastReadMessageId = userReadData?.lastReadMessageId;
      
      let unreadCount = 0;
      if (lastReadMessageId) {
        unreadCount = await Message.countDocuments({
          chatId: chat._id,
          createdAt: { $gt: userReadData.lastReadAt || new Date(0) },
        });
      } else if (chat.lastMessageAt) {
        // Если пользователь никогда не читал, считаем все сообщения непрочитанными
        unreadCount = await Message.countDocuments({
          chatId: chat._id,
        });
      }

      // Общее количество лайков в чате
      const likesResult = await Message.aggregate([
        { $match: { chatId: chat._id } },
        { $project: { likesCount: { $size: { $ifNull: ['$likes', []] } } } },
        { $group: { _id: null, totalLikes: { $sum: '$likesCount' } } },
      ]);
      const likesCount = likesResult[0]?.totalLikes || 0;

      // Количество встреч (сообщения с meetUrl в metadata)
      const meetingsCount = await Message.countDocuments({
        chatId: chat._id,
        'metadata.meetUrl': { $exists: true },
      });

      return {
        id: chat._id.toString(),
        name: chat.name,
        type: chat.type,
        participantIds: chat.participants.map(p => p._id.toString()),
        inviteCode: chat.inviteCode,
        createdAt: chat.createdAt ? new Date(chat.createdAt).toISOString() : new Date().toISOString(),
        lastMessageAt: chat.lastMessageAt ? new Date(chat.lastMessageAt).toISOString() : null,
        lastMessage: chat.lastMessage?.content || null,
        unreadCount,
        likesCount,
        meetingsCount,
      };
    }));

    res.json({ chats: formattedChats });
  } catch (error) {
    console.error('Ошибка получения чатов:', error);
    res.status(500).json({ message: 'Ошибка сервера' });
  }
};

export const getMessages = async (req, res) => {
  try {
    const { chatId } = req.params;
    const { limit = 100 } = req.query;
    const userId = req.user._id;

    // Проверка доступа к чату
    const chat = await Chat.findOne({
      _id: chatId,
      participants: userId,
    });

    if (!chat) {
      return res.status(403).json({ message: 'Доступ запрещен' });
    }

    const messages = await Message.find({ chatId })
      .populate('userId', 'email name')
      .sort({ createdAt: -1 })
      .limit(parseInt(limit))
      .lean();

    const formattedMessages = messages.reverse().map(msg => ({
      id: msg._id.toString(),
      chatId: msg.chatId.toString(),
      userId: msg.userId._id.toString(),
      userName: msg.userId.name || msg.userId.email,
      content: msg.content,
      type: msg.type,
      likes: msg.likes?.map(id => id.toString()) || [],
      likesCount: msg.likes?.length || 0,
      attachments: msg.attachments || [],
      createdAt: msg.createdAt,
      metadata: msg.metadata ? Object.fromEntries(msg.metadata) : null,
    }));

    res.json({ messages: formattedMessages });
  } catch (error) {
    console.error('Ошибка получения сообщений:', error);
    res.status(500).json({ message: 'Ошибка сервера' });
  }
};

export const sendMessage = async (req, res) => {
  try {
    const { chatId } = req.params;
    const { content } = req.body;
    const userId = req.user._id;

    if (!content || !content.trim()) {
      return res.status(400).json({ message: 'Содержание сообщения обязательно' });
    }

    // Проверка доступа к чату
    const chat = await Chat.findOne({
      _id: chatId,
      participants: userId,
    }).populate('participants');

    if (!chat) {
      return res.status(403).json({ message: 'Доступ запрещен' });
    }

    // Создание сообщения
    const message = new Message({
      chatId,
      userId,
      content: content.trim(),
      type: 'text',
    });

    await message.save();

    // Обновление последнего сообщения в чате
    await Chat.findByIdAndUpdate(chatId, {
      lastMessage: message._id,
      lastMessageAt: message.createdAt,
      updatedAt: Date.now(),
    });

    // Отправка через WebSocket всем участникам чата
    const populatedMessage = await Message.findById(message._id)
      .populate('userId', 'email name')
      .lean();

    if (!populatedMessage) {
      console.error('Сообщение не найдено после создания:', message._id);
      return res.status(500).json({ message: 'Сообщение не найдено после создания' });
    }

    // Проверяем, что userId заполнен
    if (!populatedMessage.userId) {
      console.error('userId не заполнен для сообщения:', populatedMessage._id);
      // Попробуем получить пользователя напрямую
      const user = await User.findById(userId).lean();
      populatedMessage.userId = user || { _id: userId, email: 'Неизвестный', name: null };
    }

    // Преобразуем metadata из Map в объект
    let metadataObj = null;
    if (populatedMessage.metadata) {
      if (populatedMessage.metadata instanceof Map) {
        metadataObj = Object.fromEntries(populatedMessage.metadata);
      } else if (typeof populatedMessage.metadata === 'object') {
        metadataObj = populatedMessage.metadata;
      }
    }

    const formattedMessage = {
      id: populatedMessage._id.toString(),
      chatId: populatedMessage.chatId.toString(),
      userId: populatedMessage.userId?._id?.toString() || userId.toString(),
      userName: populatedMessage.userId?.name || populatedMessage.userId?.email || 'Неизвестный',
      content: populatedMessage.content,
      type: populatedMessage.type,
      likes: populatedMessage.likes?.map(id => id.toString()) || [],
      likesCount: populatedMessage.likes?.length || 0,
      attachments: populatedMessage.attachments || [],
      createdAt: populatedMessage.createdAt ? new Date(populatedMessage.createdAt).toISOString() : new Date().toISOString(),
      metadata: metadataObj,
    };

    io.to(`chat:${chatId}`).emit('message', formattedMessage);

    // Отправка push-уведомлений участникам чата
    await sendPushToChatParticipants(
      chatId,
      formattedMessage.userName || 'Новое сообщение',
      formattedMessage.content,
      userId.toString()
    );

    res.status(201).json({ message: formattedMessage });
  } catch (error) {
    console.error('Ошибка отправки сообщения:', error);
    res.status(500).json({ message: 'Ошибка сервера' });
  }
};

