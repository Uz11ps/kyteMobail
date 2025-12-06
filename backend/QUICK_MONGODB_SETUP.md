# Быстрая настройка MongoDB (5 минут)

## Самый простой способ: MongoDB Atlas (БЕСПЛАТНО)

### Шаг 1: Регистрация (1 минута)
1. Откройте https://www.mongodb.com/cloud/atlas/register
2. Зарегистрируйтесь (можно через Google)

### Шаг 2: Создание кластера (2 минуты)
1. Нажмите "Build a Database"
2. Выберите **FREE** план (M0)
3. Выберите регион (любой)
4. Нажмите "Create"

### Шаг 3: Настройка доступа (1 минута)
1. В "Network Access" → "Add IP Address"
2. Выберите "Allow Access from Anywhere" (0.0.0.0/0)
3. Нажмите "Confirm"

### Шаг 4: Создание пользователя (1 минута)
1. В "Database Access" → "Add New Database User"
2. Username: `kyteuser` (или любое другое)
3. Password: придумайте пароль (запомните!)
4. Role: "Atlas admin"
5. Нажмите "Add User"

### Шаг 5: Получение Connection String
1. В "Database" → "Connect"
2. Выберите "Connect your application"
3. Скопируйте строку подключения

Она выглядит так:
```
mongodb+srv://kyteuser:<password>@cluster0.xxxxx.mongodb.net/?retryWrites=true&w=majority
```

### Шаг 6: Обновление .env файла

Создайте файл `backend/.env`:

```env
MONGODB_URI=mongodb+srv://kyteuser:ВАШ_ПАРОЛЬ@cluster0.xxxxx.mongodb.net/kyte_chat?retryWrites=true&w=majority
PORT=3000
NODE_ENV=development
JWT_SECRET=your-super-secret-jwt-key-min-32-characters-long-change-this
JWT_REFRESH_SECRET=your-super-secret-refresh-key-min-32-chars-change-this
OPENAI_API_KEY=your-openai-api-key-here
```

**Важно:** 
- Замените `<password>` на ваш реальный пароль
- Замените `cluster0.xxxxx` на ваш реальный кластер
- Добавьте `/kyte_chat` перед `?` для указания базы данных

### Готово! ✅

Теперь запустите backend:
```bash
cd backend
npm install
npm run dev
```

Вы должны увидеть:
```
✅ Подключено к MongoDB
🚀 Сервер запущен на порту 3000
```

---

## Альтернатива: Локальная установка (если не хотите использовать облако)

### Windows:

1. Скачайте MongoDB: https://www.mongodb.com/try/download/community
2. Установите (выберите "Complete" и "Install as Windows Service")
3. MongoDB запустится автоматически
4. В `.env` укажите:
   ```env
   MONGODB_URI=mongodb://localhost:27017/kyte_chat
   ```

### Проверка локальной установки:
```powershell
mongod --version
```

Если команда не найдена, добавьте MongoDB в PATH или используйте MongoDB Atlas.

