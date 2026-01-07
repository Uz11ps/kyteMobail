import { AIConfig } from '../../models/AIConfig.js';

// Получение текущих настроек AI
export const getAIConfig = async (req, res) => {
  try {
    let config = await AIConfig.findOne().sort({ createdAt: -1 }).lean();
    
    if (!config) {
      // Создаем дефолтную конфигурацию если её нет
      config = new AIConfig({
        openaiApiKey: process.env.OPENAI_API_KEY || '',
        openaiModel: process.env.OPENAI_MODEL || 'gpt-3.5-turbo',
        openaiMaxTokens: parseInt(process.env.OPENAI_MAX_TOKENS) || 500,
        openaiTemperature: parseFloat(process.env.OPENAI_TEMPERATURE) || 0.7,
        systemPrompt: 'Ты полезный AI-ассистент. Помогай пользователям с их вопросами.',
        maxRequestsPerMinute: 10,
        maxRequestsPerHour: 100,
        enabled: true,
      });
      await config.save();
      config = config.toObject();
    }
    
    // Не отправляем API ключ в открытом виде (только маскированный)
    const maskedApiKey = config.openaiApiKey 
      ? `${config.openaiApiKey.substring(0, 4)}...${config.openaiApiKey.substring(config.openaiApiKey.length - 4)}`
      : '';
    
    res.json({
      success: true,
      data: {
        ...config,
        openaiApiKey: maskedApiKey,
        openaiApiKeySet: !!config.openaiApiKey,
      },
    });
  } catch (error) {
    console.error('Ошибка получения настроек AI:', error);
    res.status(500).json({ 
      error: 'Ошибка получения настроек AI',
      code: 'SERVER_ERROR'
    });
  }
};

// Обновление настроек AI
export const updateAIConfig = async (req, res) => {
  try {
    const {
      openaiApiKey,
      openaiModel,
      openaiMaxTokens,
      openaiTemperature,
      systemPrompt,
      maxRequestsPerMinute,
      maxRequestsPerHour,
      enabled,
    } = req.body;
    
    let config = await AIConfig.findOne().sort({ createdAt: -1 });
    
    if (!config) {
      config = new AIConfig();
    }
    
    // Обновляем только переданные поля
    if (openaiApiKey !== undefined) {
      config.openaiApiKey = openaiApiKey;
    }
    if (openaiModel !== undefined) {
      config.openaiModel = openaiModel;
    }
    if (openaiMaxTokens !== undefined) {
      config.openaiMaxTokens = parseInt(openaiMaxTokens);
    }
    if (openaiTemperature !== undefined) {
      config.openaiTemperature = parseFloat(openaiTemperature);
    }
    if (systemPrompt !== undefined) {
      config.systemPrompt = systemPrompt;
    }
    if (maxRequestsPerMinute !== undefined) {
      config.maxRequestsPerMinute = parseInt(maxRequestsPerMinute);
    }
    if (maxRequestsPerHour !== undefined) {
      config.maxRequestsPerHour = parseInt(maxRequestsPerHour);
    }
    if (enabled !== undefined) {
      config.enabled = enabled === true || enabled === 'true';
    }
    
    config.updatedBy = req.admin?.id || null;
    config.updatedAt = new Date();
    
    await config.save();
    
    // Маскируем API ключ для ответа
    const maskedApiKey = config.openaiApiKey 
      ? `${config.openaiApiKey.substring(0, 4)}...${config.openaiApiKey.substring(config.openaiApiKey.length - 4)}`
      : '';
    
    res.json({
      success: true,
      data: {
        ...config.toObject(),
        openaiApiKey: maskedApiKey,
        openaiApiKeySet: !!config.openaiApiKey,
      },
    });
  } catch (error) {
    console.error('Ошибка обновления настроек AI:', error);
    res.status(500).json({ 
      error: 'Ошибка обновления настроек AI',
      code: 'SERVER_ERROR'
    });
  }
};

// Тестирование настроек AI
export const testAIConfig = async (req, res) => {
  try {
    const config = await AIConfig.findOne().sort({ createdAt: -1 }).lean();
    
    if (!config || !config.enabled) {
      return res.status(400).json({
        error: 'AI не включен или не настроен',
        code: 'AI_NOT_CONFIGURED'
      });
    }
    
    if (!config.openaiApiKey) {
      return res.status(400).json({
        error: 'API ключ не установлен',
        code: 'API_KEY_NOT_SET'
      });
    }
    
    // Здесь можно добавить тестовый запрос к OpenAI
    // Для MVP просто проверяем что настройки валидны
    
    res.json({
      success: true,
      message: 'Настройки AI валидны',
      data: {
        model: config.openaiModel,
        maxTokens: config.openaiMaxTokens,
        temperature: config.openaiTemperature,
      },
    });
  } catch (error) {
    console.error('Ошибка тестирования настроек AI:', error);
    res.status(500).json({ 
      error: 'Ошибка тестирования настроек AI',
      code: 'SERVER_ERROR'
    });
  }
};








