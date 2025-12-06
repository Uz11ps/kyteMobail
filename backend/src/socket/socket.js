import { authenticateSocket } from '../middleware/auth.js';
import { Chat } from '../models/Chat.js';

export const setupSocketIO = (io) => {
  // Middleware для аутентификации
  io.use(authenticateSocket);

  io.on('connection', async (socket) => {
    console.log(`✅ Пользователь подключен: ${socket.userId}`);

    try {
      // Подключение к чатам пользователя
      const userChats = await Chat.find({
        participants: socket.userId,
      }).select('_id');

      userChats.forEach(chat => {
        socket.join(`chat:${chat._id}`);
      });

      // Подключение к конкретному чату из query параметров
      const chatId = socket.handshake.query.chatId;
      if (chatId) {
        const chat = await Chat.findOne({
          _id: chatId,
          participants: socket.userId,
        });
        if (chat) {
          socket.join(`chat:${chatId}`);
          console.log(`Пользователь ${socket.userId} присоединился к чату ${chatId}`);
        }
      }

      // Обработка подключения к конкретному чату
      socket.on('join_chat', async (chatId) => {
        try {
          // Проверка доступа
          const chat = await Chat.findOne({
            _id: chatId,
            participants: socket.userId,
          });

          if (chat) {
            socket.join(`chat:${chatId}`);
            console.log(`Пользователь ${socket.userId} присоединился к чату ${chatId}`);
          }
        } catch (error) {
          console.error('Ошибка присоединения к чату:', error);
        }
      });
    } catch (error) {
      console.error('Ошибка при подключении:', error);
    }

    // Обработка отключения от чата
    socket.on('leave_chat', (chatId) => {
      socket.leave(`chat:${chatId}`);
      console.log(`Пользователь ${socket.userId} покинул чат ${chatId}`);
    });

    // Обработка отключения
    socket.on('disconnect', () => {
      console.log(`❌ Пользователь отключен: ${socket.userId}`);
    });
  });
};

