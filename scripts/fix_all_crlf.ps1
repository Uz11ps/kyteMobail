
param(
    [string]$ServerIP = "94.131.88.135",
    [string]$Username = "kyte-777",
    [string]$KeyPath = "C:\Users\1\.ssh\yandex_key\ssh-key-1765132631789"
)

Write-Host "🔧 Полная очистка файлов от Windows-символов..." -ForegroundColor Cyan

# Используем однострочный скрипт, чтобы не зависеть от переносов строк в самом скрипте
$cmd = "find /var/www/kyte-backend/backend/ -name '*.js' -type f -exec sed -i 's/\r$//' {} +; sudo pm2 restart kyte-backend"

ssh -i $KeyPath "$Username@$ServerIP" $cmd

Write-Host "⏳ Проверка логов..."
Start-Sleep -Seconds 3
ssh -i $KeyPath "$Username@$ServerIP" "sudo pm2 logs kyte-backend --lines 10 --nostream"


