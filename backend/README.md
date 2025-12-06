# Kyte Backend API

Backend сервер для чат-приложения Kyte Chat с интеграцией OpenAI и Google Meet.

## Технологии

- Node.js + Express
- Socket.io для WebSocket
- MongoDB (или PostgreSQL)
- JWT для аутентификации
- OpenAI API
- Google APIs для Meet
- Firebase Admin для push-уведомлений

## Установка

```bash
npm install
```

## Настройка

1. Скопируйте `.env.example` в `.env`
2. Заполните все необходимые переменные окружения
3. Убедитесь, что MongoDB запущен (или настройте PostgreSQL)

## Запуск

```bash
# Development режим
npm run dev

# Production режим
npm start
```

## API Endpoints

См. `API_DOCUMENTATION.md` для полной документации API.

## Структура проекта

```
backend/
├── src/
│   ├── config/          # Конфигурация
│   ├── models/          # Модели данных
│   ├── routes/          # API маршруты
│   ├── controllers/     # Контроллеры
│   ├── middleware/      # Middleware
│   ├── services/        # Бизнес-логика
│   ├── utils/           # Утилиты
│   └── server.js        # Точка входа
├── .env.example
└── package.json
```

