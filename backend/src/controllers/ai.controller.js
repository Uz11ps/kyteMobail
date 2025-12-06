import { askAI as askAIService, getAISuggestions as getAISuggestionsService } from '../services/openai.service.js';
import { io } from '../server.js';

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

