# Скрипт для сборки и развертывания Flutter веб-приложения на сервере

param(
    [string]$ServerIP = "94.131.88.135",
    [string]$Username = "kyte-777",
    [string]$KeyPath = "C:\Users\1\.ssh\yandex_key\ssh-key-1765132631789"
)

Write-Host "🚀 Сборка и развертывание Flutter веб-приложения" -ForegroundColor Green
Write-Host ""

# Проверка ключа
if (-not (Test-Path $KeyPath)) {
    Write-Host "❌ SSH ключ не найден: $KeyPath" -ForegroundColor Red
    exit 1
}

# Проверка Flutter
if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) {
    Write-Host "❌ Flutter не найден в PATH" -ForegroundColor Red
    exit 1
}

Write-Host "📦 Обновление зависимостей..." -ForegroundColor Yellow
flutter pub get
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Ошибка при обновлении зависимостей" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "🔨 Сборка веб-приложения для production..." -ForegroundColor Yellow
flutter build web --release --web-renderer html
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Ошибка при сборке" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "✅ Сборка завершена!" -ForegroundColor Green

# Развертывание
Write-Host "📤 Загрузка файлов на сервер..." -ForegroundColor Yellow

# Создаем директорию если нет (используем sudo на всякий случай, но владелец должен быть kyte-777)
# Сначала пытаемся создать как текущий пользователь
ssh -i $KeyPath -o StrictHostKeyChecking=no "$Username@$ServerIP" "mkdir -p /var/www/kyte-mobile/web"

# Загружаем файлы
$localPath = Join-Path $PSScriptRoot "..\build\web\*"
scp -i $KeyPath -r $localPath "${Username}@${ServerIP}:/var/www/kyte-mobile/web/"

if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Файлы успешно загружены" -ForegroundColor Green
    Write-Host ""
    Write-Host "🌐 Приложение доступно по адресу: http://$ServerIP/mobail/" -ForegroundColor Cyan
} else {
    Write-Host "❌ Ошибка при загрузке файлов. Проверьте права доступа." -ForegroundColor Red
    Write-Host "Попробуйте выполнить команду вручную:"
    Write-Host "scp -i `"$KeyPath`" -r build\web\* ${Username}@${ServerIP}:/var/www/kyte-mobile/web/"
    exit 1
}
