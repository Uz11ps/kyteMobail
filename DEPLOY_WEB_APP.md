# Развертывание Flutter веб-приложения на сервере

## План развертывания:

1. Собрать Flutter веб-приложение для production
2. Настроить Nginx для раздачи статических файлов по пути `/mobail`
3. Обновить конфигурацию приложения для работы с production URL
4. Загрузить файлы на сервер

## Шаг 1: Сборка Flutter веб-приложения

На вашем компьютере:

```bash
# Перейдите в директорию проекта
cd C:\Users\1\Documents\GitHub\kyteMobail

# Соберите веб-приложение для production
flutter build web --release --web-renderer html

# Файлы будут в директории: build/web/
```

## Шаг 2: Настройка Nginx на сервере

Подключитесь к серверу и обновите конфигурацию Nginx:

```bash
ssh kyte-777@94.131.88.135
sudo nano /etc/nginx/sites-available/kyte-backend
```

Добавьте конфигурацию для Flutter приложения:

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

Сохраните и перезапустите Nginx:

```bash
sudo nginx -t
sudo systemctl restart nginx
```

## Шаг 3: Создание директории на сервере

```bash
sudo mkdir -p /var/www/kyte-mobile/web
sudo chown -R kyte-777:kyte-777 /var/www/kyte-mobile
```

## Шаг 4: Загрузка файлов на сервер

На вашем компьютере (Windows PowerShell):

```powershell
# Используйте scp или sftp для загрузки файлов
# Замените путь к SSH ключу на ваш
scp -r -i C:\Users\1\.ssh\ваш_ключ build\web\* kyte-777@94.131.88.135:/var/www/kyte-mobile/web/
```

Или используйте WinSCP, FileZilla или другой SFTP клиент.

## Шаг 5: Обновление конфигурации приложения

Перед сборкой обновите `lib/core/config/app_config.dart`:

```dart
static const String apiBaseUrl = 'http://94.131.88.135';
static const String wsBaseUrl = 'ws://94.131.88.135';
```

## Шаг 6: Проверка

Откройте в браузере:
- http://94.131.88.135/mobail/ - главная страница
- http://94.131.88.135/mobail/login - страница входа
- http://94.131.88.135/api/health - проверка API



