// ВАЖНО: dotenv.config() должен быть ПЕРВЫМ
import dotenv from 'dotenv';
dotenv.config();

import express from 'express';
import { createServer } from 'http';
import { Server } from 'socket.io';
import cors from 'cors';
import helmet from 'helmet';
import path from 'path';
import { fileURLToPath } from 'url';

import { setupRoutes } from './routes/index.js';
import { setupSocketIO } from './socket/socket.js';
import { errorHandler } from './middleware/errorHandler.js';
import { connectDatabase } from './config/database.js';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

// Настройка CORS
const allowedOrigins = process.env.CORS_ORIGIN?.split(',') || '*';

const app = express();
const httpServer = createServer(app);
const io = new Server(httpServer, {
  cors: {
    origin: allowedOrigins,
    methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
    credentials: true,
  },
});

const PORT = process.env.PORT || 3000;

// Middleware
app.set('trust proxy', 1); // Доверяем Nginx
app.use(helmet({
  contentSecurityPolicy: false,
}));

app.use(cors({
  origin: allowedOrigins,
  credentials: true,
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS', 'PATCH'],
  allowedHeaders: ['Content-Type', 'Authorization', 'X-Requested-With', 'Accept', 'Origin'],
}));

app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Статика
app.use('/uploads', express.static(path.join(__dirname, '../uploads')));
app.use('/admin', express.static(path.join(__dirname, '../admin')));

app.get('/admin/*', (req, res) => {
  res.sendFile(path.join(__dirname, '../admin/index.html'));
});

// Запуск
connectDatabase().then(() => {
  setupRoutes(app);
  setupSocketIO(io);
  app.use(errorHandler);

  httpServer.listen(PORT, () => {
    console.log(`🚀 Server running on port ${PORT}`);
  });
}).catch((error) => {
  console.error('❌ Server startup error:', error);
  process.exit(1);
});

export { io };
