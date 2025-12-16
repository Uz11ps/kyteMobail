# Скрипт для проверки подключения Android устройства

Write-Host "🔍 Проверка подключения Android устройства..." -ForegroundColor Cyan
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

Write-Host "📱 Проверка устройств через Flutter..." -ForegroundColor Yellow
flutter devices

Write-Host ""
Write-Host "💡 Если устройство не найдено:" -ForegroundColor Cyan
Write-Host ""
Write-Host "1. На Android устройстве:" -ForegroundColor Yellow
Write-Host "   • Откройте Настройки → О телефоне" -ForegroundColor Gray
Write-Host "   • Нажмите 7 раз на 'Номер сборки'" -ForegroundColor Gray
Write-Host "   • Вернитесь в Настройки → Для разработчиков" -ForegroundColor Gray
Write-Host "   • Включите 'Отладка по USB'" -ForegroundColor Gray
Write-Host ""
Write-Host "2. На компьютере:" -ForegroundColor Yellow
Write-Host "   • Убедитесь, что USB кабель поддерживает передачу данных" -ForegroundColor Gray
Write-Host "   • На устройстве появится запрос 'Разрешить отладку по USB?' - нажмите 'Разрешить'" -ForegroundColor Gray
Write-Host "   • Поставьте галочку 'Всегда разрешать с этого компьютера'" -ForegroundColor Gray
Write-Host ""
Write-Host "3. Проверьте драйверы:" -ForegroundColor Yellow
Write-Host "   • Установите USB драйверы для вашего устройства (Samsung, Xiaomi и т.д.)" -ForegroundColor Gray
Write-Host "   • Или используйте универсальный ADB драйвер" -ForegroundColor Gray
Write-Host ""
Write-Host "4. Альтернатива - установка через APK файл:" -ForegroundColor Yellow
Write-Host "   • Скопируйте APK файл на телефон" -ForegroundColor Gray
Write-Host "   • Откройте файловый менеджер на телефоне" -ForegroundColor Gray
Write-Host "   • Найдите APK и установите его" -ForegroundColor Gray

