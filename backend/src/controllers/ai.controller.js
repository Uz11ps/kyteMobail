import { askAI as askAIService, getAISuggestions as getAISuggestionsService } from '../services/openai.service.js';
import { Chat } from '../models/Chat.js';
import { Message } from '../models/Message.js';
import { io } from '../server.js';

// Получение или создание приватного AI чата для пользователя
const getOrCreateAIChat = async (userId) => {
  // Ищем существующий AI чат для пользователя
  let aiChat = await Chat.findOne({
    type: 'ai',
    participants: userId,
  });

  if (!aiChat) {
    // Создаем новый AI чат
    aiChat = new Chat({
      name: 'Kyte',
      type: 'ai',
      participants: [userId],
      createdBy: userId,
    });
    await aiChat.save();
  }

  return aiChat;
};

// AI Popup Chat - специальный эндпоинт для приватного чата с AI
export const aiChat = async (req, res) => {
  try {
    const { question } = req.body;
    const userId = req.user._id;

    if (!question || !question.trim()) {
      return res.status(400).json({ message: 'Вопрос обязателен' });
    }

    // Получаем или создаем AI чат
    const aiChat = await getOrCreateAIChat(userId);

    // Сохраняем вопрос пользователя
    const userMessage = new Message({
      chatId: aiChat._id,
      userId,
      content: question.trim(),
      type: 'text',
    });
    await userMessage.save();

    // Обновляем последнее сообщение в чате
    await Chat.findByIdAndUpdate(aiChat._id, {
      lastMessage: userMessage._id,
      lastMessageAt: userMessage.createdAt,
      updatedAt: Date.now(),
    });

    // Получаем ответ от AI
    const result = await askAIService(
      aiChat._id.toString(),
      question.trim(),
      userId
    );

    // Отправка через WebSocket
    io.to(`chat:${aiChat._id}`).emit('message', {
      ...result.message,
      userName: 'User',
    });
    io.to(`chat:${aiChat._id}`).emit('message', {
      ...result.message,
      userName: 'Kyte',
    });

    res.json({
      chatId: aiChat._id.toString(),
      userMessage: {
        id: userMessage._id.toString(),
        chatId: aiChat._id.toString(),
        userId: userId.toString(),
        userName: req.user.name || req.user.email,
        content: userMessage.content,
        type: 'text',
        createdAt: userMessage.createdAt,
      },
      aiMessage: result.message,
    });
  } catch (error) {
    console.error('Ошибка AI чата:', error);
    res.status(500).json({ message: error.message || 'Ошибка сервера' });
  }
};

// Получение истории AI чата
export const getAIChatHistory = async (req, res) => {
  try {
    const userId = req.user._id;

    // Получаем или создаем AI чат
    const aiChat = await getOrCreateAIChat(userId);

    // Получаем сообщения
    const messages = await Message.find({ chatId: aiChat._id })
      .populate('userId', 'email name')
      .sort({ createdAt: 1 })
      .lean();

    const formattedMessages = messages.map(msg => ({
      id: msg._id.toString(),
      chatId: msg.chatId.toString(),
      userId: msg.userId._id.toString(),
      userName: msg.type === 'ai' ? 'Kyte' : (msg.userId.name || msg.userId.email),
      content: msg.content,
      type: msg.type,
      createdAt: msg.createdAt,
      metadata: msg.metadata ? Object.fromEntries(msg.metadata) : null,
    }));

    res.json({
      chatId: aiChat._id.toString(),
      messages: formattedMessages,
    });
  } catch (error) {
    console.error('Ошибка получения истории AI чата:', error);
    res.status(500).json({ message: 'Ошибка сервера' });
  }
};

export const askAI = async (req, res) => {
  try {
    const { chatId, question } = req.body;
    const userId = req.user._id;

    if (!chatId || !question) {
      return res.status(400).json({ message: 'chatId и question обязательны' });
    }

    const result = await askAIService(chatId, question, userId, req.user.name || req.user.email);

    // Отправка через WebSocket
    io.to(`chat:${chatId}`).emit('message', result.message);

    res.json(result);
  } catch (error) {
    console.error('Ошибка запроса к AI:', error);
    res.status(500).json({ message: error.message || 'Ошибка сервера' });
  }
};

export const getAISuggestions = async (req, res) => {
  try {
    const { chatId } = req.query;
    const userId = req.user._id;

    if (!chatId) {
      return res.status(400).json({ message: 'chatId обязателен' });
    }

    const suggestions = await getAISuggestionsService(chatId);

    res.json({ suggestions });
  } catch (error) {
    console.error('Ошибка получения предложений AI:', error);
    res.status(500).json({ message: 'Ошибка сервера' });
  }
};

