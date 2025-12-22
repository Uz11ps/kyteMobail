# Быстрое развертывание на сервере

## ✅ Сборка завершена!

Файлы готовы в `build\web\`

## 📤 Загрузка файлов на сервер

### Вариант 1: Через WinSCP/FileZilla (рекомендуется)

1. Подключитесь к серверу через SFTP:
   - Хост: `94.131.80.213`
   - Пользователь: `kyte-777`
   - Порт: `22`

2. Перейдите в `/var/www/kyte-mobile/web/` (создайте папку если её нет)

3. Загрузите **все файлы** из `build\web\` на сервер

### Вариант 2: Через scp (PowerShell)

```powershell
# Замените путь к ключу на ваш
scp -r -i C:\Users\1\.ssh\ваш_ключ build\web\* kyte-777@94.131.80.213:/var/www/kyte-mobile/web/
```

## ⚙️ Настройка на сервере

Подключитесь к серверу и выполните:

```bash
ssh kyte-777@94.131.80.213

# 1. Создайте директорию
sudo mkdir -p /var/www/kyte-mobile/web
sudo chown -R kyte-777:kyte-777 /var/www/kyte-mobile

# 2. Настройте Nginx (скопируйте весь блок)
sudo nano /etc/nginx/sites-available/kyte-backend
```

**Вставьте эту конфигурацию:**

```nginx
server {
    listen 80;
    server_name _;

    location /mobail {
        alias /var/www/kyte-mobile/web;
        try_files $uri $uri/ /mobail/index.html;
        
        location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {
            expires 1y;
            add_header Cache-Control "public, immutable";
        }
    }

    location /api {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    location /socket.io {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_cache_bypass $http_upgrade;
        proxy_connect_timeout 7d;
        proxy_send_timeout 7d;
        proxy_read_timeout 7d;
    }

    location /uploads {
        alias /var/www/kyte-backend/backend/uploads;
    }

    location /admin {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }

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

**Обновите CORS:**

```bash
cd /var/www/kyte-backend/backend
if grep -q "CORS_ORIGIN" .env; then
    sed -i 's|CORS_ORIGIN=.*|CORS_ORIGIN=http://94.131.80.213,http://localhost:8080,http://localhost:8081,http://localhost:8082,http://localhost:8083,http://localhost:8084,http://localhost:8085|' .env
else
    echo "CORS_ORIGIN=http://94.131.80.213,http://localhost:8080,http://localhost:8081,http://localhost:8082,http://localhost:8083,http://localhost:8084,http://localhost:8085" >> .env
fi
sudo pm2 restart kyte-backend
```

## ✅ Готово!

Откройте в браузере:
- **http://94.131.80.213/mobail/** - главная страница
- **http://94.131.80.213/mobail/login** - страница входа
- **http://94.131.80.213/mobail/register** - страница регистрации

Теперь вы можете полностью тестировать все эндпоинты!



