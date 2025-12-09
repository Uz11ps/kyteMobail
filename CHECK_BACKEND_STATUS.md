# Проверка статуса Backend

## Проблема:
Backend запущен через PM2 (статус "online"), но порт 3000 не отвечает.

---

## Диагностика:

### 1. Проверьте полные логи (особенно ошибки):

```bash
sudo pm2 logs kyte-backend --lines 200 --err
```

### 2. Проверьте что процесс слушает порт 3000:

```bash
sudo netstat -tlnp | grep 3000
# или
sudo ss -tlnp | grep 3000
# или
sudo lsof -i :3000
```

### 3. Проверьте логи ошибок напрямую:

```bash
sudo tail -n 100 /root/.pm2/logs/kyte-backend-error.log
sudo tail -n 100 /root/.pm2/logs/kyte-backend-out.log
```

### 4. Попробуйте запустить вручную для просмотра ошибок:

```bash
cd /var/www/kyte-backend/backend
node src/server.js
```

Это покажет ошибки которые могут быть скрыты в PM2.

---

## Возможные проблемы:

### Проблема 1: MongoDB не подключается
Проверьте подключение к MongoDB:
```bash
cd /var/www/kyte-backend/backend
node -e "const mongoose = require('mongoose'); mongoose.connect(process.env.MONGODB_URI || 'mongodb+srv://zxcmandarin48_db_user:PeflQ6ZN6TemeRTJ@cluster0.6xsfpcu.mongodb.net/kyte_chat').then(() => console.log('OK')).catch(e => console.error(e));"
```

### Проблема 2: Порт занят другим процессом
```bash
sudo lsof -i :3000
sudo kill -9 <PID>
sudo pm2 restart kyte-backend
```

### Проблема 3: .env файл не читается
```bash
cd /var/www/kyte-backend/backend
cat .env
node -e "require('dotenv').config(); console.log('PORT:', process.env.PORT);"
```

---

## Решение:

После диагностики выполните:

```bash
# Остановите текущий процесс
sudo pm2 stop kyte-backend
sudo pm2 delete kyte-backend

# Запустите заново с выводом логов
cd /var/www/kyte-backend/backend
sudo pm2 start src/server.js --name kyte-backend --log-date-format="YYYY-MM-DD HH:mm:ss Z"

# Проверьте логи
sudo pm2 logs kyte-backend --lines 100
```

