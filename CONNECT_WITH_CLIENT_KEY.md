# Подключение с ключом заказчика

## Найденные файлы:

- **Приватный ключ:** `C:\Users\1\.ssh\yandex_key\ssh-key-1765132631789`
- **Публичный ключ:** `C:\Users\1\.ssh\yandex_key\ssh-key-1765132631789.pub`

## Команда для подключения:

```powershell
ssh -i "C:\Users\1\.ssh\yandex_key\ssh-key-1765132631789" kyte-777@94.131.80.213
```

## После подключения:

Следуйте инструкциям в `DEPLOY_NOW.md` для развертывания backend.

### Быстрая установка:

```bash
# 1. Обновление и установка Node.js
sudo apt update && sudo apt upgrade -y
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt-get install -y nodejs pm2 nginx git

# 2. Загрузите backend с Windows:
# scp -r backend kyte-777@94.131.80.213:/tmp/

# 3. На сервере настройте и запустите (см. DEPLOY_NOW.md)
```

