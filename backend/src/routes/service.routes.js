import express from 'express';
import { User } from '../models/User.js';
import { serviceAuth } from '../middleware/serviceAuth.js';

const router = express.Router();

/**
 * Поиск пользователя по имени или никнейму для нужд ИИ агента
 * GET /api/service/users/lookup?name=Иван
 */
router.get('/users/lookup', serviceAuth, async (req, res) => {
  try {
    const { name } = req.query;

    if (!name) {
      return res.status(400).json({ error: 'Name parameter is required' });
    }

    // Ищем пользователя по частичному совпадению имени или никнейма
    const users = await User.find({
      $or: [
        { name: { $regex: name, $options: 'i' } },
        { nickname: { $regex: name, $options: 'i' } },
        { email: { $regex: name, $options: 'i' } }
      ]
    })
    .select('name nickname email phone avatarUrl')
    .limit(5)
    .lean();

    res.json({ users });
  } catch (error) {
    console.error('Service API Error (User Lookup):', error);
    res.status(500).json({ error: 'Internal Server Error' });
  }
});

/**
 * Получение информации о чате для анализа контекста
 * GET /api/service/chats/:id
 */
router.get('/chats/:id', serviceAuth, async (req, res) => {
  // Добавим позже если понадобится агенту получать список участников чата
  res.status(501).json({ error: 'Not implemented yet' });
});

export default router;

