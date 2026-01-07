
param(
    [string]$ServerIP = "94.131.88.135",
    [string]$Username = "kyte-777",
    [string]$KeyPath = "C:\Users\1\.ssh\yandex_key\ssh-key-1765132631789"
)

Write-Host "🔧 Очистка контроллера (через однострочную команду)..." -ForegroundColor Cyan

# Используем однострочник, так как cd в скрипте не срабатывал из-за CRLF в пути
$cmd = "sed -i 's/\r$//' /var/www/kyte-backend/backend/src/controllers/auth.controller.js && sudo pm2 restart kyte-backend"

ssh -i $KeyPath "$Username@$ServerIP" $cmd

Write-Host "⏳ Проверка логов (ждем 5 сек)..."
Start-Sleep -Seconds 5
ssh -i $KeyPath "$Username@$ServerIP" "sudo pm2 logs kyte-backend --lines 20 --nostream"

