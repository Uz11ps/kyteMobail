#!/bin/bash

# Скрипт для настройки Nginx для Flutter веб-приложения

echo "🔧 Настройка Nginx для Flutter веб-приложения..."

# Создаем директорию для веб-приложения
sudo mkdir -p /var/www/kyte-mobile/web
sudo chown -R kyte-777:kyte-777 /var/www/kyte-mobile

# Создаем резервную копию текущей конфигурации
sudo cp /etc/nginx/sites-available/kyte-backend /etc/nginx/sites-available/kyte-backend.backup

# Обновляем конфигурацию Nginx
sudo tee /etc/nginx/sites-available/kyte-backend > /dev/null <<'EOF'
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
EOF

# Проверяем конфигурацию
echo "Проверка конфигурации Nginx..."
sudo nginx -t

if [ $? -eq 0 ]; then
    echo "✅ Конфигурация корректна"
    echo "Перезапуск Nginx..."
    sudo systemctl restart nginx
    echo "✅ Nginx перезапущен"
    echo ""
    echo "🌐 Flutter приложение будет доступно по адресу:"
    echo "   http://94.131.80.213/mobail/"
else
    echo "❌ Ошибка в конфигурации Nginx"
    echo "Восстановление из резервной копии..."
    sudo cp /etc/nginx/sites-available/kyte-backend.backup /etc/nginx/sites-available/kyte-backend
    exit 1
fi



