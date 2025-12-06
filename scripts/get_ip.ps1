# Скрипт для получения IP адреса компьютера

Write-Host "🔍 Поиск IP адреса..." -ForegroundColor Yellow
Write-Host ""

# Получаем IP адреса всех сетевых адаптеров
$adapters = Get-NetIPAddress -AddressFamily IPv4 | Where-Object {
    $_.IPAddress -notlike "127.*" -and 
    $_.IPAddress -notlike "169.254.*"
} | Sort-Object InterfaceIndex

if ($adapters.Count -eq 0) {
    Write-Host "❌ IP адрес не найден" -ForegroundColor Red
    exit 1
}

Write-Host "📡 Найденные IP адреса:" -ForegroundColor Green
Write-Host ""

foreach ($adapter in $adapters) {
    $interface = Get-NetAdapter -InterfaceIndex $adapter.InterfaceIndex
    Write-Host "  $($adapter.IPAddress)" -ForegroundColor Cyan
    Write-Host "    Адаптер: $($interface.Name)" -ForegroundColor Gray
    Write-Host "    Статус: $($interface.Status)" -ForegroundColor Gray
    Write-Host ""
}

# Предполагаем что первый активный адаптер - это основной
$mainIP = $adapters[0].IPAddress

Write-Host "✅ Основной IP адрес: $mainIP" -ForegroundColor Green
Write-Host ""
Write-Host "📝 Обновите lib/core/config/app_config.dart:" -ForegroundColor Yellow
Write-Host ""
Write-Host "  static const String apiBaseUrl = 'http://$mainIP:3000';" -ForegroundColor Cyan
Write-Host "  static const String wsBaseUrl = 'ws://$mainIP:3000';" -ForegroundColor Cyan
Write-Host ""
Write-Host "📝 И обновите backend/.env:" -ForegroundColor Yellow
Write-Host ""
Write-Host "  CORS_ORIGIN=http://localhost:3000,http://localhost:8080,http://$mainIP:3000" -ForegroundColor Cyan
Write-Host ""

