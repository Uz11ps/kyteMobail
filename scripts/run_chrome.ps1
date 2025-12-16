# PowerShell скрипт для запуска приложения в Chrome для тестирования с реальным backend

Write-Host "🚀 Запуск Kyte Chat в Chrome (с реальным backend)" -ForegroundColor Green
Write-Host ""

# Проверка Flutter
$flutterPath = Get-Command flutter -ErrorAction SilentlyContinue
if (-not $flutterPath) {
    Write-Host "⚠️  Flutter не найден в PATH, пытаюсь найти локально..." -ForegroundColor Yellow
    
    # Попытка найти Flutter в стандартных местах
    $possiblePaths = @(
        "$env:USERPROFILE\flutter\bin\flutter.bat",
        "$env:LOCALAPPDATA\flutter\bin\flutter.bat",
        "C:\flutter\bin\flutter.bat"
    )
    
    $flutterFound = $false
    foreach ($path in $possiblePaths) {
        if (Test-Path $path) {
            Write-Host "✅ Flutter найден: $path" -ForegroundColor Green
            $flutterDir = Split-Path (Split-Path $path)
            $env:Path += ";$flutterDir\bin"
            $flutterFound = $true
            break
        }
    }
    
    if (-not $flutterFound) {
        Write-Host "❌ Flutter не найден" -ForegroundColor Red
        Write-Host "Установите Flutter SDK или добавьте его в PATH" -ForegroundColor Yellow
        exit 1
    }
}

Write-Host "✅ Flutter найден" -ForegroundColor Green
flutter --version

Write-Host ""
Write-Host "📦 Установка зависимостей..." -ForegroundColor Yellow
flutter pub get

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Ошибка при установке зависимостей" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "🌐 Проверка доступности backend..." -ForegroundColor Yellow
$backendUrl = "http://94.131.80.213:3000/api/health"
try {
    $response = Invoke-WebRequest -Uri $backendUrl -TimeoutSec 5 -UseBasicParsing -ErrorAction Stop
    Write-Host "✅ Backend доступен (статус: $($response.StatusCode))" -ForegroundColor Green
} catch {
    Write-Host "⚠️  Backend недоступен: $_" -ForegroundColor Yellow
    Write-Host "   Приложение все равно запустится, но запросы могут не работать" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "🌐 Проверка доступных устройств..." -ForegroundColor Yellow
flutter devices

Write-Host ""
Write-Host "🚀 Запуск приложения в Chrome..." -ForegroundColor Green
Write-Host "Backend URL: http://94.131.80.213:3000" -ForegroundColor Cyan
Write-Host ""
Write-Host "💡 Советы для отладки:" -ForegroundColor Yellow
Write-Host "   1. Откройте DevTools (F12) → вкладка Network для просмотра запросов" -ForegroundColor Gray
Write-Host "   2. Откройте DevTools → вкладка Console для просмотра ошибок" -ForegroundColor Gray
Write-Host "   3. Проверяйте терминал Flutter для логов приложения" -ForegroundColor Gray
Write-Host ""

# Проверяем наличие web папки
if (-not (Test-Path "web\index.html")) {
    Write-Host "⚠️  Web конфигурация не найдена, создаем..." -ForegroundColor Yellow
    flutter create . --platforms=web --no-overwrite 2>&1 | Out-Null
}

Write-Host ""
Write-Host "🌐 Запуск через web-server (более стабильный вариант)..." -ForegroundColor Green
Write-Host "   После запуска откройте браузер и перейдите по указанному адресу" -ForegroundColor Yellow
Write-Host ""

# Запуск через web-server (более надежный вариант)
flutter run -d web-server --web-port=8080 --web-hostname=localhost

