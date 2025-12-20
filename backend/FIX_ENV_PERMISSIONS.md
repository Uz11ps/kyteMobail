# Исправление прав доступа к .env файлу

## Проблема
Ошибка: `[ Error writing .env: Permission denied ]`

## Решение

### Вариант 1: Проверить и исправить права доступа

```bash
# Проверить текущего пользователя
whoami

# Проверить владельца файла .env
ls -la .env

# Если файл принадлежит root или другому пользователю, изменить владельца
sudo chown kyte-777:kyte-777 .env

# Установить правильные права доступа (чтение/запись для владельца)
chmod 600 .env

# Теперь можно редактировать
nano .env
```

### Вариант 2: Использовать sudo для редактирования

```bash
sudo nano .env
```

После сохранения исправить права:
```bash
sudo chown kyte-777:kyte-777 .env
chmod 600 .env
```

### Вариант 3: Создать файл заново (если файл не существует или поврежден)

```bash
cd ~/kyte-backend

# Создать файл с правильными правами
touch .env
chmod 600 .env

# Отредактировать
nano .env
```

### Вариант 4: Добавить переменные через echo (быстрый способ)

```bash
cd ~/kyte-backend

# Добавить переменные в конец файла
echo "" >> .env
echo "SMS_PROVIDER=aws" >> .env
echo "AWS_ACCESS_KEY_ID=AKIA5GBWTJIVKHZQ2SDN" >> .env
echo "AWS_SECRET_ACCESS_KEY=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" >> .env
echo "AWS_REGION=us-east-1" >> .env

# Проверить содержимое
cat .env
```

## Проверка после исправления

```bash
# Проверить права доступа
ls -la .env

# Должно быть что-то вроде:
# -rw------- 1 kyte-777 kyte-777 1234 Dec 20 10:00 .env

# Проверить содержимое
cat .env | grep AWS
```

## Если ничего не помогает

```bash
# Удалить файл и создать заново
cd ~/kyte-backend
rm -f .env
touch .env
chmod 600 .env
nano .env
```

Затем добавить все необходимые переменные окружения.

