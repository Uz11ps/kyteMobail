# Скрипт для сборки APK файла для Android

Write-Host "🔨 Сборка APK для Android..." -ForegroundColor Cyan
Write-Host ""

# Проверка Flutter
$flutterPath = Get-Command flutter -ErrorAction SilentlyContinue
if (-not $flutterPath) {
    # Попытка найти Flutter в стандартных местах
    $possiblePaths = @(
        "$env:USERPROFILE\flutter\bin\flutter.bat",
        "$env:LOCALAPPDATA\flutter\bin\flutter.bat",
        "C:\flutter\bin\flutter.bat",
        "C:\src\flutter\bin\flutter.bat"
    )
    
    $found = $false
    foreach ($path in $possiblePaths) {
        if (Test-Path $path) {
            $env:Path += ";$(Split-Path $path)"
            Write-Host "✅ Flutter найден: $path" -ForegroundColor Green
            $found = $true
            break
        }
    }
    
    if (-not $found) {
        Write-Host "❌ Flutter не найден в PATH!" -ForegroundColor Red
        Write-Host "Установите Flutter или добавьте его в PATH" -ForegroundColor Yellow
        exit 1
    }
}

# Переход в корневую директорию проекта
$projectRoot = Split-Path -Parent $PSScriptRoot
Set-Location $projectRoot

Write-Host "📦 Обновление зависимостей..." -ForegroundColor Yellow
flutter pub get

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Ошибка обновления зависимостей" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "🔍 Проверка конфигурации..." -ForegroundColor Yellow

# Проверка Android SDK
$androidHome = $env:ANDROID_HOME
if (-not $androidHome) {
    Write-Host "⚠️  ANDROID_HOME не установлен" -ForegroundColor Yellow
    Write-Host "Попытка найти Android SDK автоматически..." -ForegroundColor Gray
}

Write-Host ""
Write-Host "Выберите тип сборки:" -ForegroundColor Cyan
Write-Host "  1) Debug APK (для тестирования, быстрее)" -ForegroundColor Gray
Write-Host "  2) Release APK (оптимизированный, для распространения)" -ForegroundColor Gray
Write-Host ""
$buildType = Read-Host "Введите номер (1 или 2)"

if ($buildType -eq "2") {
    Write-Host ""
    Write-Host "🔐 Release сборка требует keystore файл" -ForegroundColor Yellow
    Write-Host "Используется debug signing для тестирования..." -ForegroundColor Gray
    $buildMode = "release"
    $apkType = "release"
} else {
    $buildMode = "debug"
    $apkType = "debug"
}

Write-Host ""
Write-Host "🏗️  Сборка $apkType APK..." -ForegroundColor Cyan

# Очистка предыдущих сборок
Write-Host "🧹 Очистка..." -ForegroundColor Gray
flutter clean

# Сборка APK
Write-Host "📱 Сборка APK..." -ForegroundColor Yellow
flutter build apk --$buildMode

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Ошибка сборки APK" -ForegroundColor Red
    exit 1
}

# Поиск собранного APK
$apkPath = ""
if ($buildMode -eq "release") {
    $apkPath = "$projectRoot\build\app\outputs\flutter-apk\app-release.apk"
} else {
    $apkPath = "$projectRoot\build\app\outputs\flutter-apk\app-debug.apk"
}

if (Test-Path $apkPath) {
    $apkSize = (Get-Item $apkPath).Length / 1MB
    Write-Host ""
    Write-Host "✅ APK успешно собран!" -ForegroundColor Green
    Write-Host ""
    Write-Host "📦 Файл: $apkPath" -ForegroundColor Cyan
    Write-Host "📊 Размер: $([math]::Round($apkSize, 2)) MB" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "📱 Установка на устройство:" -ForegroundColor Yellow
    Write-Host "  1. Включите 'Отладка по USB' на Android устройстве" -ForegroundColor Gray
    Write-Host "  2. Подключите устройство к компьютеру" -ForegroundColor Gray
    Write-Host "  3. Выполните: flutter install" -ForegroundColor Gray
    Write-Host "  ИЛИ скопируйте APK на устройство и установите вручную" -ForegroundColor Gray
    Write-Host ""
    
    # Предложение открыть папку
    $openFolder = Read-Host "Открыть папку с APK? (y/n)"
    if ($openFolder -eq "y" -or $openFolder -eq "Y") {
        Start-Process explorer.exe -ArgumentList "/select,`"$apkPath`""
    }
} else {
    Write-Host "❌ APK файл не найден по пути: $apkPath" -ForegroundColor Red
    exit 1
}









