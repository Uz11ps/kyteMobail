# Скрипт для развертывания backend на Yandex Cloud

param(
    [string]$ServerIP = "94.131.88.135",
    [string]$Username = "kyte-777",
    [string]$KeyPath = "C:\Users\1\.ssh\yandex_key\ssh-key-1765132631789"
)

Write-Host "🚀 Развертывание backend на Yandex Cloud..." -ForegroundColor Green
Write-Host ""

# Проверка ключа
if (-not (Test-Path $KeyPath)) {
    Write-Host "❌ SSH ключ не найден: $KeyPath" -ForegroundColor Red
    exit 1
}

Write-Host "✅ SSH ключ найден" -ForegroundColor Green
Write-Host ""

# Проверка подключения
Write-Host "🔍 Проверка подключения..." -ForegroundColor Yellow
$testConnection = ssh -i $KeyPath -o ConnectTimeout=5 -o BatchMode=yes "$Username@$ServerIP" "echo 'OK'" 2>&1

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Не удалось подключиться" -ForegroundColor Red
    exit 1
}

Write-Host "✅ Подключение успешно" -ForegroundColor Green
Write-Host ""

# Загрузка файлов
Write-Host "📤 Загрузка backend на сервер..." -ForegroundColor Yellow
$backendPath = Join-Path $PSScriptRoot "..\backend"

if (-not (Test-Path $backendPath)) {
    Write-Host "❌ Директория backend не найдена: $backendPath" -ForegroundColor Red
    exit 1
}

# Загружаем через scp
scp -i $KeyPath -r "$backendPath\*" "${Username}@${ServerIP}:/tmp/backend/" 2>&1 | Out-Null

if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Файлы загружены" -ForegroundColor Green
} else {
    Write-Host "⚠️  Возможна ошибка при загрузке, проверьте вручную" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "📝 Следующие шаги на сервере:" -ForegroundColor Cyan
Write-Host ""
Write-Host "1. Подключитесь:" -ForegroundColor Yellow
Write-Host "   ssh -i `"$KeyPath`" $Username@$ServerIP" -ForegroundColor Gray
Write-Host ""
Write-Host "2. Выполните команды установки (см. DEPLOY_STEPS.md):" -ForegroundColor Yellow
Write-Host "   sudo apt update && sudo apt upgrade -y" -ForegroundColor Gray
Write-Host "   curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -" -ForegroundColor Gray
Write-Host "   sudo apt-get install -y nodejs pm2 nginx git" -ForegroundColor Gray
Write-Host ""
Write-Host "3. Переместите файлы:" -ForegroundColor Yellow
Write-Host "   sudo mkdir -p /var/www/kyte-backend" -ForegroundColor Gray
Write-Host "   sudo mv /tmp/backend/* /var/www/kyte-backend/backend/" -ForegroundColor Gray
Write-Host ""
Write-Host "4. Настройте и запустите (см. DEPLOY_STEPS.md)" -ForegroundColor Yellow
Write-Host ""
Write-Host "✅ Готово!" -ForegroundColor Green

