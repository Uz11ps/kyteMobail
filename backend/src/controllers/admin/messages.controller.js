import { Message } from '../../models/Message.js';
import { Chat } from '../../models/Chat.js';

export const getMessages = async (req, res) => {
  try {
    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 50;
    const skip = (page - 1) * limit;
    const chatId = req.query.chatId;

    const query = {};
    if (chatId) {
      query.chatId = chatId;
    }

    const [messages, total] = await Promise.all([
      Message.find(query)
        .populate('userId', 'email name avatarUrl')
        .populate('chatId', 'name type')
        .sort({ createdAt: -1 })
        .skip(skip)
        .limit(limit)
        .lean(),
      Message.countDocuments(query),
    ]);

    res.json({
      success: true,
      data: messages.reverse(), // Новые сообщения первыми
      pagination: {
        page,
        limit,
        total,
        pages: Math.ceil(total / limit),
      },
    });
  } catch (error) {
    console.error('Ошибка получения сообщений:', error);
    res.status(500).json({ 
      error: 'Ошибка получения сообщений',
      code: 'SERVER_ERROR'
    });
  }
};

export const getMessageById = async (req, res) => {
  try {
    const message = await Message.findById(req.params.id)
      .populate('userId', 'email name avatarUrl')
      .populate('chatId', 'name type')
      .lean();
    
    if (!message) {
      return res.status(404).json({ 
        error: 'Сообщение не найдено',
        code: 'MESSAGE_NOT_FOUND'
      });
    }

    res.json({
      success: true,
      data: message,
    });
  } catch (error) {
    console.error('Ошибка получения сообщения:', error);
    res.status(500).json({ 
      error: 'Ошибка получения сообщения',
      code: 'SERVER_ERROR'
    });
  }
};

export const deleteMessage = async (req, res) => {
  try {
    const message = await Message.findByIdAndDelete(req.params.id);
    
    if (!message) {
      return res.status(404).json({ 
        error: 'Сообщение не найдено',
        code: 'MESSAGE_NOT_FOUND'
      });
    }

    res.json({
      success: true,
      message: 'Сообщение удалено',
    });
  } catch (error) {
    console.error('Ошибка удаления сообщения:', error);
    res.status(500).json({ 
      error: 'Ошибка удаления сообщения',
      code: 'SERVER_ERROR'
    });
  }
};

