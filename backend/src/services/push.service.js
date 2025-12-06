import admin from 'firebase-admin';
import { User } from '../models/User.js';

// Инициализация Firebase Admin (опционально)
if (!admin.apps.length) {
  try {
    const projectId = process.env.FIREBASE_PROJECT_ID;
    const privateKey = process.env.FIREBASE_PRIVATE_KEY;
    const clientEmail = process.env.FIREBASE_CLIENT_EMAIL;

    // Инициализируем только если все параметры заданы
    if (projectId && privateKey && clientEmail) {
      admin.initializeApp({
        credential: admin.credential.cert({
          projectId,
          privateKey: privateKey.replace(/\\n/g, '\n'),
          clientEmail,
        }),
      });
      console.log('✅ Firebase Admin инициализирован');
    } else {
      console.log('⚠️  Firebase Admin не настроен (push-уведомления отключены)');
    }
  } catch (error) {
    console.error('⚠️  Ошибка инициализации Firebase Admin:', error.message);
    console.log('⚠️  Push-уведомления будут отключены');
  }
}

export const sendPushNotification = async (userId, title, body, data = {}) => {
  try {
    // Проверка инициализации Firebase
    if (!admin.apps.length) {
      return { success: false, message: 'Firebase не настроен' };
    }

    const user = await User.findById(userId);
    
    if (!user || !user.fcmToken) {
      return { success: false, message: 'FCM токен не найден' };
    }

    const message = {
      notification: {
        title,
        body,
      },
      data: {
        ...data,
        click_action: 'FLUTTER_NOTIFICATION_CLICK',
      },
      token: user.fcmToken,
    };

    const response = await admin.messaging().send(message);
    return { success: true, messageId: response };
  } catch (error) {
    console.error('Ошибка отправки push-уведомления:', error);
    return { success: false, error: error.message };
  }
};

export const sendPushToChatParticipants = async (chatId, title, body, excludeUserId = null) => {
  try {
    // Проверка инициализации Firebase
    if (!admin.apps.length) {
      return { success: false, message: 'Firebase не настроен' };
    }

    const { Chat } = await import('../models/Chat.js');
    const chat = await Chat.findById(chatId).populate('participants');
    
    if (!chat) {
      return { success: false, message: 'Чат не найден' };
    }

    const participants = chat.participants.filter(
      p => p._id.toString() !== excludeUserId && p.fcmToken
    );

    const tokens = participants.map(p => p.fcmToken);
    
    if (tokens.length === 0) {
      return { success: false, message: 'Нет активных FCM токенов' };
    }

    const message = {
      notification: {
        title,
        body,
      },
      data: {
        chatId: chatId.toString(),
        click_action: 'FLUTTER_NOTIFICATION_CLICK',
      },
      tokens,
    };

    const response = await admin.messaging().sendEachForMulticast(message);
    return { 
      success: true, 
      successCount: response.successCount,
      failureCount: response.failureCount,
    };
  } catch (error) {
    console.error('Ошибка отправки push-уведомлений:', error);
    return { success: false, error: error.message };
  }
};

