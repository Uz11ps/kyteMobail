# MVP API Documentation

Документация новых API endpoints, реализованных для MVP.

## Файлы и Документы

### Загрузка файла
```
POST /api/chats/:chatId/files
Authorization: Bearer <token>
Content-Type: multipart/form-data

Body:
- file: File (обязательно)
- messageId: String (опционально, для привязки к сообщению)

Response:
{
  "file": {
    "id": "...",
    "chatId": "...",
    "messageId": null,
    "uploadedBy": "...",
    "uploadedByName": "...",
    "url": "/uploads/file-1234567890.pdf",
    "type": "document",
    "name": "document.pdf",
    "size": 1024,
    "mimeType": "application/pdf",
    "createdAt": "2024-01-01T00:00:00.000Z"
  }
}
```

### Получение списка файлов чата
```
GET /api/chats/:chatId/files
Authorization: Bearer <token>

Response:
{
  "files": [
    {
      "id": "...",
      "chatId": "...",
      "messageId": "...",
      "uploadedBy": "...",
      "uploadedByName": "...",
      "url": "/uploads/file-1234567890.pdf",
      "type": "document",
      "name": "document.pdf",
      "size": 1024,
      "mimeType": "application/pdf",
      "createdAt": "2024-01-01T00:00:00.000Z"
    }
  ]
}
```

### Удаление файла
```
DELETE /api/files/:fileId
Authorization: Bearer <token>

Response:
{
  "message": "Файл удален"
}
```

## Google Calendar

### Получение событий календаря
```
GET /api/google/calendar/events?startDate=2024-01-01&endDate=2024-01-31
Authorization: Bearer <token>

Query Parameters:
- startDate: ISO Date (опционально)
- endDate: ISO Date (опционально)

Response:
{
  "events": [
    {
      "id": "...",
      "summary": "Встреча",
      "description": "...",
      "start": "2024-01-01T10:00:00Z",
      "end": "2024-01-01T11:00:00Z",
      "location": "...",
      "meetUrl": "https://meet.google.com/...",
      "htmlLink": "https://calendar.google.com/...",
      "attendees": [...]
    }
  ]
}
```

### Получение событий календаря для чата
```
GET /api/google/chats/:chatId/events
Authorization: Bearer <token>

Response:
{
  "events": [...]
}
```

## Лайки и Статистика

### Поставить/убрать лайк
```
POST /api/messages/:messageId/like
Authorization: Bearer <token>

Response:
{
  "message": {
    "id": "...",
    "chatId": "...",
    "userId": "...",
    "userName": "...",
    "content": "...",
    "type": "text",
    "likes": ["userId1", "userId2"],
    "likesCount": 2,
    "createdAt": "...",
    "metadata": null
  },
  "liked": true
}
```

### Отметить сообщения как прочитанные
```
POST /api/chats/:chatId/read
Authorization: Bearer <token>

Body:
{
  "lastMessageId": "..." // опционально
}

Response:
{
  "success": true
}
```

### Получение чатов (обновлено)
```
GET /api/chats
Authorization: Bearer <token>

Response:
{
  "chats": [
    {
      "id": "...",
      "name": "...",
      "type": "group",
      "participantIds": [...],
      "inviteCode": "...",
      "createdAt": "...",
      "lastMessageAt": "...",
      "lastMessage": "...",
      "unreadCount": 5,
      "likesCount": 42,
      "meetingsCount": 3
    }
  ]
}
```

## AI Popup Chat

### Отправить сообщение в AI чат
```
POST /api/ai/chat
Authorization: Bearer <token>

Body:
{
  "question": "Привет, как дела?"
}

Response:
{
  "chatId": "...",
  "userMessage": {
    "id": "...",
    "chatId": "...",
    "userId": "...",
    "userName": "...",
    "content": "Привет, как дела?",
    "type": "text",
    "createdAt": "..."
  },
  "aiMessage": {
    "id": "...",
    "chatId": "...",
    "userId": "...",
    "userName": "Kyte",
    "content": "Привет! У меня всё отлично...",
    "type": "ai",
    "createdAt": "...",
    "metadata": {...}
  }
}
```

### Получить историю AI чата
```
GET /api/ai/chat/history
Authorization: Bearer <token>

Response:
{
  "chatId": "...",
  "messages": [
    {
      "id": "...",
      "chatId": "...",
      "userId": "...",
      "userName": "User" | "Kyte",
      "content": "...",
      "type": "text" | "ai",
      "createdAt": "...",
      "metadata": null
    }
  ]
}
```

## WebSocket События

### message_liked
Отправляется при изменении лайков на сообщении:
```json
{
  "id": "...",
  "chatId": "...",
  "likes": ["userId1", "userId2"],
  "likesCount": 2
}
```

## Изменения в Моделях

### Message
- `likes`: Array<ObjectId> - массив ID пользователей, поставивших лайк
- `attachments`: Array<Object> - массив вложений
  - `url`: String
  - `type`: Enum['image', 'document', 'video', 'audio', 'other']
  - `name`: String
  - `size`: Number

### Chat
- `type`: Enum['direct', 'group', 'ai'] - добавлен тип 'ai'
- `readBy`: Array<Object> - массив данных о прочтении
  - `userId`: ObjectId
  - `lastReadMessageId`: ObjectId
  - `lastReadAt`: Date

### FileAttachment (новая модель)
- `chatId`: ObjectId
- `messageId`: ObjectId (опционально)
- `uploadedBy`: ObjectId
- `url`: String
- `type`: Enum
- `name`: String
- `size`: Number
- `mimeType`: String



