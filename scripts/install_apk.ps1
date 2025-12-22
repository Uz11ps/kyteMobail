# Скрипт для установки APK на подключенное Android устройство

Write-Host "📱 Установка APK на Android устройство..." -ForegroundColor Cyan
Write-Host ""

# Проверка Flutter
$flutterPath = Get-Command flutter -ErrorAction SilentlyContinue
if (-not $flutterPath) {
    $possiblePaths = @(
        "$env:USERPROFILE\flutter\bin\flutter.bat",
        "$env:LOCALAPPDATA\flutter\bin\flutter.bat",
        "C:\flutter\bin\flutter.bat"
    )
    
    foreach ($path in $possiblePaths) {
        if (Test-Path $path) {
            $env:Path += ";$(Split-Path $path)"
            break
        }
    }
}

# Переход в корневую директорию проекта
$projectRoot = Split-Path -Parent $PSScriptRoot
Set-Location $projectRoot

# Проверка наличия APK
$debugApk = "$projectRoot\build\app\outputs\flutter-apk\app-debug.apk"
$releaseApk = "$projectRoot\build\app\outputs\flutter-apk\app-release.apk"

$apkPath = $null
if (Test-Path $debugApk) {
    $apkPath = $debugApk
    Write-Host "✅ Найден Debug APK" -ForegroundColor Green
} elseif (Test-Path $releaseApk) {
    $apkPath = $releaseApk
    Write-Host "✅ Найден Release APK" -ForegroundColor Green
} else {
    Write-Host "❌ APK файл не найден!" -ForegroundColor Red
    Write-Host "Сначала соберите APK: .\scripts\build_apk.ps1" -ForegroundColor Yellow
    exit 1
}

Write-Host ""
Write-Host "🔍 Проверка подключенных устройств..." -ForegroundColor Yellow
flutter devices

Write-Host ""
Write-Host "Выберите способ установки:" -ForegroundColor Cyan
Write-Host "  1) Через Flutter (если устройство обнаружено)" -ForegroundColor Gray
Write-Host "  2) Через ADB напрямую" -ForegroundColor Gray
Write-Host "  3) Открыть папку с APK (для ручной установки)" -ForegroundColor Gray
Write-Host ""
$choice = Read-Host "Введите номер (1, 2 или 3)"

if ($choice -eq "1") {
    Write-Host ""
    Write-Host "📲 Установка через Flutter..." -ForegroundColor Yellow
    flutter install
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host ""
        Write-Host "✅ Установка завершена!" -ForegroundColor Green
    } else {
        Write-Host ""
        Write-Host "❌ Ошибка установки. Попробуйте способ 2 или 3." -ForegroundColor Red
    }
} elseif ($choice -eq "2") {
    Write-Host ""
    Write-Host "📲 Установка через ADB..." -ForegroundColor Yellow
    
    # Попытка найти ADB
    $adbPath = $null
    $possibleAdbPaths = @(
        "$env:ANDROID_HOME\platform-tools\adb.exe",
        "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe",
        "C:\Android\Sdk\platform-tools\adb.exe"
    )
    
    foreach ($path in $possibleAdbPaths) {
        if (Test-Path $path) {
            $adbPath = $path
            break
        }
    }
    
    if ($adbPath) {
        Write-Host "✅ ADB найден: $adbPath" -ForegroundColor Green
        Write-Host ""
        Write-Host "Проверка устройств..." -ForegroundColor Yellow
        & $adbPath devices
        
        Write-Host ""
        Write-Host "Установка APK..." -ForegroundColor Yellow
        & $adbPath install -r $apkPath
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host ""
            Write-Host "✅ APK установлен!" -ForegroundColor Green
        } else {
            Write-Host ""
            Write-Host "❌ Ошибка установки. Проверьте подключение устройства." -ForegroundColor Red
        }
    } else {
        Write-Host "❌ ADB не найден. Используйте способ 3 для ручной установки." -ForegroundColor Red
    }
} elseif ($choice -eq "3") {
    Write-Host ""
    Write-Host "📂 Открытие папки с APK..." -ForegroundColor Yellow
    $apkDir = Split-Path $apkPath
    Start-Process explorer.exe -ArgumentList "/select,`"$apkPath`""
    Write-Host ""
    Write-Host "📋 Инструкция:" -ForegroundColor Cyan
    Write-Host "  1. Скопируйте APK файл на телефон (через USB, облако или email)" -ForegroundColor Gray
    Write-Host "  2. На телефоне откройте файловый менеджер" -ForegroundColor Gray
    Write-Host "  3. Найдите APK файл и нажмите на него" -ForegroundColor Gray
    Write-Host "  4. Разрешите установку из неизвестных источников (если требуется)" -ForegroundColor Gray
    Write-Host "  5. Нажмите 'Установить'" -ForegroundColor Gray
} else {
    Write-Host "❌ Неверный выбор" -ForegroundColor Red
}



