# Поиск и настройка backend на сервере

## Проблема
- Директория `~/kyte-backend` не существует
- Нужно найти где находится backend проект

## Решение

### 1. Найти где находится backend

```bash
# Поиск директории backend
find /home -name "backend" -type d 2>/dev/null
find /var/www -name "backend" -type d 2>/dev/null
find /opt -name "backend" -type d 2>/dev/null

# Или поиск по файлу server.js
find /home -name "server.js" 2>/dev/null
find /var/www -name "server.js" 2>/dev/null

# Проверить где работает PM2
pm2 list
pm2 info kyte-backend | grep "script path"
```

### 2. Проверить где запущен backend через PM2

```bash
# Список процессов PM2
pm2 list

# Детальная информация о процессе
pm2 info kyte-backend

# Или проверить все процессы
ps aux | grep node
```

### 3. После нахождения директории

```bash
# Перейти в найденную директорию (например /var/www/kyte-backend/backend)
cd /путь/к/backend

# Проверить наличие .env
ls -la .env

# Если файла нет, создать
touch .env
chmod 600 .env

# Добавить AWS настройки
echo "SMS_PROVIDER=aws" >> .env
echo "AWS_ACCESS_KEY_ID=AKIA5GBWTJIVKHZQ2SDN" >> .env
echo "AWS_SECRET_ACCESS_KEY=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" >> .env
echo "AWS_REGION=us-east-1" >> .env

# Установить aws-sdk
npm install aws-sdk

# Перезапустить сервер
pm2 restart kyte-backend
pm2 logs kyte-backend
```



