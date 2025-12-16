import OpenAI from 'openai';
import { Message } from '../models/Message.js';
import { Chat } from '../models/Chat.js';
import { getSystemPrompt, getSuggestionPrompt } from '../utils/aiPrompts.js';

// Инициализация OpenAI (опционально)
let openai = null;
if (process.env.OPENAI_API_KEY && process.env.OPENAI_API_KEY !== 'your-openai-api-key') {
  try {
    openai = new OpenAI({
      apiKey: process.env.OPENAI_API_KEY,
    });
    console.log('✅ OpenAI инициализирован');
  } catch (error) {
    console.error('⚠️  Ошибка инициализации OpenAI:', error.message);
  }
} else {
  console.log('⚠️  OpenAI не настроен (AI функции отключены)');
}

// Rate limiting для контроля затрат
const requestQueue = [];
const MAX_REQUESTS_PER_MINUTE = 10;
let requestCount = 0;
let lastReset = Date.now();

const checkRateLimit = () => {
  const now = Date.now();
  if (now - lastReset > 60000) {
    requestCount = 0;
    lastReset = now;
  }
  return requestCount < MAX_REQUESTS_PER_MINUTE;
};

export const askAI = async (chatId, question, userId) => {
  if (!openai) {
    throw new Error('OpenAI не настроен. Укажите OPENAI_API_KEY в .env файле.');
  }

  if (!checkRateLimit()) {
    throw new Error('Превышен лимит запросов к AI. Попробуйте позже.');
  }

  requestCount++;

  try {
    // Получение последних 100-200 сообщений для контекста
    const messages = await Message.find({ chatId })
      .sort({ createdAt: -1 })
      .limit(200)
      .populate('userId', 'email name')
      .lean();

    const chat = await Chat.findById(chatId).populate('participants', 'email name').lean();

    // Формирование контекста
    const contextMessages = messages.reverse().map(msg => ({
      role: msg.type === 'ai' ? 'assistant' : 'user',
      content: `${msg.userId.name || msg.userId.email}: ${msg.content}`,
    }));

    // Системный промпт
    const systemPrompt = getSystemPrompt(chat.participants);

    // Запрос к OpenAI
    const completion = await openai.chat.completions.create({
      model: 'gpt-3.5-turbo',
      messages: [
        { role: 'system', content: systemPrompt },
        ...contextMessages,
        { role: 'user', content: question },
      ],
      max_tokens: 500,
      temperature: 0.7,
    });

    const aiResponse = completion.choices[0].message.content;

    // Проверка на рекомендацию создания Meet
    const suggestMeet = /встреч|совещан|видеозвонк|meet|zoom/i.test(aiResponse) ||
                       /создай.*встреч|организуй.*встреч/i.test(aiResponse);

    // Создание сообщения от AI
    // Для AI чата используем специальный userId или оставляем userId пользователя
    const message = new Message({
      chatId,
      userId: userId, // Сохраняем userId пользователя для связи
      content: aiResponse,
      type: 'ai',
      metadata: {
        suggestMeet,
        askedBy: userId.toString(),
      },
    });

    await message.save();

    // Обновляем последнее сообщение в чате
    await Chat.findByIdAndUpdate(chatId, {
      lastMessage: message._id,
      lastMessageAt: message.createdAt,
      updatedAt: Date.now(),
    });

    const populatedMessage = await Message.findById(message._id)
      .populate('userId', 'email name')
      .lean();

    return {
      message: {
        id: populatedMessage._id.toString(),
        chatId: populatedMessage.chatId.toString(),
        userId: populatedMessage.userId._id.toString(),
        userName: 'Kyte', // Имя AI ассистента
        content: populatedMessage.content,
        type: populatedMessage.type,
        createdAt: populatedMessage.createdAt,
        metadata: populatedMessage.metadata ? Object.fromEntries(populatedMessage.metadata) : null,
      },
    };
  } catch (error) {
    console.error('Ошибка OpenAI:', error);
    throw new Error('Ошибка при обращении к AI сервису');
  }
};

export const getAISuggestions = async (chatId) => {
  if (!openai) {
    return []; // Возвращаем пустой массив если OpenAI не настроен
  }

  if (!checkRateLimit()) {
    return [];
  }

  requestCount++;

  try {
    // Получение последних сообщений
    const messages = await Message.find({ chatId })
      .sort({ createdAt: -1 })
      .limit(100)
      .populate('userId', 'email name')
      .lean();

    if (messages.length < 5) {
      return []; // Недостаточно контекста для предложений
    }

    const recentMessages = messages.slice(0, 10).reverse();
    const context = recentMessages
      .map(msg => `${msg.userId.name || msg.userId.email}: ${msg.content}`)
      .join('\n');

    // Анализ контекста для предложений
    const suggestionPrompt = getSuggestionPrompt(recentMessages);
    
    const completion = await openai.chat.completions.create({
      model: 'gpt-3.5-turbo',
      messages: [
        {
          role: 'system',
          content: 'Ты помощник в групповом чате. Анализируй сообщения и предлагай полезные действия.',
        },
        {
          role: 'user',
          content: suggestionPrompt,
        },
      ],
      max_tokens: 200,
      temperature: 0.7,
    });

    const suggestion = completion.choices[0].message.content;
    const suggestMeet = /встреч|meet|видеозвонк/i.test(suggestion);

    return [
      {
        id: `suggestion-${Date.now()}`,
        chatId,
        userId: 'ai-user',
        content: suggestion,
        type: 'ai',
        createdAt: new Date(),
        metadata: {
          suggestMeet,
        },
      },
    ];
  } catch (error) {
    console.error('Ошибка получения предложений AI:', error);
    return [];
  }
};

