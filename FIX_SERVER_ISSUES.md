# Исправление проблем на сервере

## Проблемы:
1. ❌ Nginx конфигурация не создана
2. ⚠️ UFW был прерван
3. ❌ Backend не запущен (порт 3000 не отвечает)

---

## Исправление по порядку:

### 1. Проверьте статус backend:

```bash
sudo pm2 status
sudo pm2 logs kyte-backend --lines 50
```

Если backend не запущен, запустите:
```bash
cd /var/www/kyte-backend/backend
sudo pm2 start src/server.js --name kyte-backend
sudo pm2 save
```

---

### 2. Создайте конфигурацию Nginx:

```bash
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

**Активируйте:**
```bash
sudo ln -s /etc/nginx/sites-available/kyte-backend /etc/nginx/sites-enabled/
sudo rm -f /etc/nginx/sites-enabled/default
sudo nginx -t
sudo systemctl restart nginx
```

---

### 3. Настройте брандмауэр (правильно):

```bash
# Проверьте текущие правила
sudo ufw status

# Если нужно сбросить
sudo ufw --force reset

# Добавьте правила
sudo ufw allow 22/tcp comment 'SSH'
sudo ufw allow 80/tcp comment 'HTTP'
sudo ufw allow 443/tcp comment 'HTTPS'

# Включите (ответьте y)
sudo ufw --force enable

# Проверьте статус
sudo ufw status
```

---

### 4. Проверка работы:

```bash
# Проверьте backend
curl http://localhost:3000/api/health

# Проверьте через Nginx
curl http://localhost/api/health

# Проверьте статус PM2
sudo pm2 status

# Проверьте логи
sudo pm2 logs kyte-backend --lines 20
```

---

## Если backend не запускается:

```bash
cd /var/www/kyte-backend/backend

# Проверьте .env файл
cat .env

# Проверьте что файлы на месте
ls -la src/

# Попробуйте запустить вручную для проверки ошибок
node src/server.js
```

Если есть ошибки - исправьте их и перезапустите через PM2.

