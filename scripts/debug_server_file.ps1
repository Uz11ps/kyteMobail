
param(
    [string]$ServerIP = "94.131.88.135",
    [string]$Username = "kyte-777",
    [string]$KeyPath = "C:\Users\1\.ssh\yandex_key\ssh-key-1765132631789"
)

Write-Host "🔍 Проверка файла на сервере..." -ForegroundColor Cyan

# Читаем файл с сервера
ssh -i $KeyPath "$Username@$ServerIP" "cat /var/www/kyte-backend/backend/src/server.js"

Write-Host ""
Write-Host "🔍 Проверка node_modules (может там дубли)..."
ssh -i $KeyPath "$Username@$ServerIP" "ls -la /var/www/kyte-backend/backend/node_modules"

Write-Host ""
Write-Host "🔄 Принудительная перезапись..."
# Загружаем файл заново
scp -i $KeyPath "backend/src/server.js" "${Username}@${ServerIP}:/var/www/kyte-backend/backend/src/server.js"

# Перезапускаем
ssh -i $KeyPath "$Username@$ServerIP" "sudo pm2 restart kyte-backend && sudo pm2 logs kyte-backend --lines 20 --nostream"

