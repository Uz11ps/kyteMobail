import axios from 'axios';
import dotenv from 'dotenv';

dotenv.config();

class AgentService {
  constructor() {
    this.webhookUrl = process.env.N8N_WEBHOOK_URL;
  }

  /**
   * Отправка сообщения ИИ агенту в n8n для анализа и ответа
   * @param {Object} messageData Данные сообщения
   * @param {Object} chatData Данные чата (участники и т.д.)
   */
  async notifyAgent(messageData, chatData) {
    if (!this.webhookUrl) {
      // console.log('ℹ️ n8n Webhook URL не настроен, уведомление агента пропущено');
      return;
    }

    try {
      // Подготавливаем данные для n8n
      const payload = {
        message: {
          id: messageData.id,
          content: messageData.content,
          type: messageData.type,
          createdAt: messageData.createdAt,
        },
        user: {
          id: messageData.userId,
          name: messageData.userName,
        },
        chat: {
          id: messageData.chatId,
          name: chatData.name,
          type: chatData.type,
          participants: chatData.participants.map(p => ({
            id: p._id.toString(),
            name: p.name,
            email: p.email,
          })),
        },
        timestamp: new Date().toISOString(),
      };

      // Отправляем асинхронно, не дожидаясь ответа, чтобы не тормозить чат
      axios.post(this.webhookUrl, payload, {
        headers: {
          'Content-Type': 'application/json',
          'X-Service-API-Key': process.env.SERVICE_API_KEY || 'kyte_service_secret_2024',
        },
        timeout: 5000, // Таймаут 5 секунд
      }).catch(err => {
        console.error('❌ Ошибка отправки в n8n:', err.message);
      });

    } catch (error) {
      console.error('❌ Ошибка подготовки данных для агента:', error.message);
    }
  }
}

export const agentService = new AgentService();

