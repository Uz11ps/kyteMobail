# Быстрое обновление CORS_ORIGIN

## Подключитесь к серверу:

```bash
ssh kyte-777@94.131.88.135
```

(Используйте ваш SSH ключ)

## Выполните эти команды на сервере:

```bash
# Перейдите в директорию backend
cd /var/www/kyte-backend/backend

# Создайте резервную копию
cp .env .env.backup

# Обновите CORS_ORIGIN (одна команда)
if grep -q "CORS_ORIGIN" .env; then
    sed -i 's|CORS_ORIGIN=.*|CORS_ORIGIN=http://localhost:8080,http://localhost:8081,http://localhost:8082,http://localhost:8083,http://localhost:8084,http://localhost:8085|' .env
else
    echo "CORS_ORIGIN=http://localhost:8080,http://localhost:8081,http://localhost:8082,http://localhost:8083,http://localhost:8084,http://localhost:8085" >> .env
fi

# Проверьте что изменения применились
cat .env | grep CORS_ORIGIN

# Перезапустите backend
sudo pm2 restart kyte-backend

# Проверьте логи
sudo pm2 logs kyte-backend --lines 10
```

## Альтернативный способ (через nano):

Если предпочитаете редактировать вручную:

```bash
cd /var/www/kyte-backend/backend
nano .env
```

Найдите строку `CORS_ORIGIN` и замените на:
```
CORS_ORIGIN=http://localhost:8080,http://localhost:8081,http://localhost:8082,http://localhost:8083,http://localhost:8084,http://localhost:8085
```

Сохраните: `Ctrl+O`, `Enter`, `Ctrl+X`

Затем перезапустите:
```bash
sudo pm2 restart kyte-backend
```









