import { User } from '../../models/User.js';
import { Chat } from '../../models/Chat.js';
import { Message } from '../../models/Message.js';

export const getStats = async (req, res) => {
  try {
    const [
      totalUsers,
      totalChats,
      totalMessages,
      directChats,
      groupChats,
      usersToday,
      messagesToday,
      chatsToday,
    ] = await Promise.all([
      User.countDocuments(),
      Chat.countDocuments(),
      Message.countDocuments(),
      Chat.countDocuments({ type: 'direct' }),
      Chat.countDocuments({ type: 'group' }),
      User.countDocuments({
        createdAt: { $gte: new Date(new Date().setHours(0, 0, 0, 0)) }
      }),
      Message.countDocuments({
        createdAt: { $gte: new Date(new Date().setHours(0, 0, 0, 0)) }
      }),
      Chat.countDocuments({
        createdAt: { $gte: new Date(new Date().setHours(0, 0, 0, 0)) }
      }),
    ]);

    // Получаем последних пользователей
    const recentUsers = await User.find()
      .sort({ createdAt: -1 })
      .limit(5)
      .select('email name createdAt')
      .lean();

    // Получаем самые активные чаты
    const activeChats = await Chat.find()
      .populate('lastMessage')
      .sort({ lastMessageAt: -1 })
      .limit(5)
      .select('name type lastMessageAt participants')
      .lean();

    res.json({
      success: true,
      data: {
        overview: {
          totalUsers,
          totalChats,
          totalMessages,
          directChats,
          groupChats,
        },
        today: {
          users: usersToday,
          messages: messagesToday,
          chats: chatsToday,
        },
        recentUsers,
        activeChats,
      },
    });
  } catch (error) {
    console.error('Ошибка получения статистики:', error);
    res.status(500).json({ 
      error: 'Ошибка получения статистики',
      code: 'SERVER_ERROR'
    });
  }
};

