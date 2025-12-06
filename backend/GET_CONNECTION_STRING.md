# Получение Connection String из MongoDB Atlas

## Шаг 1: Выберите "Drivers"

В модальном окне "Connect to Cluster0" выберите:
**"Drivers"** (иконка с двоичным кодом 1011)

Это правильный вариант для подключения из Node.js приложения.

## Шаг 2: Выберите версию

После выбора "Drivers" вы увидите:
- **Driver:** Node.js
- **Version:** выберите последнюю (например, 5.5 или выше)

## Шаг 3: Скопируйте Connection String

Вы увидите строку вида:
```
mongodb+srv://<username>:<password>@cluster0.xxxxx.mongodb.net/?retryWrites=true&w=majority
```

**Важно:** Замените `<username>` и `<password>` на ваши реальные данные:
- Username: `zxcmandarin48_db_user`
- Password: `PeflQ6ZN6TemeRTJ`

Итоговая строка должна быть:
```
mongodb+srv://zxcmandarin48_db_user:PeflQ6ZN6TemeRTJ@cluster0.xxxxx.mongodb.net/kyte_chat?retryWrites=true&w=majority
```

**Обратите внимание:** Добавьте `/kyte_chat` перед `?` для указания базы данных.

## Шаг 4: Обновите .env файл

Откройте файл `backend/.env` и замените строку `MONGODB_URI` на вашу connection string.

