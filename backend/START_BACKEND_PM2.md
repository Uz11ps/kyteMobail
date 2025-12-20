# Запуск backend через PM2

## Проблема
Backend работает, но не управляется через PM2. Нужно найти текущий процесс и перезапустить через PM2.

## Решение

### 1. Найти как запущен backend

```bash
# Проверить процессы Node.js
ps aux | grep node

# Проверить что слушает порт 3000
sudo netstat -tlnp | grep 3000
# или
sudo ss -tlnp | grep 3000

# Проверить systemd сервисы
sudo systemctl list-units | grep -i kyte
sudo systemctl list-units | grep -i backend
```

### 2. Остановить текущий процесс (если запущен напрямую)

```bash
# Найти PID процесса на порту 3000
sudo lsof -i :3000

# Остановить процесс (замените PID на реальный)
# sudo kill PID
```

### 3. Запустить через PM2 с правильными настройками

```bash
cd /var/www/kyte-backend/backend

# Запустить через PM2
pm2 start src/server.js --name kyte-backend --update-env

# Сохранить конфигурацию
pm2 save

# Настроить автозапуск
pm2 startup
# Выполните команду которую покажет PM2

# Проверить статус
pm2 status
pm2 logs kyte-backend --lines 20
```

### 4. Проверить что переменные окружения загружены

```bash
# Проверить env переменные процесса
pm2 env kyte-backend | grep -E "SMS|AWS"
```

### 5. Протестировать отправку SMS

```bash
curl -X POST http://94.131.80.213/api/auth/phone/send-code \
  -H 'Content-Type: application/json' \
  -d '{"phone": "+79686288842"}'
```

### 6. Проверить логи для получения кода

```bash
pm2 logs kyte-backend --lines 30 --nostream
```

