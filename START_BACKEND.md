# Запуск Backend на сервере

## Проблема: Backend не запущен

PM2 показывает пустой список, значит backend не был запущен.

---

## Шаги для запуска:

### 1. Перейдите в директорию backend:

```bash
cd /var/www/kyte-backend/backend
```

### 2. Проверьте что файлы на месте:

```bash
ls -la
ls -la src/
```

### 3. Проверьте .env файл:

```bash
cat .env
```

Если файла нет, создайте его:

```bash
sudo nano .env
```

Вставьте (замените секреты!):

```env
PORT=3000
NODE_ENV=production
MONGODB_URI=mongodb+srv://zxcmandarin48_db_user:PeflQ6ZN6TemeRTJ@cluster0.6xsfpcu.mongodb.net/kyte_chat?retryWrites=true&w=majority
JWT_SECRET=сгенерируйте-случайный-секрет-минимум-32-символа
JWT_REFRESH_SECRET=сгенерируйте-случайный-секрет-минимум-32-символа
JWT_EXPIRES_IN=24h
JWT_REFRESH_EXPIRES_IN=7d
OPENAI_API_KEY=your-openai-api-key
CORS_ORIGIN=http://localhost:8080,https://yourdomain.com
ENCRYPTION_KEY=сгенерируйте-32-символьный-ключ-шифрования
```

**Генерация секретов:**

```bash
openssl rand -base64 32  # для JWT_SECRET
openssl rand -base64 32  # для JWT_REFRESH_SECRET
openssl rand -base64 24  # для ENCRYPTION_KEY
```

### 4. Установите зависимости (если еще не установлены):

```bash
sudo npm install --production
```

### 5. Запустите backend через PM2:

```bash
sudo pm2 start src/server.js --name kyte-backend
sudo pm2 save
sudo pm2 startup
```

**Важно:** После `pm2 startup` выполните команду которую покажет PM2!

### 6. Проверьте статус:

```bash
sudo pm2 status
sudo pm2 logs kyte-backend --lines 50
```

### 7. Проверьте работу:

```bash
curl http://localhost:3000/api/health
curl http://localhost/api/health
```

---

## Если есть ошибки в логах:

```bash
sudo pm2 logs kyte-backend --lines 100
```

Проверьте:
- MongoDB подключение
- JWT секреты
- Порт 3000 не занят

---

## Если порт занят:

```bash
sudo lsof -i :3000
sudo kill -9 <PID>
sudo pm2 restart kyte-backend
```

