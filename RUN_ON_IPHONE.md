# Запуск приложения на iPhone

## ⚠️ Важно: Требования

Для запуска Flutter приложения на iPhone **необходим Mac** с установленным Xcode.

## Вариант 1: Запуск на реальном iPhone (Mac требуется)

### Шаг 1: Подготовка Mac

1. **Установите Xcode:**
   ```bash
   # Через App Store или
   xcode-select --install
   ```

2. **Установите CocoaPods:**
   ```bash
   sudo gem install cocoapods
   ```

3. **Настройте Flutter для iOS:**
   ```bash
   flutter doctor
   flutter doctor --android-licenses  # если нужно
   ```

### Шаг 2: Подключение iPhone

1. Подключите iPhone к Mac через USB
2. На iPhone: **Настройки → Основные → Управление устройством** → Доверьтесь компьютеру
3. Разблокируйте iPhone

### Шаг 3: Настройка Backend URL

Для работы с реальным устройством нужно использовать **IP адрес вашего компьютера**, а не `localhost`.

**На Windows (где запущен backend):**

1. Узнайте IP адрес:
   ```powershell
   ipconfig
   ```
   Найдите IPv4 адрес (например: `192.168.1.100`)

2. Обновите `lib/core/config/app_config.dart`:
   ```dart
   static const String apiBaseUrl = 'http://192.168.1.100:3000';
   static const String wsBaseUrl = 'ws://192.168.1.100:3000';
   ```

3. Убедитесь что iPhone и компьютер в **одной Wi-Fi сети**

### Шаг 4: Запуск на iPhone

```bash
# На Mac
cd /path/to/kyteMobail
flutter devices  # Должен показать ваш iPhone
flutter run -d <device-id>
```

---

## Вариант 2: iOS Симулятор (Mac требуется)

Если у вас есть Mac, но нет iPhone:

```bash
# На Mac
flutter emulators  # Покажет доступные эмуляторы
flutter emulators --launch apple_ios_simulator
flutter run
```

---

## Вариант 3: Без Mac (Альтернативы)

### 3.1. Использовать Android устройство/эмулятор

Android эмулятор работает на Windows:

```bash
flutter devices
flutter run -d <android-device-id>
```

### 3.2. Использовать Codemagic или другие CI/CD

- Codemagic.io - бесплатный план для сборки iOS
- GitHub Actions с Mac runner
- AppCircle, Bitrise и др.

### 3.3. Использовать облачный Mac

- MacStadium
- MacinCloud
- AWS EC2 Mac instances

---

## Вариант 4: Запуск через сеть (если есть доступ к Mac)

Если у вас есть доступ к Mac (даже удаленный):

1. **На Windows (где backend):**
   - Узнайте IP: `ipconfig` → IPv4 адрес
   - Убедитесь что порт 3000 открыт в брандмауэре

2. **На Mac:**
   - Клонируйте проект
   - Обновите `app_config.dart` с IP адресом Windows компьютера
   - Запустите: `flutter run`

---

## Настройка Backend для работы с iPhone

### 1. Узнайте IP адрес компьютера:

**Windows:**
```powershell
ipconfig
# Найдите IPv4 адрес, например: 192.168.1.100
```

**Mac/Linux:**
```bash
ifconfig | grep "inet "
# или
ip addr show
```

### 2. Обновите CORS в backend:

В файле `backend/.env`:
```env
CORS_ORIGIN=http://localhost:3000,http://localhost:8080,http://192.168.1.100:3000
```

### 3. Откройте порт в брандмауэре Windows:

```powershell
# Запустите PowerShell от имени администратора
New-NetFirewallRule -DisplayName "Kyte Backend" -Direction Inbound -LocalPort 3000 -Protocol TCP -Action Allow
```

### 4. Обновите Flutter приложение:

В `lib/core/config/app_config.dart`:
```dart
class AppConfig {
  // Замените на IP адрес вашего компьютера
  static const String apiBaseUrl = 'http://192.168.1.100:3000';
  static const String wsBaseUrl = 'ws://192.168.1.100:3000';
  
  // ... остальное
}
```

---

## Проверка подключения

После настройки проверьте:

1. **Backend доступен с iPhone:**
   - Откройте Safari на iPhone
   - Перейдите на `http://192.168.1.100:3000/api/health`
   - Должен вернуться JSON: `{"status":"ok",...}`

2. **Если не работает:**
   - Убедитесь что iPhone и компьютер в одной Wi-Fi сети
   - Проверьте брандмауэр Windows
   - Проверьте что backend запущен

---

## Быстрый старт (если есть Mac)

```bash
# 1. Клонируйте проект на Mac
git clone <your-repo>
cd kyteMobail

# 2. Установите зависимости
flutter pub get
cd ios
pod install
cd ..

# 3. Обновите app_config.dart с IP адресом backend

# 4. Подключите iPhone и запустите
flutter devices
flutter run
```

---

## Troubleshooting

### Ошибка: "No devices found"
- Убедитесь что iPhone разблокирован
- Проверьте кабель USB
- В Xcode: Window → Devices and Simulators → должно показать iPhone

### Ошибка: "Failed to connect to backend"
- Проверьте IP адрес в `app_config.dart`
- Убедитесь что backend запущен
- Проверьте что iPhone и компьютер в одной сети
- Откройте порт 3000 в брандмауэре

### Ошибка: "Signing for Runner requires a development team"
- Откройте `ios/Runner.xcworkspace` в Xcode
- Выберите Runner → Signing & Capabilities
- Выберите вашу Apple ID в Team
- Или создайте бесплатный Apple Developer аккаунт

