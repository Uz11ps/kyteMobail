
param(
    [string]$ServerIP = "94.131.88.135",
    [string]$Username = "kyte-777",
    [string]$KeyPath = "C:\Users\1\.ssh\yandex_key\ssh-key-1765132631789"
)

Write-Host "🔧 Удаление CR символов и перезапуск..." -ForegroundColor Cyan

# Создаем временный скрипт очистки на сервере
$cleanScript = @"
cd /var/www/kyte-backend/backend/src
# Удаляем символы возврата каретки \r из server.js
sed -i 's/\r$//' server.js
echo '✅ CR символы удалены'
sudo pm2 restart kyte-backend
"@

ssh -i $KeyPath "$Username@$ServerIP" $cleanScript

Write-Host "⏳ Проверка логов..."
ssh -i $KeyPath "$Username@$ServerIP" "sudo pm2 logs kyte-backend --lines 10 --nostream"


