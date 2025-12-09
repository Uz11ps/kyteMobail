# Скрипт для загрузки backend на Yandex Cloud VM

param(
    [Parameter(Mandatory=$true)]
    [string]$ServerIP,
    
    [Parameter(Mandatory=$true)]
    [string]$Username = "ubuntu"
)

Write-Host "🚀 Загрузка backend на Yandex Cloud VM..." -ForegroundColor Green
Write-Host ""

# Проверка SSH ключа
$sshKey = "$env:USERPROFILE\.ssh\id_rsa"
if (-not (Test-Path $sshKey)) {
    Write-Host "❌ SSH ключ не найден: $sshKey" -ForegroundColor Red
    Write-Host "Создайте ключ: ssh-keygen -t rsa -b 4096" -ForegroundColor Yellow
    exit 1
}

Write-Host "✅ SSH ключ найден" -ForegroundColor Green
Write-Host ""

# Проверка подключения
Write-Host "🔍 Проверка подключения к серверу..." -ForegroundColor Yellow
$testConnection = ssh -o ConnectTimeout=5 -o BatchMode=yes "$Username@$ServerIP" "echo 'OK'" 2>&1

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Не удалось подключиться к серверу" -ForegroundColor Red
    Write-Host "Проверьте:" -ForegroundColor Yellow
    Write-Host "  1. IP адрес правильный: $ServerIP" -ForegroundColor Gray
    Write-Host "  2. SSH ключ добавлен в Yandex Cloud" -ForegroundColor Gray
    Write-Host "  3. Группа безопасности разрешает SSH (порт 22)" -ForegroundColor Gray
    exit 1
}

Write-Host "✅ Подключение успешно" -ForegroundColor Green
Write-Host ""

# Создание временной директории на сервере
Write-Host "📦 Подготовка сервера..." -ForegroundColor Yellow
ssh "$Username@$ServerIP" "mkdir -p /tmp/kyte-backend-upload" | Out-Null

# Загрузка файлов
Write-Host "📤 Загрузка файлов backend..." -ForegroundColor Yellow
$backendPath = Join-Path $PSScriptRoot "..\backend"

if (-not (Test-Path $backendPath)) {
    Write-Host "❌ Директория backend не найдена: $backendPath" -ForegroundColor Red
    exit 1
}

# Исключаем node_modules и другие ненужные файлы
$excludePatterns = @(
    "node_modules",
    ".git",
    "*.log",
    ".env"
)

$scpCommand = "scp -r"
foreach ($pattern in $excludePatterns) {
    $scpCommand += " --exclude='$pattern'"
}

# Загружаем через tar для лучшей производительности
Write-Host "📦 Создание архива..." -ForegroundColor Yellow
$tempArchive = "$env:TEMP\kyte-backend-$(Get-Date -Format 'yyyyMMddHHmmss').tar.gz"

# Создаем архив исключая ненужные файлы
$excludeArgs = $excludePatterns | ForEach-Object { "--exclude=$_" }
tar -czf $tempArchive -C (Split-Path $backendPath) backend $excludeArgs 2>$null

if ($LASTEXITCODE -ne 0) {
    Write-Host "⚠️  tar не найден, используем scp..." -ForegroundColor Yellow
    
    # Альтернативный способ через scp
    scp -r "$backendPath\*" "${Username}@${ServerIP}:/tmp/kyte-backend-upload/" 2>&1 | Out-Null
} else {
    Write-Host "📤 Загрузка архива..." -ForegroundColor Yellow
    scp $tempArchive "${Username}@${ServerIP}:/tmp/kyte-backend-upload/backend.tar.gz" 2>&1 | Out-Null
    
    Write-Host "📦 Распаковка на сервере..." -ForegroundColor Yellow
    ssh "$Username@$ServerIP" "cd /tmp/kyte-backend-upload && tar -xzf backend.tar.gz && rm backend.tar.gz" 2>&1 | Out-Null
    
    Remove-Item $tempArchive -ErrorAction SilentlyContinue
}

Write-Host "✅ Файлы загружены" -ForegroundColor Green
Write-Host ""

# Инструкции для завершения на сервере
Write-Host "📝 Следующие шаги на сервере:" -ForegroundColor Cyan
Write-Host ""
Write-Host "1. Подключитесь к серверу:" -ForegroundColor Yellow
Write-Host "   ssh $Username@$ServerIP" -ForegroundColor Gray
Write-Host ""
Write-Host "2. Переместите файлы:" -ForegroundColor Yellow
Write-Host "   sudo mkdir -p /var/www/kyte-backend" -ForegroundColor Gray
Write-Host "   sudo mv /tmp/kyte-backend-upload/backend/* /var/www/kyte-backend/backend/" -ForegroundColor Gray
Write-Host ""
Write-Host "3. Установите зависимости:" -ForegroundColor Yellow
Write-Host "   cd /var/www/kyte-backend/backend" -ForegroundColor Gray
Write-Host "   sudo npm install --production" -ForegroundColor Gray
Write-Host ""
Write-Host "4. Создайте .env файл:" -ForegroundColor Yellow
Write-Host "   sudo nano /var/www/kyte-backend/backend/.env" -ForegroundColor Gray
Write-Host ""
Write-Host "5. Запустите приложение:" -ForegroundColor Yellow
Write-Host "   sudo pm2 start src/server.js --name kyte-backend" -ForegroundColor Gray
Write-Host "   sudo pm2 save" -ForegroundColor Gray
Write-Host "   sudo pm2 startup" -ForegroundColor Gray
Write-Host ""
Write-Host "✅ Готово!" -ForegroundColor Green

