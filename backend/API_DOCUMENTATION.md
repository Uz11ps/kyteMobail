# API Документация

## Базовый URL
```
http://localhost:3000/api
```

## Аутентификация

Большинство endpoints требуют JWT токен в заголовке:
```
Authorization: Bearer <access_token>
```

## Endpoints

### Аутентификация

#### POST /auth/login
Вход пользователя

**Request:**
```json
{
  "email": "user@example.com",
  "password": "password123"
}
```
или
```json
{
  "phone": "+79991234567",
  "code": "123456"
}
```

**Response:**
```json
{
  "user": {
    "id": "user-id",
    "email": "user@example.com",
    "name": "User Name"
  },
  "accessToken": "jwt-token",
  "refreshToken": "refresh-token"
}
```

#### POST /auth/register
Регистрация нового пользователя

**Request:**
```json
{
  "email": "user@example.com",
  "password": "password123",
  "name": "User Name"
}
```

**Response:**
```json
{
  "user": {
    "id": "user-id",
    "email": "user@example.com",
    "name": "User Name"
  },
  "accessToken": "jwt-token",
  "refreshToken": "refresh-token"
}
```

#### POST /auth/refresh
Обновление access token

**Request:**
```json
{
  "refreshToken": "refresh-token"
}
```

**Response:**
```json
{
  "accessToken": "new-jwt-token",
  "refreshToken": "new-refresh-token"
}
```

#### POST /auth/gmail/token
Отправка Gmail OAuth токена

**Headers:** `Authorization: Bearer <token>`

**Request:**
```json
{
  "token": "google-oauth-token"
}
```

**Response:**
```json
{
  "success": true,
  "message": "Токен успешно сохранен"
}
```

### Чаты

#### GET /chats
Получение списка чатов пользователя

**Headers:** `Authorization: Bearer <token>`

**Response:**
```json
{
  "chats": [
    {
      "id": "chat-id",
      "name": "Chat Name",
      "type": "group",
      "participantIds": ["user-id-1", "user-id-2"],
      "inviteCode": "ABC123",
      "createdAt": "2024-01-01T00:00:00Z",
      "lastMessageAt": "2024-01-01T12:00:00Z",
      "lastMessage": "Последнее сообщение"
    }
  ]
}
```

#### GET /chats/:chatId/messages?limit=100
Получение сообщений чата

**Headers:** `Authorization: Bearer <token>`

**Response:**
```json
{
  "messages": [
    {
      "id": "message-id",
      "chatId": "chat-id",
      "userId": "user-id",
      "userName": "User Name",
      "content": "Message content",
      "type": "text",
      "createdAt": "2024-01-01T00:00:00Z",
      "metadata": null
    }
  ]
}
```

#### POST /chats/:chatId/messages
Отправка сообщения

**Headers:** `Authorization: Bearer <token>`

**Request:**
```json
{
  "content": "Message text"
}
```

**Response:**
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

### Группы

#### POST /groups
Создание группы

**Headers:** `Authorization: Bearer <token>`

**Request:**
```json
{
  "name": "Group Name",
  "participantIds": ["user-id-1", "user-id-2"]
}
```

**Response:**
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

#### POST /groups/join
Присоединение к группе

**Headers:** `Authorization: Bearer <token>`

**Request:**
```json
{
  "inviteCode": "ABC123"
}
```

**Response:**
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

### AI

#### POST /ai/ask
Запрос к AI

**Headers:** `Authorization: Bearer <token>`

**Request:**
```json
{
  "chatId": "chat-id",
  "question": "User question"
}
```

**Response:**
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
      "suggestMeet": true
    }
  }
}
```

#### GET /ai/suggestions?chatId=chat-id
Получение предложений AI

**Headers:** `Authorization: Bearer <token>`

**Response:**
```json
{
  "suggestions": [
    {
      "id": "suggestion-id",
      "chatId": "chat-id",
      "userId": "ai-user-id",
      "content": "AI suggestion",
      "type": "ai",
      "createdAt": "2024-01-01T00:00:00Z",
      "metadata": {
        "suggestMeet": true
      }
    }
  ]
}
```

### Google

#### POST /google/meet/create
Создание Google Meet

**Headers:** `Authorization: Bearer <token>`

**Request:**
```json
{}
```

**Response:**
```json
{
  "meetUrl": "https://meet.google.com/xxx-xxxx-xxx"
}
```

## WebSocket

### Подключение
```
wss://your-api.com/ws/chat/{chatId}?token={accessToken}
```

или через Socket.io:
```
ws://your-api.com/?chatId={chatId}&token={accessToken}
```

### События

#### От клиента:
- `join_chat` - присоединиться к чату
- `leave_chat` - покинуть чат

#### От сервера:
- `message` - новое сообщение
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

