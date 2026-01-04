// ВАЖНО: dotenv.config() должен быть ПЕРВЫМ, до всех импортов которые используют process.env
import dotenv from 'dotenv';
dotenv.config();

import express from 'express';
import { createServer } from 'http';
import { Server } from 'socket.io';
import cors from 'cors';
import helmet from 'helmet';
import mongoose from 'mongoose';
import path from 'path';
import { fileURLToPath } from 'url';

import { setupRoutes } from './routes/index.js';
import { setupSocketIO } from './socket/socket.js';
import { errorHandler } from './middleware/errorHandler.js';
import { connectDatabase } from './config/database.js';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const corsOrigins = process.env.CORS_ORIGIN?.split(',') || '*';
const app = express();
const httpServer = createServer(app);
const io = new Server(httpServer, {
  cors: {
    origin: corsOrigins,
    methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
    credentials: true,
  },
});

const PORT = process.env.PORT || 3000;

// Middleware
app.use(helmet({
  contentSecurityPolicy: false, // Отключаем для админ-панели
}));

// Настройка CORS
const corsOrigins = process.env.CORS_ORIGIN?.split(',') || '*';
app.use(cors({
  origin: corsOrigins,
  credentials: true,
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS', 'PATCH'],
  allowedHeaders: ['Content-Type', 'Authorization', 'X-Requested-With', 'Accept', 'Origin'],
}));
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Статическая раздача загруженных файлов
app.use('/uploads', express.static(path.join(__dirname, '../uploads')));

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

