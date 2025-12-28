# Остановка старого процесса и использование PM2

## Проблема
Backend запущен от root (PID 177811), а PM2 запущен от пользователя. Нужно остановить старый процесс.

## Решение

### 1. Остановить старый процесс от root

```bash
# Остановить процесс от root
sudo kill 177811

# Или более мягко
sudo kill -TERM 177811

# Проверить что процесс остановлен
ps aux | grep node
sudo lsof -i :3000
```

### 2. Проверить что PM2 процесс работает

```bash
pm2 status
pm2 list
```

### 3. Проверить переменные окружения

```bash
# Проверить env файл
cat .env | grep -E "SMS|AWS"

# Проверить переменные в PM2 процессе (другой способ)
pm2 describe kyte-backend | grep -A 20 "env:"
```

### 4. Перезапустить PM2 процесс для загрузки новых env переменных

```bash
pm2 restart kyte-backend --update-env
pm2 logs kyte-backend --lines 20
```

### 5. Протестировать отправку SMS

```bash
curl -X POST http://94.131.88.135/api/auth/phone/send-code \
  -H 'Content-Type: application/json' \
  -d '{"phone": "+79686288842"}'
```

### 6. Проверить логи для получения кода

```bash
pm2 logs kyte-backend --lines 50 --nostream
```



