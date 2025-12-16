import { google } from 'googleapis';
import { User } from '../models/User.js';
import { Message } from '../models/Message.js';
import { Chat } from '../models/Chat.js';
import { decrypt } from '../utils/encryption.js';

// Получение OAuth2 клиента для пользователя
const getOAuth2Client = (user) => {
  if (!user || !user.gmailOAuthToken) {
    return null;
  }

  const accessToken = decrypt(user.gmailOAuthToken);
  if (!accessToken) {
    return null;
  }

  const oauth2Client = new google.auth.OAuth2(
    process.env.GOOGLE_CLIENT_ID,
    process.env.GOOGLE_CLIENT_SECRET,
    process.env.GOOGLE_REDIRECT_URI
  );

  oauth2Client.setCredentials({
    access_token: accessToken,
  });

  return oauth2Client;
};

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

// Получение событий календаря пользователя
export const getCalendarEvents = async (req, res) => {
  try {
    const userId = req.user._id;
    const { chatId, startDate, endDate } = req.query;

    const user = await User.findById(userId);
    
    if (!user || !user.gmailOAuthToken) {
      return res.status(400).json({ 
        message: 'Google OAuth токен не настроен. Пожалуйста, подключите Google аккаунт в настройках.' 
      });
    }

    const oauth2Client = getOAuth2Client(user);
    if (!oauth2Client) {
      return res.status(400).json({ message: 'Не удалось настроить OAuth клиент' });
    }

    const calendar = google.calendar({ version: 'v3', auth: oauth2Client });

    // Параметры запроса
    const timeMin = startDate ? new Date(startDate).toISOString() : new Date().toISOString();
    const timeMax = endDate ? new Date(endDate).toISOString() : new Date(Date.now() + 30 * 24 * 60 * 60 * 1000).toISOString(); // +30 дней по умолчанию

    const response = await calendar.events.list({
      calendarId: 'primary',
      timeMin,
      timeMax,
      maxResults: 50,
      singleEvents: true,
      orderBy: 'startTime',
    });

    let events = response.data.items || [];

    // Если указан chatId, фильтруем события связанные с этим чатом
    if (chatId) {
      // Ищем сообщения с метаданными о встречах для этого чата
      const messagesWithMeetings = await Message.find({
        chatId,
        'metadata.meetUrl': { $exists: true },
      }).lean();

      const meetUrls = messagesWithMeetings.map(msg => msg.metadata?.meetUrl).filter(Boolean);
      
      // Фильтруем события по ссылкам на встречи
      events = events.filter(event => {
        const meetLink = event.conferenceData?.entryPoints?.[0]?.uri || 
                        event.hangoutLink ||
                        event.htmlLink;
        return meetUrls.some(url => meetLink && meetLink.includes(url.split('/').pop()));
      });
    }

    const formattedEvents = events.map(event => ({
      id: event.id,
      summary: event.summary || 'Без названия',
      description: event.description || '',
      start: event.start.dateTime || event.start.date,
      end: event.end.dateTime || event.end.date,
      location: event.location || '',
      meetUrl: event.conferenceData?.entryPoints?.[0]?.uri || event.hangoutLink || null,
      htmlLink: event.htmlLink,
      attendees: event.attendees?.map(a => ({
        email: a.email,
        displayName: a.displayName,
        responseStatus: a.responseStatus,
      })) || [],
    }));

    res.json({ events: formattedEvents });
  } catch (error) {
    console.error('Ошибка получения событий календаря:', error);
    res.status(500).json({ message: 'Ошибка получения событий календаря' });
  }
};

// Получение событий календаря для конкретного чата
export const getChatCalendarEvents = async (req, res) => {
  try {
    const { chatId } = req.params;
    const userId = req.user._id;

    // Проверка доступа к чату
    const chat = await Chat.findOne({
      _id: chatId,
      participants: userId,
    });

    if (!chat) {
      return res.status(403).json({ message: 'Доступ запрещен' });
    }

    // Используем общий метод с фильтрацией по chatId
    req.query.chatId = chatId;
    return getCalendarEvents(req, res);
  } catch (error) {
    console.error('Ошибка получения событий календаря чата:', error);
    res.status(500).json({ message: 'Ошибка сервера' });
  }
};

