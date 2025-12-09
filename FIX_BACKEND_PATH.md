# Исправление пути к backend

## Проблема:
Команды выполнялись не из директории `/var/www/kyte-backend/backend/`, поэтому:
- `npm install` не нашел `package.json`
- PM2 не нашел `src/server.js`
- `.env` файл находится в неправильном месте

---

## Решение:

### 1. Проверьте где находятся файлы backend:

```bash
# Проверьте существует ли директория
ls -la /var/www/kyte-backend/backend/

# Если директории нет или пуста, проверьте /tmp
ls -la /tmp/backend/
```

### 2. Если файлы в /tmp/backend, переместите их:

```bash
sudo mkdir -p /var/www/kyte-backend
sudo mv /tmp/backend /var/www/kyte-backend/backend
```

### 3. Перейдите в правильную директорию:

```bash
cd /var/www/kyte-backend/backend
pwd  # Должно показать: /var/www/kyte-backend/backend
```

### 4. Переместите .env файл в правильное место:

```bash
# Скопируйте .env из домашней директории
sudo cp /home/kyte-777/.env /var/www/kyte-backend/backend/.env

# Или создайте заново
sudo nano /var/www/kyte-backend/backend/.env
```

Вставьте содержимое:

```env
PORT=3000
NODE_ENV=production
MONGODB_URI=mongodb+srv://zxcmandarin48_db_user:PeflQ6ZN6TemeRTJ@cluster0.6xsfpcu.mongodb.net/kyte_chat?retryWrites=true&w=majority
JWT_SECRET=e33bcebea669bd452b58ad02170ae0cf
JWT_REFRESH_SECRET=7c3cbdf507dd786dd5e7f22f2effb5bb
JWT_EXPIRES_IN=24h
JWT_REFRESH_EXPIRES_IN=7d
OPENAI_API_KEY=your-openai-api-key
CORS_ORIGIN=http://localhost:8080,https://yourdomain.com
ENCRYPTION_KEY=617ee4d03c1302288ea1e40b0da57814
```

### 5. Установите зависимости:

```bash
cd /var/www/kyte-backend/backend
sudo npm install --production
```

### 6. Запустите backend:

```bash
cd /var/www/kyte-backend/backend
sudo pm2 start src/server.js --name kyte-backend
sudo pm2 save
sudo pm2 status
sudo pm2 logs kyte-backend --lines 50
```

### 7. Проверьте работу:

```bash
curl http://localhost:3000/api/health
curl http://localhost/api/health
```

---

## Если файлы backend не были загружены:

Загрузите их с Windows:

```powershell
cd C:\Users\1\Documents\GitHub\kyteMobail
scp -i "C:\Users\1\.ssh\yandex_key\ssh-key-1765132631789" -r backend kyte-777@94.131.80.213:/tmp/
```

Затем на сервере:

```bash
sudo mkdir -p /var/www/kyte-backend
sudo mv /tmp/backend /var/www/kyte-backend/backend
cd /var/www/kyte-backend/backend
```

