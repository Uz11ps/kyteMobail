# Пошаговое развертывание Backend

## ✅ Подключение работает!

Вы успешно подключились к серверу:
- **IP:** 94.131.88.135
- **Пользователь:** kyte-777
- **ОС:** Ubuntu (Linux)

---

## Шаг 1: Установка необходимого ПО

**Подключитесь к серверу:**
```powershell
ssh -i "C:\Users\1\.ssh\yandex_key\ssh-key-1765132631789" kyte-777@94.131.88.135
```

**На сервере выполните:**

```bash
# Обновление системы
sudo apt update && sudo apt upgrade -y

# Установка Node.js 20.x
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt-get install -y nodejs

# Проверка установки
node --version  # Должно быть v20.x.x
npm --version

# Установка PM2 (менеджер процессов)
sudo npm install -g pm2

# Установка Git и Nginx
sudo apt-get install -y git nginx

# Установка утилит
sudo apt-get install -y curl wget nano
```

---

## Шаг 2: Загрузка backend на сервер

**Из Windows PowerShell (в директории проекта):**

```powershell
cd C:\Users\1\Documents\GitHub\kyteMobail

# Загрузите backend на сервер
scp -i "C:\Users\1\.ssh\yandex_key\ssh-key-1765132631789" -r backend kyte-777@94.131.88.135:/tmp/
```


---

## Шаг 3: Настройка приложения на сервере

**Подключитесь к серверу и выполните:**

```bash
# Создайте директорию для приложения
sudo mkdir -p /var/www/kyte-backend
sudo mv /tmp/backend/* /var/www/kyte-backend/backend/
cd /var/www/kyte-backend/backend

# Установите зависимости
sudo npm install --production

# Создайте .env файл
sudo nano .env
```

**Вставьте в .env (замените секреты!):**

```env
PORT=3000
NODE_ENV=production

# MongoDB Atlas (ваш существующий)
MONGODB_URI=mongodb+srv://zxcmandarin48_db_user:PeflQ6ZN6TemeRTJ@cluster0.6xsfpcu.mongodb.net/kyte_chat?retryWrites=true&w=majority

# JWT секреты (СГЕНЕРИРУЙТЕ НОВЫЕ!)
JWT_SECRET=сгенерируйте-случайный-секрет-минимум-32-символа
JWT_REFRESH_SECRET=сгенерируйте-случайный-секрет-минимум-32-символа
JWT_EXPIRES_IN=24h
JWT_REFRESH_EXPIRES_IN=7d

# OpenAI (если используете)
OPENAI_API_KEY=your-openai-api-key

# CORS
CORS_ORIGIN=http://localhost:8080,https://yourdomain.com

# Encryption
ENCRYPTION_KEY=сгенерируйте-32-символьный-ключ
```

**Генерация секретов на сервере:**

```bash
# Генерация JWT секрета
openssl rand -base64 32

# Генерация encryption ключа
openssl rand -base64 24
```

**Сохраните файл:** `Ctrl+O`, `Enter`, `Ctrl+X`

---

## Шаг 4: Запуск приложения

```bash
cd /var/www/kyte-backend/backend

# Запустите через PM2
sudo pm2 start src/server.js --name kyte-backend

# Сохраните конфигурацию
sudo pm2 save

# Настройте автозапуск
sudo pm2 startup
# Выполните команду которую покажет PM2 (будет что-то вроде:
# sudo env PATH=$PATH:/usr/bin pm2 startup systemd -u kyte-777 --hp /home/kyte-777)

# Проверьте статус
sudo pm2 status
sudo pm2 logs kyte-backend
```

---

## Шаг 5: Настройка Nginx

```bash
# Создайте конфигурацию
sudo nano /etc/nginx/sites-available/kyte-backend
```

**Вставьте:**

```nginx
server {
    listen 80;
    server_name _;

    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
        
        # Таймауты для WebSocket
        proxy_connect_timeout 7d;
        proxy_send_timeout 7d;
        proxy_read_timeout 7d;
    }
}
```

```bash
# Активируйте конфигурацию
sudo ln -s /etc/nginx/sites-available/kyte-backend /etc/nginx/sites-enabled/

# Удалите дефолтную (опционально)
sudo rm /etc/nginx/sites-enabled/default

# Проверьте конфигурацию
sudo nginx -t

# Перезапустите Nginx
sudo systemctl restart nginx
```

---

## Шаг 6: Настройка брандмауэра

```bash
# Установите UFW
sudo apt-get install -y ufw

# Разрешите SSH, HTTP, HTTPS
sudo ufw allow 22/tcp
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp

# Включите брандмауэр
sudo ufw enable

# Проверьте статус
sudo ufw status
```

**Также проверьте группу безопасности в Yandex Cloud:**
1. В консоли: **VPC → Группы безопасности**
2. Найдите группу вашей VM
3. Убедитесь что открыты порты: 22, 80, 443

---

## Шаг 7: Проверка работы

### На сервере:

```bash
curl http://localhost:3000/api/health
```

Должен вернуться: `{"status":"ok","timestamp":"..."}`

### Из браузера:

Откройте:
```
http://94.131.88.135/api/health
```

---

## Готово! 🎉

Backend работает на: `http://94.131.88.135`

---

## Полезные команды:

```bash
# Просмотр логов
sudo pm2 logs kyte-backend

# Перезапуск
sudo pm2 restart kyte-backend

# Статус
sudo pm2 status

# Мониторинг
sudo pm2 monit
```

