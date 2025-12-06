# Инструкция по развертыванию и публикации

## Предварительные требования

1. Flutter SDK 3.0 или выше
2. Android Studio / Xcode
3. Firebase проект для push-уведомлений
4. Google OAuth credentials
5. Backend API с поддержкой WebSocket

## Настройка окружения

### 1. Установка зависимостей

```bash
flutter pub get
```

### 2. Настройка переменных окружения

Создайте файл `.env` в корне проекта или используйте аргументы сборки:

```bash
flutter run --dart-define=API_BASE_URL=https://your-backend-api.com \
           --dart-define=WS_BASE_URL=wss://your-backend-api.com \
           --dart-define=GOOGLE_CLIENT_ID=your-google-client-id
```

### 3. Настройка Firebase

1. Создайте проект в Firebase Console
2. Добавьте Android и iOS приложения
3. Скачайте `google-services.json` для Android и `GoogleService-Info.plist` для iOS
4. Разместите файлы в соответствующих директориях:
   - `android/app/google-services.json`
   - `ios/Runner/GoogleService-Info.plist`

### 4. Настройка Google Sign-In

#### Android

1. Добавьте SHA-1 отпечаток в Firebase Console
2. Получите SHA-1: `keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android`
3. Добавьте OAuth Client ID в Firebase Console

#### iOS

1. Добавьте Bundle ID в Firebase Console
2. Скачайте обновленный `GoogleService-Info.plist`
3. Настройте URL Schemes в `Info.plist`

### 5. Настройка Push-уведомлений

#### Android

1. Убедитесь, что `google-services.json` добавлен
2. Минимальная версия SDK: 21 (Android 5.0)

#### iOS

1. Включите Push Notifications в Capabilities
2. Настройте сертификаты в Apple Developer Portal
3. Добавьте разрешения в `Info.plist`

## Сборка приложения

### Android

```bash
flutter build apk --release
# или для App Bundle
flutter build appbundle --release
```

### iOS

```bash
flutter build ios --release
```

Затем откройте Xcode и выполните архив для публикации в App Store.

## Публикация

### Google Play Store

1. Создайте аккаунт разработчика
2. Создайте приложение в Google Play Console
3. Загрузите APK или App Bundle
4. Заполните информацию о приложении
5. Отправьте на проверку

### Apple App Store

1. Создайте аккаунт разработчика Apple
2. Создайте приложение в App Store Connect
3. Загрузите сборку через Xcode или Transporter
4. Заполните информацию о приложении
5. Отправьте на проверку

## Проверка перед публикацией

- [ ] Все зависимости установлены
- [ ] Firebase настроен и протестирован
- [ ] Google Sign-In работает
- [ ] Push-уведомления работают
- [ ] WebSocket подключение стабильно
- [ ] AI интеграция работает
- [ ] Google Meet создание работает
- [ ] Приложение протестировано на реальных устройствах
- [ ] Версия и номер сборки обновлены

## Поддержка

При возникновении проблем проверьте:
1. Логи приложения: `flutter logs`
2. Firebase Console для push-уведомлений
3. Backend логи для API запросов
4. Консоль разработчика Google/Apple для OAuth

