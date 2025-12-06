# 🚀 Быстрый запуск на iPhone

## ⚠️ Требование: Mac с Xcode

Для запуска на iPhone нужен Mac. Если Mac нет, используйте Android устройство или эмулятор.

## Шаги:

### 1. Получите IP адрес компьютера (где запущен backend)

**Windows:**
```powershell
.\scripts\get_ip.ps1
```

Или вручную:
```powershell
ipconfig
# Найдите IPv4 адрес (например: 192.168.1.100)
```

### 2. Обновите конфигурацию

**В `lib/core/config/app_config.dart`:**
```dart
static const String apiBaseUrl = 'http://192.168.1.100:3000';  // Замените на ваш IP
static const String wsBaseUrl = 'ws://192.168.1.100:3000';     // Замените на ваш IP
```

**В `backend/.env`:**
```env
CORS_ORIGIN=http://localhost:3000,http://localhost:8080,http://192.168.1.100:3000
```

### 3. Откройте порт в брандмауэре Windows

```powershell
# Запустите от имени администратора
New-NetFirewallRule -DisplayName "Kyte Backend" -Direction Inbound -LocalPort 3000 -Protocol TCP -Action Allow
```

### 4. На Mac:

```bash
# Клонируйте проект
git clone <your-repo>
cd kyteMobail

# Установите зависимости
flutter pub get
cd ios
pod install
cd ..

# Подключите iPhone через USB
# Разблокируйте iPhone
# Доверьтесь компьютеру на iPhone

# Запустите
flutter devices  # Должен показать iPhone
flutter run
```

### 5. Проверка

На iPhone откройте Safari и перейдите:
```
http://192.168.1.100:3000/api/health
```

Должен вернуться: `{"status":"ok",...}`

---

## Если Mac нет:

### Вариант A: Android устройство/эмулятор

```bash
flutter devices
flutter run -d <android-device-id>
```

### Вариант B: Веб-версия (Chrome)

```bash
flutter run -d chrome
```

### Вариант C: Облачная сборка iOS

- Codemagic.io (бесплатный план)
- GitHub Actions
- AppCircle

