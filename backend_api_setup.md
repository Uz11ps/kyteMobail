# Настройка Backend API с WebSocket

## Требования к Backend API

Backend должен предоставлять следующие эндпоинты и функциональность:

### REST API Endpoints

#### Аутентификация

**POST /auth/login**
```json
// Request
{
  "email": "user@example.com",
  "password": "password123"
}
// или
{
  "phone": "+79991234567",
  "code": "123456"
}

// Response
{
  "user": {
    "id": "user-id",
    "email": "user@example.com",
    "name": "User Name",
    "phone": "+79991234567"
  },
  "accessToken": "jwt-access-token",
  "refreshToken": "jwt-refresh-token"
}
```

**POST /auth/register**
```json
// Request
{
  "email": "user@example.com",
  "password": "password123",
  "name": "User Name" // опционально
}

// Response
{
  "user": {
    "id": "user-id",
    "email": "user@example.com",
    "name": "User Name"
  },
  "accessToken": "jwt-access-token",
  "refreshToken": "jwt-refresh-token"
}
```

**POST /auth/refresh**
```json
// Request
{
  "refreshToken": "jwt-refresh-token"
}

// Response
{
  "accessToken": "new-jwt-access-token"
}
```

**POST /auth/gmail/token**
```json
// Request
{
  "token": "google-oauth-token"
}

// Response
{
  "success": true
}
```

#### Чаты

**GET /chats**
Headers: `Authorization: Bearer {accessToken}`

Response:
```json
{
  "chats": [
    {
      "id": "chat-id",
      "name": "Chat Name",
      "type": "group", // или "direct"
      "participantIds": ["user-id-1", "user-id-2"],
      "inviteCode": "ABC123", // только для групп
      "createdAt": "2024-01-01T00:00:00Z",
      "lastMessageAt": "2024-01-01T12:00:00Z",
      "lastMessage": "Последнее сообщение"
    }
  ]
}
```

**GET /chats/{chatId}/messages?limit=100**
Headers: `Authorization: Bearer {accessToken}`

Response:
```json
{
  "messages": [
    {
      "id": "message-id",
      "chatId": "chat-id",
      "userId": "user-id",
      "userName": "User Name",
      "content": "Message content",
      "type": "text", // "text", "ai", "system"
      "createdAt": "2024-01-01T00:00:00Z",
      "metadata": {
        "meetUrl": "https://meet.google.com/xxx-xxxx-xxx", // опционально
        "suggestMeet": true // опционально
      }
    }
  ]
}
```

**POST /chats/{chatId}/messages**
Headers: `Authorization: Bearer {accessToken}`

Request:
```json
{
  "content": "Message text"
}
```

Response:
```json
{
  "message": {
    "id": "message-id",
    "chatId": "chat-id",
    "userId": "user-id",
    "userName": "User Name",
    "content": "Message text",
    "type": "text",
    "createdAt": "2024-01-01T00:00:00Z"
  }
}
```

#### Группы

**POST /groups**
Headers: `Authorization: Bearer {accessToken}`

Request:
```json
{
  "name": "Group Name",
  "participantIds": ["user-id-1", "user-id-2"]
}
```

Response:
```json
{
  "group": {
    "id": "group-id",
    "name": "Group Name",
    "type": "group",
    "participantIds": ["user-id-1", "user-id-2"],
    "inviteCode": "ABC123",
    "createdAt": "2024-01-01T00:00:00Z"
  }
}
```

**POST /groups/join**
Headers: `Authorization: Bearer {accessToken}`

Request:
```json
{
  "inviteCode": "ABC123"
}
```

Response:
```json
{
  "group": {
    "id": "group-id",
    "name": "Group Name",
    "type": "group",
    "participantIds": ["user-id-1", "user-id-2"],
    "inviteCode": "ABC123",
    "createdAt": "2024-01-01T00:00:00Z"
  }
}
```

#### AI

**POST /ai/ask**
Headers: `Authorization: Bearer {accessToken}`

Request:
```json
{
  "chatId": "chat-id",
  "question": "User question"
}
```

Response:
```json
{
  "message": {
    "id": "message-id",
    "chatId": "chat-id",
    "userId": "ai-user-id",
    "content": "AI response",
    "type": "ai",
    "createdAt": "2024-01-01T00:00:00Z",
    "metadata": {
      "suggestMeet": true, // если AI рекомендует создать встречу
      "meetUrl": "https://meet.google.com/xxx-xxxx-xxx" // если встреча создана
    }
  }
}
```

**GET /ai/suggestions?chatId={chatId}**
Headers: `Authorization: Bearer {accessToken}`

Response:
```json
{
  "suggestions": [
    {
      "id": "suggestion-id",
      "chatId": "chat-id",
      "userId": "ai-user-id",
      "content": "AI suggestion",
      "type": "ai",
      "createdAt": "2024-01-01T00:00:00Z"
    }
  ]
}
```

**POST /google/meet/create**
Headers: `Authorization: Bearer {accessToken}`

Request:
```json
{}
```

Response:
```json
{
  "meetUrl": "https://meet.google.com/xxx-xxxx-xxx"
}
```

### WebSocket API

**Подключение:**
```
wss://your-api.com/ws/chat/{chatId}?token={accessToken}
```

**Формат сообщений:**

От клиента к серверу:
```json
{
  "type": "message",
  "content": "Message text"
}
```

От сервера к клиенту:
```json
{
  "id": "message-id",
  "chatId": "chat-id",
  "userId": "user-id",
  "userName": "User Name",
  "content": "Message content",
  "type": "text",
  "createdAt": "2024-01-01T00:00:00Z"
}
```

## Пример реализации Backend (Node.js + Socket.io)

Создайте файл `backend-example/server.js`:

```javascript
const express = require('express');
const http = require('http');
const socketIo = require('socket.io');
const jwt = require('jsonwebtoken');

const app = express();
const server = http.createServer(app);
const io = socketIo(server, {
  cors: {
    origin: "*",
    methods: ["GET", "POST"]
  }
});

const JWT_SECRET = 'your-secret-key';

// Middleware для проверки JWT
const authenticateSocket = (socket, next) => {
  const token = socket.handshake.query.token;
  if (!token) {
    return next(new Error('Authentication error'));
  }
  try {
    const decoded = jwt.verify(token, JWT_SECRET);
    socket.userId = decoded.userId;
    next();
  } catch (err) {
    next(new Error('Authentication error'));
  }
};

io.use(authenticateSocket);

// WebSocket подключения по чатам
io.on('connection', (socket) => {
  const chatId = socket.handshake.query.chatId;
  socket.join(`chat:${chatId}`);

  socket.on('message', async (data) => {
    // Сохранить сообщение в БД
    const message = {
      id: generateId(),
      chatId: chatId,
      userId: socket.userId,
      content: data.content,
      type: 'text',
      createdAt: new Date().toISOString()
    };

    // Отправить всем участникам чата
    io.to(`chat:${chatId}`).emit('message', message);
  });

  socket.on('disconnect', () => {
    socket.leave(`chat:${chatId}`);
  });
});

server.listen(3000, () => {
  console.log('Server running on port 3000');
});
```

## Настройка в приложении

Обновите `lib/core/config/app_config.dart` с вашими URL:

```dart
class AppConfig {
  static const String apiBaseUrl = 'https://your-backend-api.com';
  static const String wsBaseUrl = 'wss://your-backend-api.com';
  static const String googleClientId = 'your-google-client-id';
}
```

Или используйте переменные окружения при запуске:

```bash
flutter run --dart-define=API_BASE_URL=https://your-api.com \
           --dart-define=WS_BASE_URL=wss://your-api.com \
           --dart-define=GOOGLE_CLIENT_ID=your-client-id
```

## Тестирование WebSocket

Для тестирования можно использовать простой WebSocket сервер:

```bash
# Установка wscat для тестирования
npm install -g wscat

# Подключение к WebSocket
wscat -c "wss://your-api.com/ws/chat/chat-id?token=your-token"
```

## Безопасность

1. Используйте HTTPS/WSS для всех соединений
2. Валидируйте все входные данные
3. Используйте rate limiting
4. Логируйте все запросы
5. Регулярно обновляйте зависимости

