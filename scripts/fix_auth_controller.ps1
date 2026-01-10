
param(
    [string]$ServerIP = "94.131.88.135",
    [string]$Username = "kyte-777",
    [string]$KeyPath = "C:\Users\1\.ssh\yandex_key\ssh-key-1765132631789"
)

Write-Host "🔧 Исправление auth.controller.js на сервере..." -ForegroundColor Cyan

# 1. Загружаем локальную версию (она должна быть нормальной)
Write-Host "📤 Загрузка файла..."
scp -i $KeyPath "backend/src/controllers/auth.controller.js" "${Username}@${ServerIP}:/var/www/kyte-backend/backend/src/controllers/auth.controller.js"

# 2. Очищаем от Windows символов и перезапускаем
Write-Host "🧹 Очистка и перезапуск..."
$cmd = @"
cd /var/www/kyte-backend/backend/src/controllers
sed -i 's/\r$//' auth.controller.js
# Также проверим и исправим экранирование если есть двойные слэши перед кавычками
sed -i 's/\\\\"/\\"/g' auth.controller.js
sudo pm2 restart kyte-backend
sleep 3
sudo pm2 logs kyte-backend --lines 20 --nostream
"@

ssh -i $KeyPath "$Username@$ServerIP" $cmd
Write-Host "✅ Готово"


