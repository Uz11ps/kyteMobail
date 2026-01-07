
param(
    [string]$ServerIP = "94.131.88.135",
    [string]$Username = "kyte-777",
    [string]$KeyPath = "C:\Users\1\.ssh\yandex_key\ssh-key-1765132631789"
)

Write-Host "🔧 Интерактивная отладка..." -ForegroundColor Cyan

# Останавливаем PM2
ssh -i $KeyPath "$Username@$ServerIP" "sudo pm2 stop kyte-backend"

# Запускаем node напрямую, чтобы увидеть точную ошибку
Write-Host "🏃 Запуск node src/server.js напрямую..."
ssh -i $KeyPath "$Username@$ServerIP" "cd /var/www/kyte-backend/backend && node src/server.js"

Write-Host "🏁 Тест завершен"

