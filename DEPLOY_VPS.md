# Развертывание Backend на VPS

## Рекомендуемый провайдер: Timeweb

### Шаг 1: Создание VPS

1. Зарегистрируйтесь на https://timeweb.com
2. Перейдите в **Облачные серверы → Создать сервер**
3. Выберите:
   - **ОС:** Ubuntu 22.04 LTS
   - **Конфигурация:** Минимум 1 CPU, 1GB RAM, 20GB SSD
   - **Регион:** Москва или Санкт-Петербург
4. Создайте сервер

### Шаг 2: Подключение к серверу

```bash
# Windows: используйте PowerShell или PuTTY
ssh root@ваш-ip-адрес

# Или через PuTTY:
# Host: ваш-ip-адрес
# Port: 22
# Username: root
# Password: из панели Timeweb
```

### Шаг 3: Настройка сервера

```bash
# Обновление системы
apt update && apt upgrade -y

# Установка Node.js 20.x
curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
apt-get install -y nodejs

# Проверка установки
node --version  # Должно быть v20.x.x
npm --version

# Установка PM2 (менеджер процессов)
npm install -g pm2

# Установка Nginx
apt-get install -y nginx

# Установка Git
apt-get install -y git
```

### Шаг 4: Развертывание приложения

```bash
# Создайте директорию для приложения
mkdir -p /var/www/kyte-backend
cd /var/www/kyte-backend

# Клонируйте репозиторий (или загрузите файлы)
git clone <your-repo-url> .

# Или загрузите через SCP из Windows:
# scp -r backend/* root@ваш-ip:/var/www/kyte-backend/

# Установите зависимости
cd backend
npm install --production

# Создайте .env файл
nano .env
```

### Шаг 5: Настройка .env файла

```env
PORT=3000
NODE_ENV=production

# MongoDB Atlas (уже настроен)
MONGODB_URI=mongodb+srv://zxcmandarin48_db_user:PeflQ6ZN6TemeRTJ@cluster0.6xsfpcu.mongodb.net/kyte_chat?retryWrites=true&w=majority

# JWT секреты (замените на случайные строки!)
JWT_SECRET=ваш-случайный-секрет-минимум-32-символа
JWT_REFRESH_SECRET=ваш-случайный-секрет-минимум-32-символа
JWT_EXPIRES_IN=24h
JWT_REFRESH_EXPIRES_IN=7d

# OpenAI (если используете)
OPENAI_API_KEY=ваш-openai-ключ

# CORS (замените на ваш домен)
CORS_ORIGIN=https://yourdomain.com,https://www.yourdomain.com

# Остальные переменные...
```

### Шаг 6: Запуск приложения

```bash
# Запустите через PM2
pm2 start src/server.js --name kyte-backend

# Сохраните конфигурацию PM2
pm2 save

# Настройте автозапуск при перезагрузке
pm2 startup
# Выполните команду которую покажет PM2

# Проверьте статус
pm2 status
pm2 logs kyte-backend
```

### Шаг 7: Настройка Nginx

```bash
# Создайте конфигурацию
nano /etc/nginx/sites-available/kyte-backend
```

Вставьте:

```nginx
server {
    listen 80;
    server_name your-domain.com www.your-domain.com;

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
    }
}
```

```bash
# Активируйте конфигурацию
ln -s /etc/nginx/sites-available/kyte-backend /etc/nginx/sites-enabled/

# Проверьте конфигурацию
nginx -t

# Перезапустите Nginx
systemctl restart nginx
```

### Шаг 8: Настройка SSL (Let's Encrypt)

```bash
# Установите Certbot
apt-get install -y certbot python3-certbot-nginx

# Получите SSL сертификат
certbot --nginx -d your-domain.com -d www.your-domain.com

# Автоматическое обновление (настроено автоматически)
```

### Шаг 9: Настройка брандмауэра

```bash
# Установите UFW
apt-get install -y ufw

# Разрешите SSH, HTTP, HTTPS
ufw allow 22/tcp
ufw allow 80/tcp
ufw allow 443/tcp

# Включите брандмауэр
ufw enable

# Проверьте статус
ufw status
```

### Шаг 10: Проверка работы

```bash
# Проверьте что приложение работает
curl http://localhost:3000/api/health

# Проверьте логи
pm2 logs kyte-backend

# Проверьте статус
pm2 status
```

---

## Полезные команды PM2:

```bash
# Просмотр логов
pm2 logs kyte-backend

# Перезапуск
pm2 restart kyte-backend

# Остановка
pm2 stop kyte-backend

# Удаление
pm2 delete kyte-backend

# Мониторинг
pm2 monit
```

---

## Обновление приложения:

```bash
cd /var/www/kyte-backend/backend

# Получите последние изменения
git pull

# Установите новые зависимости
npm install --production

# Перезапустите приложение
pm2 restart kyte-backend
```

---

## Мониторинг:

### UptimeRobot (бесплатно):
1. Зарегистрируйтесь на https://uptimerobot.com
2. Добавьте мониторинг: `https://your-domain.com/api/health`
3. Получайте уведомления при падении сервера

---

## Резервное копирование:

```bash
# Создайте скрипт бэкапа
nano /root/backup.sh
```

```bash
#!/bin/bash
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="/root/backups"
mkdir -p $BACKUP_DIR

# Бэкап .env файла
cp /var/www/kyte-backend/backend/.env $BACKUP_DIR/env_$DATE

# Бэкап через MongoDB Atlas (автоматически)
# Или экспорт данных если нужно
```

```bash
# Сделайте исполняемым
chmod +x /root/backup.sh

# Добавьте в cron (ежедневно в 3:00)
crontab -e
# Добавьте: 0 3 * * * /root/backup.sh
```

---

## Безопасность:

1. **Измените SSH порт** (опционально):
   ```bash
   nano /etc/ssh/sshd_config
   # Port 2222
   systemctl restart sshd
   ```

2. **Отключите вход по паролю, используйте ключи**:
   ```bash
   # На Windows создайте ключ
   ssh-keygen -t rsa -b 4096
   
   # Скопируйте на сервер
   ssh-copy-id root@ваш-ip
   ```

3. **Регулярно обновляйте систему**:
   ```bash
   apt update && apt upgrade -y
   ```

---

## Примерная стоимость:

- **VPS Timeweb:** 200-500₽/месяц
- **Домен:** ~200₽/год (~20₽/месяц)
- **Итого:** ~220-520₽/месяц

---

## Готово! 🎉

Ваш backend теперь работает на VPS и доступен по адресу:
- `https://your-domain.com/api/health`

