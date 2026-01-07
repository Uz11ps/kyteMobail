
param(
    [string]$ServerIP = "94.131.88.135",
    [string]$Username = "kyte-777",
    [string]$KeyPath = "C:\Users\1\.ssh\yandex_key\ssh-key-1765132631789"
)

Write-Host "🔧 Исправление сервера..." -ForegroundColor Cyan

# 1. Загрузка исправленного server.js
Write-Host "📤 Загрузка исправленного кода..."
scp -i $KeyPath "backend/src/server.js" "${Username}@${ServerIP}:/var/www/kyte-backend/backend/src/server.js"

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Ошибка загрузки файла" -ForegroundColor Red
    exit 1
}

# 2. Выполнение команд по одной для избежания проблем с CRLF
Write-Host "🔄 Перезапуск процессов..."
ssh -i $KeyPath "$Username@$ServerIP" "sudo pm2 restart kyte-backend"

Write-Host "⏳ Ожидание запуска..."
Start-Sleep -Seconds 5

Write-Host "📊 Проверка статуса..."
ssh -i $KeyPath "$Username@$ServerIP" "sudo pm2 status"

Write-Host "📜 Проверка логов (ошибки)..."
ssh -i $KeyPath "$Username@$ServerIP" "sudo pm2 logs kyte-backend --err --lines 10 --nostream"

Write-Host "✅ Готово" -ForegroundColor Green
