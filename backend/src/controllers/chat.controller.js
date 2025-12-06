import { Chat } from '../models/Chat.js';
import { Message } from '../models/Message.js';
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

    const formattedChats = chats.map(chat => ({
      id: chat._id.toString(),
      name: chat.name,
      type: chat.type,
      participantIds: chat.participants.map(p => p._id.toString()),
      inviteCode: chat.inviteCode,
      createdAt: chat.createdAt,
      lastMessageAt: chat.lastMessageAt,
      lastMessage: chat.lastMessage?.content,
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

    const formattedMessage = {
      id: populatedMessage._id.toString(),
      chatId: populatedMessage.chatId.toString(),
      userId: populatedMessage.userId._id.toString(),
      userName: populatedMessage.userId.name || populatedMessage.userId.email,
      content: populatedMessage.content,
      type: populatedMessage.type,
      createdAt: populatedMessage.createdAt,
      metadata: populatedMessage.metadata ? Object.fromEntries(populatedMessage.metadata) : null,
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

