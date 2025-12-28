# Все команды для выполнения на сервере

## ⚠️ ВАЖНО: Выполняйте команды последовательно!

---

## Шаг 1: Обновление системы и установка Node.js

```bash
# Обновление системы
sudo apt update && sudo apt upgrade -y

# Установка Node.js 20.x
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt-get install -y nodejs

# Проверка установки
node --version
npm --version
```

---

## Шаг 2: Установка PM2, Git и Nginx

```bash
# Установка PM2 (менеджер процессов)
sudo npm install -g pm2

# Установка Git и Nginx
sudo apt-get install -y git nginx

# Установка утилит
sudo apt-get install -y curl wget nano
```

---

## Шаг 3: Перемещение файлов backend

```bash
# Создайте директорию для приложения
sudo mkdir -p /var/www/kyte-backend

# Переместите файлы из /tmp
sudo mv /tmp/backend/* /var/www/kyte-backend/backend/

# Перейдите в директорию
cd /var/www/kyte-backend/backend

# Проверьте что файлы на месте
ls -la
```

---

## Шаг 4: Установка зависимостей

```bash
cd /var/www/kyte-backend/backend

# Установите зависимости
sudo npm install --production
```

---

## Шаг 5: Создание .env файла

```bash
cd /var/www/kyte-backend/backend

# Создайте .env файл
sudo nano .env
```

**Вставьте следующее (замените секреты!):**

```env
PORT=3000
NODE_ENV=production

# MongoDB Atlas
MONGODB_URI=mongodb+srv://zxcmandarin48_db_user:PeflQ6ZN6TemeRTJ@cluster0.6xsfpcu.mongodb.net/kyte_chat?retryWrites=true&w=majority

# JWT секреты (СГЕНЕРИРУЙТЕ НОВЫЕ!)
JWT_SECRET=сгенерируйте-случайный-секрет-минимум-32-символа
JWT_REFRESH_SECRET=сгенерируйте-случайный-секрет-минимум-32-символа
JWT_EXPIRES_IN=24h
JWT_REFRESH_EXPIRES_IN=7d

# OpenAI (если используете)
OPENAI_API_KEY=your-openai-api-key

# CORS (добавьте домены вашего приложения)
CORS_ORIGIN=http://localhost:8080,https://yourdomain.com

# Encryption ключ (32 символа)
ENCRYPTION_KEY=сгенерируйте-32-символьный-ключ-шифрования
```

**Генерация секретов (выполните перед созданием .env):**

```bash
# Генерация JWT секрета
openssl rand -base64 32

# Генерация encryption ключа
openssl rand -base64 24
```

**Сохраните файл:** `Ctrl+O`, `Enter`, `Ctrl+X`

---

## Шаг 6: Запуск приложения через PM2

```bash
cd /var/www/kyte-backend/backend

# Запустите приложение
sudo pm2 start src/server.js --name kyte-backend

# Сохраните конфигурацию
sudo pm2 save

# Настройте автозапуск при перезагрузке
sudo pm2 startup
```

**Важно:** После команды `pm2 startup` PM2 покажет команду вида:
```
sudo env PATH=$PATH:/usr/bin pm2 startup systemd -u kyte-777 --hp /home/kyte-777
```

**Выполните эту команду!**

```bash
# Проверьте статус
sudo pm2 status

# Просмотрите логи
sudo pm2 logs kyte-backend
```

---

## Шаг 7: Настройка Nginx

```bash
# Создайте конфигурацию
sudo nano /etc/nginx/sites-available/kyte-backend
```

**Вставьте следующее:**

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

**Сохраните:** `Ctrl+O`, `Enter`, `Ctrl+X`

```bash
# Активируйте конфигурацию
sudo ln -s /etc/nginx/sites-available/kyte-backend /etc/nginx/sites-enabled/

# Удалите дефолтную конфигурацию (опционально)
sudo rm /etc/nginx/sites-enabled/default

# Проверьте конфигурацию
sudo nginx -t

# Перезапустите Nginx
sudo systemctl restart nginx

# Проверьте статус Nginx
sudo systemctl status nginx
```

---

## Шаг 8: Настройка брандмауэра

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

---

## Шаг 9: Проверка работы

```bash
# Проверьте что приложение работает
curl http://localhost:3000/api/health

# Должен вернуться: {"status":"ok","timestamp":"..."}
```

**Из браузера откройте:**
```
http://94.131.88.135/api/health
```

---

## Полезные команды для управления

### PM2 команды:

```bash
# Просмотр логов
sudo pm2 logs kyte-backend

# Просмотр последних 100 строк логов
sudo pm2 logs kyte-backend --lines 100

# Перезапуск приложения
sudo pm2 restart kyte-backend

# Остановка приложения
sudo pm2 stop kyte-backend

# Статус приложения
sudo pm2 status

# Мониторинг ресурсов
sudo pm2 monit

# Информация о приложении
sudo pm2 info kyte-backend
```

### Nginx команды:

```bash
# Перезапуск Nginx
sudo systemctl restart nginx

# Проверка статуса
sudo systemctl status nginx

# Просмотр логов ошибок
sudo tail -f /var/log/nginx/error.log

# Просмотр логов доступа
sudo tail -f /var/log/nginx/access.log
```

### Обновление приложения:

```bash
# Перейдите в директорию
cd /var/www/kyte-backend/backend

# Если используете Git:
sudo git pull

# Или загрузите новые файлы через SCP из Windows

# Установите зависимости
sudo npm install --production

# Перезапустите приложение
sudo pm2 restart kyte-backend
```

---

## Полная последовательность команд (копируйте и выполняйте):

```bash
# 1. Обновление и установка Node.js
sudo apt update && sudo apt upgrade -y
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt-get install -y nodejs

# 2. Установка PM2, Git, Nginx
sudo npm install -g pm2
sudo apt-get install -y git nginx curl wget nano

# 3. Перемещение файлов
sudo mkdir -p /var/www/kyte-backend
sudo mv /tmp/backend/* /var/www/kyte-backend/backend/
cd /var/www/kyte-backend/backend

# 4. Установка зависимостей
sudo npm install --production

# 5. Генерация секретов
echo "JWT_SECRET:"
openssl rand -base64 32
echo "ENCRYPTION_KEY:"
openssl rand -base64 24

# 6. Создание .env (скопируйте секреты из шага 5)
sudo nano .env
# Вставьте содержимое .env (см. выше)

# 7. Запуск приложения
sudo pm2 start src/server.js --name kyte-backend
sudo pm2 save
sudo pm2 startup
# Выполните команду которую покажет PM2

# 8. Настройка Nginx
sudo nano /etc/nginx/sites-available/kyte-backend
# Вставьте конфигурацию Nginx (см. выше)
sudo ln -s /etc/nginx/sites-available/kyte-backend /etc/nginx/sites-enabled/
sudo rm /etc/nginx/sites-enabled/default
sudo nginx -t
sudo systemctl restart nginx

# 9. Настройка брандмауэра
sudo apt-get install -y ufw
sudo ufw allow 22/tcp
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw enable

# 10. Проверка
curl http://localhost:3000/api/health
sudo pm2 status
```

---

## Готово! 🎉

После выполнения всех команд ваш backend будет доступен по адресу:
- **http://94.131.88.135/api/health**

