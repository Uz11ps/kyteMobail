import { Chat } from '../models/Chat.js';
import { Message } from '../models/Message.js';
import { io } from '../server.js';
import { agentService } from '../services/agent.service.js';

// Получение или создание приватного AI чата для пользователя
const getOrCreateAIChat = async (userId) => {
  // Ищем существующий AI чат для пользователя
  let aiChat = await Chat.findOne({
    participants: userId,
    $or: [{ type: 'ai' }, { name: 'Kyte Assistant' }]
  });

  if (!aiChat) {
    // Создаем новый AI чат
    aiChat = new Chat({
      name: 'Kyte Assistant',
      type: 'direct', // Маскируем под direct для фронтенда
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

    const formattedUserMessage = {
      id: userMessage._id.toString(),
      chatId: aiChat._id.toString(),
      userId: userId.toString(),
      userName: req.user.name || req.user.email,
      content: userMessage.content,
      type: 'text',
      createdAt: userMessage.createdAt,
    };

    // Отправка через WebSocket вопроса пользователя
    io.to(`chat:${aiChat._id}`).emit('message', formattedUserMessage);

    // Уведомляем n8n агента
    // Загружаем чат с участниками для контекста
    const chatData = await Chat.findById(aiChat._id).populate('participants').lean();
    agentService.notifyAgent(formattedUserMessage, chatData);

    res.json({
      success: true,
      message: 'Запрос отправлен агенту',
      chatId: aiChat._id.toString(),
      userMessage: formattedUserMessage
    });
  } catch (error) {
    console.error('Ошибка AI чата:', error);
    res.status(500).json({ message: 'Ошибка сервера' });
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

    const formattedMessages = messages.map(msg => {
      let userIdStr = '';
      let userNameStr = 'Kyte';

      if (msg.userId) {
        userIdStr = msg.userId._id ? msg.userId._id.toString() : msg.userId.toString();
        userNameStr = msg.type === 'ai' ? 'Kyte' : (msg.userId.name || msg.userId.email || 'User');
      }

      return {
        id: msg._id.toString(),
        chatId: msg.chatId.toString(),
        userId: userIdStr,
        userName: userNameStr,
        content: msg.content,
        type: msg.type,
        createdAt: msg.createdAt,
        metadata: msg.metadata ? (msg.metadata instanceof Map ? Object.fromEntries(msg.metadata) : msg.metadata) : null,
      };
    });

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

    // Сохраняем вопрос пользователя
    const userMessage = new Message({
      chatId,
      userId,
      content: question.trim(),
      type: 'text',
    });
    await userMessage.save();

    const formattedUserMessage = {
      id: userMessage._id.toString(),
      chatId: chatId.toString(),
      userId: userId.toString(),
      userName: req.user.name || req.user.email,
      content: userMessage.content,
      type: 'text',
      createdAt: userMessage.createdAt,
    };

    // Отправка через WebSocket
    io.to(`chat:${chatId}`).emit('message', formattedUserMessage);

    // Уведомляем n8n агента
    const chatData = await Chat.findById(chatId).populate('participants').lean();
    agentService.notifyAgent(formattedUserMessage, chatData);

    res.json({ success: true, message: 'Запрос отправлен агенту' });
  } catch (error) {
    console.error('Ошибка запроса к AI:', error);
    res.status(500).json({ message: 'Ошибка сервера' });
  }
};

export const getAISuggestions = async (req, res) => {
  // В режиме n8n предложения можно реализовать через отдельный механизм или оставить пустым
  res.json({ suggestions: [] });
};


