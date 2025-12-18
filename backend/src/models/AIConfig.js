import mongoose from 'mongoose';
import { encrypt, decrypt } from '../utils/encryption.js';

const aiConfigSchema = new mongoose.Schema({
  // OpenAI настройки
  openaiApiKey: {
    type: String,
    default: '',
  },
  openaiModel: {
    type: String,
    default: 'gpt-3.5-turbo',
  },
  openaiMaxTokens: {
    type: Number,
    default: 500,
  },
  openaiTemperature: {
    type: Number,
    default: 0.7,
    min: 0,
    max: 2,
  },
  
  // Системный промпт
  systemPrompt: {
    type: String,
    default: 'Ты полезный AI-ассистент. Помогай пользователям с их вопросами.',
  },
  
  // Лимиты и ограничения
  maxRequestsPerMinute: {
    type: Number,
    default: 10,
  },
  maxRequestsPerHour: {
    type: Number,
    default: 100,
  },
  
  // Включено/выключено
  enabled: {
    type: Boolean,
    default: true,
  },
  
  // Метаданные
  updatedBy: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
  },
  updatedAt: {
    type: Date,
    default: Date.now,
  },
  createdAt: {
    type: Date,
    default: Date.now,
  },
});

// Шифрование API ключа перед сохранением
aiConfigSchema.pre('save', function(next) {
  if (this.isModified('openaiApiKey') && this.openaiApiKey) {
    this.openaiApiKey = encrypt(this.openaiApiKey);
  }
  next();
});

// Дешифрование API ключа после загрузки
aiConfigSchema.post('init', function() {
  if (this.openaiApiKey) {
    try {
      this.openaiApiKey = decrypt(this.openaiApiKey);
    } catch (e) {
      console.error('Ошибка дешифрования API ключа:', e);
    }
  }
});

aiConfigSchema.post('find', function(docs) {
  if (docs && Array.isArray(docs)) {
    docs.forEach(doc => {
      if (doc.openaiApiKey) {
        try {
          doc.openaiApiKey = decrypt(doc.openaiApiKey);
        } catch (e) {
          console.error('Ошибка дешифрования API ключа:', e);
        }
      }
    });
  }
});

aiConfigSchema.post('findOne', function(doc) {
  if (doc && doc.openaiApiKey) {
    try {
      doc.openaiApiKey = decrypt(doc.openaiApiKey);
    } catch (e) {
      console.error('Ошибка дешифрования API ключа:', e);
    }
  }
});

// Индекс для быстрого поиска активной конфигурации
aiConfigSchema.index({ enabled: 1, createdAt: -1 });

export const AIConfig = mongoose.model('AIConfig', aiConfigSchema);

