
param(
    [string]$ServerIP = "94.131.88.135",
    [string]$Username = "kyte-777",
    [string]$KeyPath = "C:\Users\1\.ssh\yandex_key\ssh-key-1765132631789"
)

Write-Host "🔧 Окончательное исправление auth.controller.js..." -ForegroundColor Cyan

# 1. Загружаем исправленный файл
Write-Host "📤 Загрузка исправленного кода..."
scp -i $KeyPath "backend/src/controllers/auth.controller.js" "${Username}@${ServerIP}:/var/www/kyte-backend/backend/src/controllers/auth.controller.js"

# 2. Перезапуск
Write-Host "🔄 Перезапуск сервера..."
ssh -i $KeyPath "$Username@$ServerIP" "sudo pm2 restart kyte-backend && sleep 2 && sudo pm2 logs kyte-backend --lines 20 --nostream"

Write-Host "✅ Исправление применено" -ForegroundColor Green

