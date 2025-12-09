# Развертывание Backend на Yandex Cloud VM

## Информация о сервере:

- **IP адрес:** 94.131.80.213
- **Логин:** kyte-777
- **ОС:** Ubuntu 24.04
- **Зона:** kz1-a (Казахстан)

## Шаг 1: Подключение к серверу

```powershell
# Windows PowerShell
ssh -l kyte-777 94.131.80.213
```

Если запросит пароль или ключ - используйте SSH ключ который дал заказчик.

---

## Шаг 2: Установка необходимого ПО

После подключения выполните на сервере:

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

## Шаг 3: Загрузка backend на сервер

### Вариант A: Через SCP (из Windows)

```powershell
# В PowerShell (из директории проекта)
cd C:\Users\1\Documents\GitHub\kyteMobail

# Загрузите backend директорию
scp -r backend kyte-777@94.131.80.213:/tmp/
```

### Вариант B: Через Git (на сервере)

```bash
# На сервере
cd /tmp
git clone <your-repo-url>
# Или загрузите файлы другим способом
```

---

## Шаг 4: Настройка приложения

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

Вставьте в `.env`:

```env
PORT=3000
NODE_ENV=production

# MongoDB Atlas (ваш существующий)
MONGODB_URI=mongodb+srv://zxcmandarin48_db_user:PeflQ6ZN6TemeRTJ@cluster0.6xsfpcu.mongodb.net/kyte_chat?retryWrites=true&w=majority

# JWT секреты (СГЕНЕРИРУЙТЕ НОВЫЕ для production!)
JWT_SECRET=сгенерируйте-случайный-секрет-минимум-32-символа
JWT_REFRESH_SECRET=сгенерируйте-случайный-секрет-минимум-32-символа
JWT_EXPIRES_IN=24h
JWT_REFRESH_EXPIRES_IN=7d

# OpenAI (если используете)
OPENAI_API_KEY=your-openai-api-key

# CORS - добавьте домены вашего приложения
CORS_ORIGIN=http://localhost:8080,https://yourdomain.com

# Encryption ключ (32 символа)
ENCRYPTION_KEY=сгенерируйте-32-символьный-ключ-шифрования
```

**Генерация секретов на сервере:**

```bash
# Генерация JWT секрета
openssl rand -base64 32

# Генерация encryption ключа
openssl rand -base64 24
```

---

## Шаг 5: Запуск приложения

```bash
cd /var/www/kyte-backend/backend

# Запустите через PM2
sudo pm2 start src/server.js --name kyte-backend

# Сохраните конфигурацию
sudo pm2 save

# Настройте автозапуск при перезагрузке
sudo pm2 startup
# Выполните команду которую покажет PM2 (будет что-то вроде:
# sudo env PATH=$PATH:/usr/bin pm2 startup systemd -u kyte-777 --hp /home/kyte-777)

# Проверьте статус
sudo pm2 status
sudo pm2 logs kyte-backend
```

---

## Шаг 6: Настройка Nginx

```bash
# Создайте конфигурацию
sudo nano /etc/nginx/sites-available/kyte-backend
```

Вставьте:

```nginx
server {
    listen 80;
    server_name _;

    # WebSocket поддержка
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

## Шаг 7: Настройка брандмауэра

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

## Шаг 8: Проверка работы

### На сервере:

```bash
# Проверьте что приложение работает
curl http://localhost:3000/api/health

# Должен вернуться: {"status":"ok","timestamp":"..."}
```

### Из браузера:

Откройте:
```
http://94.131.80.213/api/health
```

Должен вернуться JSON с `{"status":"ok",...}`

---

## Полезные команды

### Управление приложением:

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

### Обновление приложения:

```bash
cd /var/www/kyte-backend/backend

# Получите последние изменения (если используете Git)
sudo git pull

# Или загрузите новые файлы через SCP

# Установите зависимости
sudo npm install --production

# Перезапустите
sudo pm2 restart kyte-backend
```

---

## Настройка домена (опционально)

Если есть домен:

1. **В DNS провайдере** добавьте A-запись:
   ```
   @    A    94.131.80.213
   www  A    94.131.80.213
   ```

2. **Обновите Nginx конфигурацию:**
   ```bash
   sudo nano /etc/nginx/sites-available/kyte-backend
   ```
   Замените `server_name _;` на `server_name ваш-домен.com www.ваш-домен.com;`

3. **Настройте SSL:**
   ```bash
   sudo apt-get install -y certbot python3-certbot-nginx
   sudo certbot --nginx -d ваш-домен.com -d www.ваш-домен.com
   ```

---

## Готово! 🎉

Ваш backend теперь работает на:
- **IP:** http://94.131.80.213/api/health
- **Домен:** https://ваш-домен.com/api/health (если настроен)

---

## Troubleshooting

### Не могу подключиться по SSH:
- Проверьте что используете правильный ключ
- Проверьте группу безопасности в Yandex Cloud (порт 22)

### Приложение не отвечает:
- Проверьте PM2: `sudo pm2 status`
- Проверьте логи: `sudo pm2 logs kyte-backend`
- Проверьте что порт 3000 слушается: `sudo netstat -tlnp | grep 3000`

### Nginx не работает:
- Проверьте конфигурацию: `sudo nginx -t`
- Проверьте логи: `sudo tail -f /var/log/nginx/error.log`

