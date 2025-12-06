# Быстрый старт Backend

## 1. Установка зависимостей

```bash
cd backend
npm install
```

## 2. Настройка MongoDB

### Вариант A: Локальная установка
```bash
# Установите MongoDB и запустите
mongod
```

### Вариант B: MongoDB Atlas (облачный)
1. Создайте аккаунт на https://www.mongodb.com/cloud/atlas
2. Создайте бесплатный кластер
3. Получите connection string
4. Укажите в `.env` файле

## 3. Настройка переменных окружения

Скопируйте `.env.example` в `.env` и заполните:

```bash
cp .env.example .env
```

Минимально необходимые переменные для запуска:
```env
MONGODB_URI=mongodb://localhost:27017/kyte_chat
JWT_SECRET=your-secret-key-min-32-characters-long
JWT_REFRESH_SECRET=your-refresh-secret-key-min-32-chars
OPENAI_API_KEY=sk-your-openai-key
```

## 4. Запуск сервера

```bash
npm run dev
```

Сервер запустится на `http://localhost:3000`

## 5. Проверка работы

Откройте в браузере или выполните:
```bash
curl http://localhost:3000/api/health
```

Должен вернуть: `{"status":"ok","timestamp":"..."}`

## 6. Тестирование API

### Регистрация пользователя:
```bash
curl -X POST http://localhost:3000/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"123456","name":"Test User"}'
```

### Вход:
```bash
curl -X POST http://localhost:3000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"123456"}'
```

## 7. Подключение к мобильному приложению

Обновите в `lib/core/config/app_config.dart`:
```dart
static const String apiBaseUrl = 'http://localhost:3000';
static const String wsBaseUrl = 'ws://localhost:3000';
```

**Важно:** Для Android эмулятора используйте `10.0.2.2` вместо `localhost`:
```dart
static const String apiBaseUrl = 'http://10.0.2.2:3000';
static const String wsBaseUrl = 'ws://10.0.2.2:3000';
```

## Структура API

- `/api/auth/*` - Аутентификация
- `/api/chats/*` - Чаты и сообщения
- `/api/groups/*` - Группы
- `/api/ai/*` - AI функции
- `/api/google/*` - Google интеграция
- `/api/user/*` - Пользовательские настройки

## WebSocket

WebSocket доступен на том же порту через Socket.io:
```
ws://localhost:3000/?chatId={chatId}&token={jwt-token}
```

## Troubleshooting

### MongoDB не подключается
- Убедитесь что MongoDB запущен
- Проверьте MONGODB_URI в .env
- Для Atlas: проверьте IP whitelist

### Порт занят
- Измените PORT в .env
- Или остановите процесс на порту 3000

### OpenAI ошибки
- Проверьте OPENAI_API_KEY
- Убедитесь что на аккаунте есть кредиты

### CORS ошибки
- Обновите CORS_ORIGIN в .env
- Добавьте URL вашего Flutter приложения

