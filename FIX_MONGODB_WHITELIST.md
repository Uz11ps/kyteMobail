# Исправление MongoDB Atlas Whitelist

## Проблема:
MongoDB Atlas блокирует подключение, потому что IP-адрес сервера Yandex Cloud не добавлен в whitelist.

---

## Решение 1: Добавить IP сервера в whitelist (рекомендуется)

### Шаг 1: Узнайте IP-адрес сервера

На сервере выполните:

```bash
curl ifconfig.me
# или
curl ipinfo.io/ip
```

Это покажет внешний IP-адрес вашего сервера.

### Шаг 2: Добавьте IP в MongoDB Atlas

1. Откройте MongoDB Atlas: https://cloud.mongodb.com/
2. Войдите в свой аккаунт
3. Выберите ваш кластер (Cluster0)
4. Перейдите в раздел **Network Access** (или **Security → Network Access**)
5. Нажмите **Add IP Address** или **Add Entry**
6. Вставьте IP-адрес сервера (например: `94.131.80.213`)
   - Или используйте CIDR: `94.131.80.213/32`
7. Нажмите **Confirm**
8. Подождите 1-2 минуты пока изменения применятся

### Шаг 3: Перезапустите backend

```bash
sudo pm2 restart kyte-backend
sudo pm2 logs kyte-backend --lines 50
```

---

## Решение 2: Разрешить все IP (менее безопасно, но быстрее)

Если нужно быстро протестировать:

1. Откройте MongoDB Atlas: https://cloud.mongodb.com/
2. Перейдите в **Network Access**
3. Нажмите **Add IP Address**
4. Введите: `0.0.0.0/0`
5. Добавьте комментарий: "Allow all IPs (temporary)"
6. Нажмите **Confirm**

⚠️ **Внимание:** Это разрешит доступ с любого IP-адреса. Используйте только для тестирования!

---

## Проверка подключения

После добавления IP в whitelist:

```bash
cd /var/www/kyte-backend/backend

# Проверьте подключение
node -e "require('dotenv').config(); const mongoose = require('mongoose'); mongoose.connect(process.env.MONGODB_URI).then(() => { console.log('✅ MongoDB подключен!'); process.exit(0); }).catch(e => { console.error('❌ Ошибка:', e.message); process.exit(1); });"
```

Если подключение успешно, перезапустите backend:

```bash
sudo pm2 restart kyte-backend
sudo pm2 logs kyte-backend --lines 50
curl http://localhost:3000/api/health
```

---

## Если IP сервера динамический

Если IP сервера может меняться, используйте один из вариантов:

1. **MongoDB Atlas Data API** (если доступен)
2. **VPN или фиксированный IP** от Yandex Cloud
3. **Временно разрешить все IP** (`0.0.0.0/0`) для разработки

---

## После исправления

Backend должен успешно подключиться к MongoDB и запуститься на порту 3000.

Проверьте:

```bash
curl http://localhost:3000/api/health
curl http://localhost/api/health
```

Должен вернуться: `{"status":"ok","timestamp":"..."}`

