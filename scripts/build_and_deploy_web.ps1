# Скрипт для сборки и развертывания Flutter веб-приложения на сервере

Write-Host "🚀 Сборка и развертывание Flutter веб-приложения" -ForegroundColor Green
Write-Host ""

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
Write-Host "Файлы находятся в: build\web\" -ForegroundColor Cyan
Write-Host ""

# Проверка наличия файлов
if (-not (Test-Path "build\web\index.html")) {
    Write-Host "❌ Файлы сборки не найдены" -ForegroundColor Red
    exit 1
}

Write-Host "📋 Следующие шаги:" -ForegroundColor Yellow
Write-Host ""
Write-Host "1. Подключитесь к серверу:" -ForegroundColor Cyan
Write-Host "   ssh kyte-777@94.131.80.213" -ForegroundColor Gray
Write-Host ""
Write-Host "2. Создайте директорию на сервере:" -ForegroundColor Cyan
Write-Host "   sudo mkdir -p /var/www/kyte-mobile/web" -ForegroundColor Gray
Write-Host "   sudo chown -R kyte-777:kyte-777 /var/www/kyte-mobile" -ForegroundColor Gray
Write-Host ""
Write-Host "3. Загрузите файлы (выберите один способ):" -ForegroundColor Cyan
Write-Host ""
Write-Host "   Способ A - через scp:" -ForegroundColor Yellow
Write-Host "   scp -r -i путь\к\ключу build\web\* kyte-777@94.131.80.213:/var/www/kyte-mobile/web/" -ForegroundColor Gray
Write-Host ""
Write-Host "   Способ B - через WinSCP/FileZilla:" -ForegroundColor Yellow
Write-Host "   Загрузите все файлы из build\web\ в /var/www/kyte-mobile/web/" -ForegroundColor Gray
Write-Host ""
Write-Host "4. Настройте Nginx (см. DEPLOY_WEB_APP.md)" -ForegroundColor Cyan
Write-Host ""
Write-Host "5. Откройте в браузере: http://94.131.80.213/mobail/" -ForegroundColor Green



