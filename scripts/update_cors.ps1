# Скрипт для обновления CORS_ORIGIN на сервере

Write-Host "🔧 Обновление CORS_ORIGIN на сервере..." -ForegroundColor Green
Write-Host ""

$serverIP = "94.131.88.135"
$serverUser = "kyte-777"
$backendPath = "/var/www/kyte-backend/backend"

# Поиск SSH ключа
$sshKeys = @(
    "$env:USERPROFILE\.ssh\yandex_cloud",
    "$env:USERPROFILE\.ssh\yandex_key",
    "$env:USERPROFILE\.ssh\id_rsa",
    "$env:USERPROFILE\.ssh\id_ed25519"
)

$sshKey = $null
foreach ($key in $sshKeys) {
    if (Test-Path $key) {
        $sshKey = $key
        Write-Host "✅ Найден SSH ключ: $key" -ForegroundColor Green
        break
    }
}

if (-not $sshKey) {
    Write-Host "❌ SSH ключ не найден" -ForegroundColor Red
    Write-Host ""
    Write-Host "Пожалуйста, подключитесь к серверу вручную и выполните команды из файла UPDATE_CORS_ENV.md" -ForegroundColor Yellow
    exit 1
}

Write-Host ""
Write-Host "📝 Обновление CORS_ORIGIN..." -ForegroundColor Yellow

# Команда для обновления CORS_ORIGIN
$corsValue = "http://localhost:8080,http://localhost:8081,http://localhost:8082,http://localhost:8083,http://localhost:8084,http://localhost:8085"

$updateCommand = @"
cd $backendPath
cp .env .env.backup
if grep -q "CORS_ORIGIN" .env; then
    sed -i 's|CORS_ORIGIN=.*|CORS_ORIGIN=$corsValue|' .env
else
    echo "CORS_ORIGIN=$corsValue" >> .env
fi
cat .env | grep CORS_ORIGIN
"@

Write-Host "Выполнение команды на сервере..." -ForegroundColor Cyan
ssh -i $sshKey ${serverUser}@${serverIP} $updateCommand

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "✅ CORS_ORIGIN обновлен!" -ForegroundColor Green
    Write-Host ""
    Write-Host "🔄 Перезапуск backend..." -ForegroundColor Yellow
    
    ssh -i $sshKey ${serverUser}@${serverIP} "cd $backendPath && sudo pm2 restart kyte-backend"
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host ""
        Write-Host "✅ Backend перезапущен!" -ForegroundColor Green
        Write-Host ""
        Write-Host "Проверьте логи:" -ForegroundColor Cyan
        Write-Host "  ssh -i $sshKey ${serverUser}@${serverIP} 'sudo pm2 logs kyte-backend --lines 20'" -ForegroundColor Gray
    } else {
        Write-Host ""
        Write-Host "⚠️  Не удалось перезапустить backend автоматически" -ForegroundColor Yellow
        Write-Host "Выполните вручную: sudo pm2 restart kyte-backend" -ForegroundColor Yellow
    }
} else {
    Write-Host ""
    Write-Host "❌ Ошибка при обновлении CORS_ORIGIN" -ForegroundColor Red
    Write-Host ""
    Write-Host "Пожалуйста, подключитесь к серверу вручную:" -ForegroundColor Yellow
    Write-Host "  ssh -i $sshKey ${serverUser}@${serverIP}" -ForegroundColor Gray
    Write-Host ""
    Write-Host "И выполните команды из файла UPDATE_CORS_ENV.md" -ForegroundColor Yellow
}



