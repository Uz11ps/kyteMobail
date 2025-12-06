# Настройка Backend

## Требования

- Node.js 18+ 
- MongoDB 4.4+ (или PostgreSQL 12+)
- OpenAI API ключ
- Google Cloud проект (для Google Meet)
- Firebase проект (для push-уведомлений)

## Установка

```bash
cd backend
npm install
```

## Настройка переменных окружения

1. Скопируйте `.env.example` в `.env`
2. Заполните все необходимые переменные:

```env
# Server
PORT=3000
NODE_ENV=development

# Database
MONGODB_URI=mongodb://localhost:27017/kyte_chat

# JWT
JWT_SECRET=your-super-secret-jwt-key-min-32-chars
JWT_REFRESH_SECRET=your-super-secret-refresh-key-min-32-chars

# OpenAI
OPENAI_API_KEY=sk-...

# Google
GOOGLE_CLIENT_ID=your-client-id.apps.googleusercontent.com
GOOGLE_CLIENT_SECRET=your-client-secret
GOOGLE_REDIRECT_URI=http://localhost:3000/auth/google/callback

# Firebase Admin
FIREBASE_PROJECT_ID=your-project-id
FIREBASE_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----\n"
FIREBASE_CLIENT_EMAIL=firebase-adminsdk-...@your-project.iam.gserviceaccount.com

# Encryption
ENCRYPTION_KEY=your-32-character-encryption-key

# CORS
CORS_ORIGIN=http://localhost:8080,http://localhost:3000
```

## Запуск MongoDB

### Локально:
```bash
mongod
```

### Или используйте MongoDB Atlas (облачный):
1. Создайте аккаунт на https://www.mongodb.com/cloud/atlas
2. Создайте кластер
3. Получите connection string
4. Укажите в `MONGODB_URI`

## Запуск сервера

```bash
# Development режим (с автоперезагрузкой)
npm run dev

# Production режим
npm start
```

Сервер запустится на `http://localhost:3000`

## Проверка работы

```bash
curl http://localhost:3000/api/health
```

Должен вернуть:
```json
{"status":"ok","timestamp":"2024-01-01T00:00:00.000Z"}
```

## Тестирование API

Используйте Postman, Insomnia или curl для тестирования endpoints.

Пример регистрации:
```bash
curl -X POST http://localhost:3000/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"123456","name":"Test User"}'
```

## WebSocket тестирование

Используйте wscat или Socket.io клиент:

```bash
npm install -g wscat
wscat -c "ws://localhost:3000/?chatId=chat-id&token=your-jwt-token"
```

## Структура проекта

```
backend/
├── src/
│   ├── config/          # Конфигурация БД
│   ├── models/          # Mongoose модели
│   ├── routes/          # Express маршруты
│   ├── controllers/     # Контроллеры
│   ├── services/        # Бизнес-логика (OpenAI, Push)
│   ├── middleware/      # Middleware (auth, errors)
│   ├── socket/          # WebSocket обработчики
│   ├── utils/           # Утилиты (JWT, encryption)
│   └── server.js        # Точка входа
├── .env.example
├── package.json
└── README.md
```

## Следующие шаги

1. Настройте MongoDB
2. Получите OpenAI API ключ
3. Настройте Google Cloud проект
4. Настройте Firebase Admin
5. Запустите сервер
6. Протестируйте endpoints

