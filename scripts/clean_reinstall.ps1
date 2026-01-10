
param(
    [string]$ServerIP = "94.131.88.135",
    [string]$Username = "kyte-777",
    [string]$KeyPath = "C:\Users\1\.ssh\yandex_key\ssh-key-1765132631789"
)

Write-Host "🔧 Очистка и перезагрузка backend..." -ForegroundColor Cyan

# Полностью очищаем файл на сервере и загружаем заново (чтобы убрать скрытые символы)
# 1. Удаляем файл
ssh -i $KeyPath "$Username@$ServerIP" "rm -f /var/www/kyte-backend/backend/src/server.js"

# 2. Загружаем чистый файл
scp -i $KeyPath "backend/src/server.js" "${Username}@${ServerIP}:/var/www/kyte-backend/backend/src/server.js"

# 3. Переустанавливаем модули (возможно там ошибка)
$remoteCmd = @"
cd /var/www/kyte-backend/backend
sudo pm2 stop kyte-backend
sudo rm -rf node_modules package-lock.json
npm install
sudo pm2 restart kyte-backend
sleep 5
sudo pm2 logs kyte-backend --lines 20 --nostream
"@

ssh -i $KeyPath -t "$Username@$ServerIP" $remoteCmd

Write-Host "✅ Готово" -ForegroundColor Green


