
param(
    [string]$ServerIP = "94.131.88.135",
    [string]$Username = "kyte-777",
    [string]$KeyPath = "C:\Users\1\.ssh\yandex_key\ssh-key-1765132631789"
)

Write-Host "🔧 Проверка запущенного порта..." -ForegroundColor Cyan

# Проверяем, какой процесс слушает порт 3000
$cmd = "sudo lsof -i :3000"
ssh -i $KeyPath "$Username@$ServerIP" $cmd

Write-Host "🔧 Проверка логов запуска..."
# Читаем последние 50 строк, чтобы увидеть момент запуска
ssh -i $KeyPath "$Username@$ServerIP" "sudo pm2 logs kyte-backend --lines 50 --nostream"


