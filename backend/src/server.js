import express from 'express';
import { createServer } from 'http';
import { Server } from 'socket.io';
import cors from 'cors';
import helmet from 'helmet';
import dotenv from 'dotenv';
import mongoose from 'mongoose';
import path from 'path';
import { fileURLToPath } from 'url';

import { setupRoutes } from './routes/index.js';
import { setupSocketIO } from './socket/socket.js';
import { errorHandler } from './middleware/errorHandler.js';
import { connectDatabase } from './config/database.js';

dotenv.config();

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const app = express();
const httpServer = createServer(app);
const io = new Server(httpServer, {
  cors: {
    origin: process.env.CORS_ORIGIN?.split(',') || '*',
    methods: ['GET', 'POST'],
  },
});

const PORT = process.env.PORT || 3000;

// Middleware
app.use(helmet({
  contentSecurityPolicy: false, // Отключаем для админ-панели
}));
app.use(cors({
  origin: process.env.CORS_ORIGIN?.split(',') || '*',
  credentials: true,
}));
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Статическая раздача админ-панели
app.use('/admin', express.static(path.join(__dirname, '../admin')));

// Fallback для админ-панели (SPA routing)
app.get('/admin/*', (req, res) => {
  res.sendFile(path.join(__dirname, '../admin/index.html'));
});

// Подключение к базе данных
connectDatabase().then(() => {
  // Настройка маршрутов
  setupRoutes(app);

  // Настройка WebSocket
  setupSocketIO(io);

  // Обработка ошибок
  app.use(errorHandler);

  // Запуск сервера
  httpServer.listen(PORT, () => {
    console.log(`🚀 Сервер запущен на порту ${PORT}`);
    console.log(`📡 WebSocket доступен на ws://localhost:${PORT}`);
    console.log(`🌐 API доступен на http://localhost:${PORT}/api`);
  });
}).catch((error) => {
  console.error('❌ Не удалось запустить сервер:', error);
  process.exit(1);
});

export { io };

