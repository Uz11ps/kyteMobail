# Развертывание Flutter веб-приложения на сервере по пути /mobail

## Шаг 1: Сборка завершена ✅

Файлы находятся в `build\web\`

## Шаг 2: Настройка на сервере

### 2.1. Подключитесь к серверу:

```bash
ssh kyte-777@94.131.80.213
```

### 2.2. Создайте директорию:

```bash
sudo mkdir -p /var/www/kyte-mobile/web
sudo chown -R kyte-777:kyte-777 /var/www/kyte-mobile
```

### 2.3. Загрузите файлы на сервер:

**Способ A - через scp (из PowerShell на вашем компьютере):**

```powershell
# Найдите ваш SSH ключ и замените путь
scp -r -i C:\Users\1\.ssh\ваш_ключ build\web\* kyte-777@94.131.80.213:/var/www/kyte-mobile/web/
```

**Способ B - через WinSCP/FileZilla:**

1. Подключитесь к серверу через SFTP
2. Перейдите в `/var/www/kyte-mobile/web/`
3. Загрузите все файлы из `build\web\`

### 2.4. Настройте Nginx:

```bash
sudo nano /etc/nginx/sites-available/kyte-backend
```

**Замените содержимое на:**

```nginx
server {
    listen 80;
    server_name _;

    # Flutter веб-приложение по пути /mobail
    location /mobail {
        alias /var/www/kyte-mobile/web;
        try_files $uri $uri/ /mobail/index.html;
        
        # Кеширование статических файлов
        location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {
            expires 1y;
            add_header Cache-Control "public, immutable";
        }
    }

    # API проксирование
    location /api {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    # WebSocket для Socket.io
    location /socket.io {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_cache_bypass $http_upgrade;
        
        # Таймауты для WebSocket
        proxy_connect_timeout 7d;
        proxy_send_timeout 7d;
        proxy_read_timeout 7d;
    }

    # Загруженные файлы
    location /uploads {
        alias /var/www/kyte-backend/backend/uploads;
    }

    # Админ-панель
    location /admin {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }

    # Корневой путь - редирект на /mobail
    location = / {
        return 301 /mobail/;
    }
}
```

**Сохраните:** `Ctrl+O`, `Enter`, `Ctrl+X`

**Проверьте и перезапустите:**

```bash
sudo nginx -t
sudo systemctl restart nginx
```

### 2.5. Обновите CORS_ORIGIN в .env:

```bash
cd /var/www/kyte-backend/backend

# Обновите CORS_ORIGIN
if grep -q "CORS_ORIGIN" .env; then
    sed -i 's|CORS_ORIGIN=.*|CORS_ORIGIN=http://94.131.80.213,http://localhost:8080,http://localhost:8081,http://localhost:8082,http://localhost:8083,http://localhost:8084,http://localhost:8085|' .env
else
    echo "CORS_ORIGIN=http://94.131.80.213,http://localhost:8080,http://localhost:8081,http://localhost:8082,http://localhost:8083,http://localhost:8084,http://localhost:8085" >> .env
fi

# Перезапустите backend
sudo pm2 restart kyte-backend
```

## Шаг 3: Проверка

Откройте в браузере:
- **Главная:** http://94.131.80.213/mobail/
- **Вход:** http://94.131.80.213/mobail/login
- **Регистрация:** http://94.131.80.213/mobail/register
- **API Health:** http://94.131.80.213/api/health

## Готово! 🎉

Теперь вы можете тестировать приложение по адресу `http://94.131.80.213/mobail/`

