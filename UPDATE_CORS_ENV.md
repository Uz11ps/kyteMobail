# Обновление CORS_ORIGIN в .env на сервере

## Команды для выполнения на сервере:

Подключитесь к серверу через SSH и выполните:

```bash
# Перейдите в директорию backend
cd /var/www/kyte-backend/backend

# Создайте резервную копию текущего .env
cp .env .env.backup

# Откройте .env для редактирования
sudo nano .env
```

## Добавьте или обновите строку CORS_ORIGIN:

Найдите строку `CORS_ORIGIN` и замените её на:

```
CORS_ORIGIN=http://localhost:8080,http://localhost:8081,http://localhost:8082,http://localhost:8083,http://localhost:8084,http://localhost:8085
```

Если строки нет, добавьте её в конец файла.

## Сохраните файл:

- Нажмите `Ctrl+O` для сохранения
- Нажмите `Enter` для подтверждения
- Нажмите `Ctrl+X` для выхода

## Перезапустите backend:

```bash
sudo pm2 restart kyte-backend
```

## Проверьте логи:

```bash
sudo pm2 logs kyte-backend --lines 20
```

Должны увидеть, что сервер перезапустился с новыми настройками.

## Альтернативный способ (через sed):

Если хотите обновить автоматически:

```bash
cd /var/www/kyte-backend/backend

# Создайте резервную копию
cp .env .env.backup

# Добавьте или обновите CORS_ORIGIN
if grep -q "CORS_ORIGIN" .env; then
    # Обновить существующую строку
    sed -i 's|CORS_ORIGIN=.*|CORS_ORIGIN=http://localhost:8080,http://localhost:8081,http://localhost:8082,http://localhost:8083,http://localhost:8084,http://localhost:8085|' .env
else
    # Добавить новую строку
    echo "CORS_ORIGIN=http://localhost:8080,http://localhost:8081,http://localhost:8082,http://localhost:8083,http://localhost:8084,http://localhost:8085" >> .env
fi

# Перезапустите backend
sudo pm2 restart kyte-backend

# Проверьте что изменения применились
cat .env | grep CORS_ORIGIN
```



