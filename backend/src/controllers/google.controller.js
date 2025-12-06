import { google } from 'googleapis';
import { User } from '../models/User.js';
import { decrypt } from '../utils/encryption.js';

export const createGoogleMeet = async (req, res) => {
  try {
    const userId = req.user._id;

    // Получение пользователя с токеном
    const user = await User.findById(userId);
    
    if (!user || !user.gmailOAuthToken) {
      return res.status(400).json({ 
        message: 'Google OAuth токен не настроен. Пожалуйста, подключите Google аккаунт в настройках.' 
      });
    }

    // Расшифровка токена
    const accessToken = decrypt(user.gmailOAuthToken);

    if (!accessToken) {
      return res.status(400).json({ message: 'Не удалось расшифровать токен' });
    }

    // Настройка OAuth2 клиента
    const oauth2Client = new google.auth.OAuth2(
      process.env.GOOGLE_CLIENT_ID,
      process.env.GOOGLE_CLIENT_SECRET,
      process.env.GOOGLE_REDIRECT_URI
    );

    oauth2Client.setCredentials({
      access_token: accessToken,
    });

    // Создание Google Meet через Calendar API
    const calendar = google.calendar({ version: 'v3', auth: oauth2Client });

    const event = {
      summary: 'Kyte Chat Meeting',
      description: 'Встреча создана из Kyte Chat',
      start: {
        dateTime: new Date().toISOString(),
        timeZone: 'UTC',
      },
      end: {
        dateTime: new Date(Date.now() + 60 * 60 * 1000).toISOString(), // +1 час
        timeZone: 'UTC',
      },
      conferenceData: {
        createRequest: {
          requestId: `meet-${Date.now()}`,
          conferenceSolutionKey: {
            type: 'hangoutsMeet',
          },
        },
      },
    };

    const createdEvent = await calendar.events.insert({
      calendarId: 'primary',
      conferenceDataVersion: 1,
      requestBody: event,
    });

    const meetUrl = createdEvent.data.conferenceData?.entryPoints?.[0]?.uri;

    if (!meetUrl) {
      return res.status(500).json({ message: 'Не удалось создать встречу' });
    }

    res.json({ meetUrl });
  } catch (error) {
    console.error('Ошибка создания Google Meet:', error);
    res.status(500).json({ message: 'Ошибка создания встречи' });
  }
};

