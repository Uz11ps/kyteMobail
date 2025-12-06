# PowerShell скрипт для запуска приложения в демо-режиме

Write-Host "🚀 Запуск Kyte Chat в демо-режиме" -ForegroundColor Green
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
        Write-Host ""
        Write-Host "Скачать Flutter: https://flutter.dev/docs/get-started/install" -ForegroundColor Cyan
        Write-Host "Или выполните установку через скрипт" -ForegroundColor Cyan
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
Write-Host "📱 Доступные устройства:" -ForegroundColor Yellow
flutter devices

Write-Host ""
Write-Host "🚀 Запуск приложения..." -ForegroundColor Green
Write-Host "Примечание: Приложение запустится в демо-режиме без backend" -ForegroundColor Cyan
Write-Host ""

# Проверяем доступность Chrome (самый простой вариант для демо)
$chromeDevice = flutter devices | Select-String "Chrome"
if ($chromeDevice) {
    Write-Host "Запуск на Chrome (веб-версия)..." -ForegroundColor Green
    Write-Host "Это самый быстрый способ просмотреть UI приложения" -ForegroundColor Yellow
    flutter run -d chrome
} else {
    Write-Host "Chrome не найден, пытаемся запустить на Windows..." -ForegroundColor Yellow
    flutter run -d windows
}

