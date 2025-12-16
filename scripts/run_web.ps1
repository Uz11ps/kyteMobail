# Упрощенный скрипт для запуска в браузере через web-server

Write-Host "🚀 Запуск Kyte Chat в браузере" -ForegroundColor Green
Write-Host ""

# Проверка Flutter
if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) {
    Write-Host "❌ Flutter не найден в PATH" -ForegroundColor Red
    exit 1
}

Write-Host "📦 Обновление зависимостей..." -ForegroundColor Yellow
flutter pub get | Out-Null

Write-Host ""
Write-Host "🔍 Проверка доступных портов..." -ForegroundColor Yellow

# Проверяем порты и находим свободный
$ports = @(8080, 8081, 8082, 8083, 8084, 8085)
$freePort = $null

foreach ($port in $ports) {
    $connection = Get-NetTCPConnection -LocalPort $port -ErrorAction SilentlyContinue
    if (-not $connection) {
        $freePort = $port
        break
    }
}

if (-not $freePort) {
    Write-Host "⚠️  Не удалось найти свободный порт, используем случайный..." -ForegroundColor Yellow
    $freePort = 0  # Flutter выберет свободный порт автоматически
} else {
    Write-Host "✅ Найден свободный порт: $freePort" -ForegroundColor Green
}

Write-Host ""
Write-Host "🌐 Запуск web-server..." -ForegroundColor Green
if ($freePort -ne 0) {
    Write-Host "   Приложение будет доступно по адресу: http://localhost:$freePort" -ForegroundColor Cyan
} else {
    Write-Host "   Приложение будет доступно по адресу, указанному после запуска" -ForegroundColor Cyan
}
Write-Host ""
Write-Host "💡 После запуска:" -ForegroundColor Yellow
Write-Host "   1. Откройте браузер и перейдите на указанный адрес" -ForegroundColor Gray
Write-Host "   2. Нажмите F12 для открытия DevTools" -ForegroundColor Gray
Write-Host "   3. Перейдите на вкладку Network для просмотра запросов" -ForegroundColor Gray
Write-Host ""

if ($freePort -ne 0) {
    flutter run -d web-server --web-port=$freePort --web-hostname=localhost
} else {
    flutter run -d web-server --web-hostname=localhost
}

