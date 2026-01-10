import axios from 'axios';
import dotenv from 'dotenv';

dotenv.config();

class RocketChatService {
  constructor() {
    this.baseURL = process.env.ROCKET_CHAT_URL;
    this.userId = process.env.ROCKET_CHAT_USER_ID;
    this.authToken = process.env.ROCKET_CHAT_AUTH_TOKEN;
    this.username = process.env.ROCKET_CHAT_USER;
    this.password = process.env.ROCKET_CHAT_PASSWORD;
  }

  async login() {
    if (this.authToken && this.userId) return;

    try {
      const response = await axios.post(`${this.baseURL}/api/v1/login`, {
        user: this.username,
        password: this.password,
      });

      if (response.data.status === 'success') {
        this.userId = response.data.data.userId;
        this.authToken = response.data.data.authToken;
        console.log('✅ Rocket.Chat logged in successfully');
      }
    } catch (error) {
      console.error('❌ Rocket.Chat login error:', error.message);
    }
  }

  async postMessage(channel, text, attachments = []) {
    await this.login();

    try {
      const response = await axios.post(
        `${this.baseURL}/api/v1/chat.postMessage`,
        {
          channel,
          text,
          attachments,
        },
        {
          headers: {
            'X-Auth-Token': this.authToken,
            'X-User-Id': this.userId,
          },
        }
      );
      return response.data;
    } catch (error) {
      console.error('❌ Rocket.Chat postMessage error:', error.message);
      throw error;
    }
  }

  // Метод для интеграции с агентом (n8n)
  async sendToAgent(message, context = {}) {
    // Здесь мы можем отправлять сообщение в канал агента или напрямую
    // Например, если агент слушает определенный канал
    return this.postMessage('agent-channel', message, [
      {
        title: 'Context',
        text: JSON.stringify(context),
      },
    ]);
  }
}

export const rocketChatService = new RocketChatService();


