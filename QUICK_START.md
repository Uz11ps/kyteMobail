# Быстрый старт

## 1. Настройка Firebase (5 минут)

### Android:
1. Создайте проект в [Firebase Console](https://console.firebase.google.com/)
2. Добавьте Android приложение с package name: `com.kyte.mobile`
3. Скачайте `google-services.json`
4. Поместите файл в `android/app/google-services.json`

### iOS:
1. В том же проекте Firebase добавьте iOS приложение
2. Bundle ID: `com.kyte.mobile`
3. Скачайте `GoogleService-Info.plist`
4. Откройте проект в Xcode: `open ios/Runner.xcworkspace`
5. Перетащите файл в папку `Runner`

### Получение SHA-1 для Android:
```bash
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
```
Скопируйте SHA-1 и добавьте в Firebase Console.

## 2. Настройка Backend API

### Вариант A: Использование существующего API

Обновите `lib/core/config/app_config.dart`:
```dart
static const String apiBaseUrl = 'https://your-api.com';
static const String wsBaseUrl = 'wss://your-api.com';
```

### Вариант B: Использование переменных окружения

Создайте файл `.env` (см. `.env.example`):
```bash
API_BASE_URL=https://your-api.com
WS_BASE_URL=wss://your-api.com
GOOGLE_CLIENT_ID=your-client-id
```

Запуск с переменными:
```bash
flutter run --dart-define=API_BASE_URL=https://your-api.com \
           --dart-define=WS_BASE_URL=wss://your-api.com \
           --dart-define=GOOGLE_CLIENT_ID=your-client-id
```

## 3. Установка зависимостей

```bash
flutter pub get
cd ios && pod install && cd ..
```

## 4. Запуск приложения

```bash
flutter run
```

## Проверка конфигурации

Запустите скрипт проверки:
```bash
chmod +x scripts/check_config.sh
./scripts/check_config.sh
```

## Дополнительная информация

- **Firebase**: См. `firebase_setup_instructions.md`
- **Backend API**: См. `backend_api_setup.md`
- **Развертывание**: См. `DEPLOYMENT.md`

## Troubleshooting

### Firebase не инициализируется
- Убедитесь, что файлы `google-services.json` и `GoogleService-Info.plist` на месте
- Проверьте package name / bundle ID совпадают с Firebase

### WebSocket не подключается
- Проверьте URL в `app_config.dart`
- Убедитесь, что backend поддерживает WebSocket
- Проверьте токен авторизации

### Push-уведомления не работают
- Проверьте настройки Firebase Cloud Messaging
- Для iOS: настройте APNs сертификаты
- Проверьте разрешения на уведомления в настройках устройства

