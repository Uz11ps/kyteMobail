import express from 'express';
import { User } from '../models/User.js';
import { Chat } from '../models/Chat.js';
import { Message } from '../models/Message.js';
import { serviceAuth } from '../middleware/serviceAuth.js';

const router = express.Router();

/**
 * Отправка сообщения от имени ИИ агента
 * POST /api/service/messages/send
 */
router.post('/messages/send', serviceAuth, async (req, res) => {
  try {
    const { chatId, content, metadata } = req.body;

    if (!chatId || !content) {
      return res.status(400).json({ error: 'chatId and content are required' });
    }

    // Находим или создаем системного пользователя "Kyte AI"
    let aiUser = await User.findOne({ email: 'ai-agent@kyte.me' });
    if (!aiUser) {
      aiUser = new User({
        email: 'ai-agent@kyte.me',
        name: 'Kyte AI Assistant',
        nickname: 'kyte_ai',
        isAI: true // Добавим флаг если нужно
      });
      await aiUser.save();
    }

    // Создаем сообщение
    const message = new Message({
      chatId,
      userId: aiUser._id,
      content,
      type: 'ai',
      metadata: metadata || {}
    });

    await message.save();

    // Обновляем последнее сообщение в чате
    await Chat.findByIdAndUpdate(chatId, {
      lastMessage: message._id,
      lastMessageAt: message.createdAt
    });

    res.json({ success: true, messageId: message._id });
  } catch (error) {
    console.error('Service API Error (Send Message):', error);
    res.status(500).json({ error: 'Internal Server Error' });
  }
});

/**
 * Поиск пользователя по имени или никнейму для нужд ИИ агента
... (остальной код) ...

/**
 * Получение информации о чате для анализа контекста
 * GET /api/service/chats/:id
 */
router.get('/chats/:id', serviceAuth, async (req, res) => {
  // Добавим позже если понадобится агенту получать список участников чата
  res.status(501).json({ error: 'Not implemented yet' });
});

export default router;

