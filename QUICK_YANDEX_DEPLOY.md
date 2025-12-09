# Быстрое развертывание в Yandex Cloud

## Быстрая инструкция (5 шагов)

### 1. Создайте VM в Yandex Cloud

1. Откройте: https://console.yandex.cloud
2. Выберите каталог: `ao7gso7afqnk7771b5l1`
3. **Compute Cloud → Виртуальные машины → Создать**
4. Настройки:
   - **Имя:** `kyte-backend`
   - **Зона:** `ru-central1-a` (или ближайшая)
   - **Платформа:** Intel Ice Lake
   - **vCPU:** 2, **RAM:** 2GB, **Диск:** 20GB SSD
   - **ОС:** Ubuntu 22.04 LTS
   - **Сеть:** Выберите подсеть в VPC `dbp2q6dsummhsc385asm`
   - **Публичный IP:** Автоматически
   - **SSH ключ:** Добавьте ваш публичный ключ

### 2. Подключитесь к VM

```powershell
# Windows PowerShell
ssh ubuntu@51.250.XX.XX  # Замените на ваш IP
```

### 3. Установите необходимое ПО

```bash
# Обновление
sudo apt update && sudo apt upgrade -y

# Node.js
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt-get install -y nodejs

# PM2
sudo npm install -g pm2

# Git и Nginx
sudo apt-get install -y git nginx
```

### 4. Разверните приложение

```bash
# Создайте директорию
sudo mkdir -p /var/www/kyte-backend
cd /var/www/kyte-backend

# Загрузите файлы (из Windows):
# scp -r backend/* ubuntu@51.250.XX.XX:/tmp/backend/
# На сервере: sudo mv /tmp/backend/* /var/www/kyte-backend/backend/

cd backend
sudo npm install --production

# Создайте .env
sudo nano .env
# Вставьте ваши настройки (см. DEPLOY_YANDEX_CLOUD.md)

# Запустите
sudo pm2 start src/server.js --name kyte-backend
sudo pm2 save
sudo pm2 startup
```

### 5. Настройте Nginx

```bash
sudo nano /etc/nginx/sites-available/kyte-backend
```

Вставьте:
```nginx
server {
    listen 80;
    server_name _;

    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }
}
```

```bash
sudo ln -s /etc/nginx/sites-available/kyte-backend /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl restart nginx
```

### Готово!

Проверьте:
```bash
curl http://localhost:3000/api/health
```

Или из браузера:
```
http://51.250.XX.XX/api/health
```

---

## Загрузка файлов с Windows

```powershell
# Из PowerShell в директории проекта
cd C:\Users\1\Documents\GitHub\kyteMobail

# Загрузите backend
scp -r backend ubuntu@51.250.XX.XX:/tmp/

# На сервере переместите:
# sudo mv /tmp/backend/* /var/www/kyte-backend/backend/
```

---

## Настройка группы безопасности

В Yandex Cloud консоли:
1. **VPC → Группы безопасности**
2. Найдите группу вашей VM
3. Добавьте правила:
   - **Входящие:** 22 (SSH), 80 (HTTP), 443 (HTTPS)
   - **Исходящие:** Все разрешено

---

Подробная инструкция: см. `DEPLOY_YANDEX_CLOUD.md`

