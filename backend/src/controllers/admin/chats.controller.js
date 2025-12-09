import { Chat } from '../../models/Chat.js';
import { Message } from '../../models/Message.js';

export const getChats = async (req, res) => {
  try {
    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 20;
    const skip = (page - 1) * limit;
    const type = req.query.type; // 'direct' или 'group'

    const query = {};
    if (type) {
      query.type = type;
    }

    const [chats, total] = await Promise.all([
      Chat.find(query)
        .populate('participants', 'email name avatarUrl')
        .populate('createdBy', 'email name')
        .populate('lastMessage')
        .sort({ lastMessageAt: -1, createdAt: -1 })
        .skip(skip)
        .limit(limit)
        .lean(),
      Chat.countDocuments(query),
    ]);

    res.json({
      success: true,
      data: chats,
      pagination: {
        page,
        limit,
        total,
        pages: Math.ceil(total / limit),
      },
    });
  } catch (error) {
    console.error('Ошибка получения чатов:', error);
    res.status(500).json({ 
      error: 'Ошибка получения чатов',
      code: 'SERVER_ERROR'
    });
  }
};

export const getChatById = async (req, res) => {
  try {
    const chat = await Chat.findById(req.params.id)
      .populate('participants', 'email name avatarUrl')
      .populate('createdBy', 'email name')
      .populate('lastMessage')
      .lean();
    
    if (!chat) {
      return res.status(404).json({ 
        error: 'Чат не найден',
        code: 'CHAT_NOT_FOUND'
      });
    }

    // Получаем сообщения чата
    const messages = await Message.find({ chatId: chat._id })
      .populate('userId', 'email name avatarUrl')
      .sort({ createdAt: -1 })
      .limit(50)
      .lean();

    res.json({
      success: true,
      data: {
        ...chat,
        messages: messages.reverse(),
      },
    });
  } catch (error) {
    console.error('Ошибка получения чата:', error);
    res.status(500).json({ 
      error: 'Ошибка получения чата',
      code: 'SERVER_ERROR'
    });
  }
};

export const deleteChat = async (req, res) => {
  try {
    // Удаляем все сообщения чата
    await Message.deleteMany({ chatId: req.params.id });
    
    // Удаляем чат
    const chat = await Chat.findByIdAndDelete(req.params.id);
    
    if (!chat) {
      return res.status(404).json({ 
        error: 'Чат не найден',
        code: 'CHAT_NOT_FOUND'
      });
    }

    res.json({
      success: true,
      message: 'Чат и все сообщения удалены',
    });
  } catch (error) {
    console.error('Ошибка удаления чата:', error);
    res.status(500).json({ 
      error: 'Ошибка удаления чата',
      code: 'SERVER_ERROR'
    });
  }
};

