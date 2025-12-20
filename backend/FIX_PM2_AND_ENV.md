# Исправление PM2 и настройка .env

## Проблемы:
1. В .env нет настроек SMS/AWS
2. PM2 процесс не найден
3. Нужно добавить AWS настройки и перезапустить

## Решение:

### 1. Проверить какие процессы PM2 запущены

```bash
pm2 list
```

### 2. Найти правильное имя процесса или запустить заново

```bash
# Если процесс называется по-другому, перезапустить его
pm2 restart all

# Или найти процесс по порту 3000
pm2 list | grep 3000

# Или запустить заново
cd /var/www/kyte-backend/backend
pm2 start src/server.js --name kyte-backend
pm2 save
```

### 3. Добавить AWS настройки в .env

```bash
# Добавить в конец .env файла
echo "" >> .env
echo "SMS_PROVIDER=aws" >> .env
echo "AWS_ACCESS_KEY_ID=AKIA5GBWTJIVKHZQ2SDN" >> .env
echo "AWS_SECRET_ACCESS_KEY=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" >> .env
echo "AWS_REGION=us-east-1" >> .env

# Проверить что добавилось
cat .env | tail -5
```

### 4. Перезапустить процесс с обновленными переменными окружения

```bash
# Перезапустить с обновлением env переменных
pm2 restart all --update-env

# Или если процесс называется kyte-backend
pm2 restart kyte-backend --update-env

# Проверить статус
pm2 status
```

### 5. Протестировать отправку SMS (исправленная команда)

```bash
# Использовать одинарные кавычки снаружи, двойные внутри
curl -X POST http://94.131.80.213/api/auth/phone/send-code \
  -H 'Content-Type: application/json' \
  -d '{"phone": "+79686288842"}'
```

### 6. Проверить логи

```bash
# Проверить последние логи
pm2 logs --lines 30 --nostream

# Или для конкретного процесса
pm2 logs kyte-backend --lines 30 --nostream
```

## Альтернатива: Если процесс не запущен через PM2

```bash
# Проверить запущен ли процесс напрямую
ps aux | grep node

# Если процесс запущен напрямую, остановить и запустить через PM2
pkill -f "node.*server.js"

# Запустить через PM2
cd /var/www/kyte-backend/backend
pm2 start src/server.js --name kyte-backend --update-env
pm2 save
pm2 startup
```

