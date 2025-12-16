# Быстрое развертывание Flutter веб-приложения

## ✅ Шаг 1: Сборка завершена

Файлы готовы в `build\web\`

## 📋 Шаг 2: Команды для выполнения на сервере

Подключитесь к серверу и выполните все команды подряд:

```bash
# Подключение
ssh kyte-777@94.131.80.213

# Создание директории
sudo mkdir -p /var/www/kyte-mobile/web
sudo chown -R kyte-777:kyte-777 /var/www/kyte-mobile

# Загрузка файлов (выполните на вашем компьютере через scp или WinSCP)
# scp -r build\web\* kyte-777@94.131.80.213:/var/www/kyte-mobile/web/

# Настройка Nginx
sudo tee /etc/nginx/sites-available/kyte-backend > /dev/null <<'NGINX_EOF'
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
NGINX_EOF

# Проверка и перезапуск Nginx
sudo nginx -t && sudo systemctl restart nginx

# Обновление CORS_ORIGIN
cd /var/www/kyte-backend/backend
if grep -q "CORS_ORIGIN" .env; then
    sed -i 's|CORS_ORIGIN=.*|CORS_ORIGIN=http://94.131.80.213,http://localhost:8080,http://localhost:8081,http://localhost:8082,http://localhost:8083,http://localhost:8084,http://localhost:8085|' .env
else
    echo "CORS_ORIGIN=http://94.131.80.213,http://localhost:8080,http://localhost:8081,http://localhost:8082,http://localhost:8083,http://localhost:8084,http://localhost:8085" >> .env
fi

# Перезапуск backend
sudo pm2 restart kyte-backend

# Проверка
echo "Проверка работы:"
curl http://localhost/api/health
```

## 🌐 Шаг 3: Загрузка файлов

**На вашем компьютере (PowerShell):**

```powershell
# Найдите ваш SSH ключ
$sshKey = "C:\Users\1\.ssh\ваш_ключ"  # Замените на путь к вашему ключу

# Загрузите файлы
scp -r -i $sshKey build\web\* kyte-777@94.131.80.213:/var/www/kyte-mobile/web/
```

Или используйте WinSCP/FileZilla для загрузки всех файлов из `build\web\` в `/var/www/kyte-mobile/web/`

## ✅ Готово!

Откройте в браузере:
- http://94.131.80.213/mobail/ - главная
- http://94.131.80.213/mobail/login - вход
- http://94.131.80.213/mobail/register - регистрация

