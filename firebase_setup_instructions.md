# Инструкция по настройке Firebase

## Шаг 1: Создание проекта Firebase

1. Перейдите на https://console.firebase.google.com/
2. Нажмите "Добавить проект"
3. Введите название проекта (например, "Kyte Chat")
4. Отключите Google Analytics (или включите по желанию)
5. Нажмите "Создать проект"

## Шаг 2: Добавление Android приложения

1. В Firebase Console выберите ваш проект
2. Нажмите на иконку Android
3. Введите:
   - **Package name**: `com.kyte.mobile` (должен совпадать с `applicationId` в `android/app/build.gradle`)
   - **App nickname**: Kyte Chat Android (опционально)
   - **Debug signing certificate SHA-1**: (см. ниже как получить)
4. Нажмите "Зарегистрировать приложение"
5. Скачайте файл `google-services.json`
6. Поместите его в `android/app/google-services.json`

### Получение SHA-1 отпечатка для Android:

```bash
# Для debug keystore
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android

# Для release keystore (если есть)
keytool -list -v -keystore your-release-key.keystore -alias your-key-alias
```

Скопируйте SHA-1 отпечаток и вставьте в Firebase Console.

## Шаг 3: Добавление iOS приложения

1. В Firebase Console нажмите на иконку iOS
2. Введите:
   - **Bundle ID**: `com.kyte.mobile` (должен совпадать с Bundle Identifier в Xcode)
   - **App nickname**: Kyte Chat iOS (опционально)
   - **App Store ID**: (оставьте пустым для тестирования)
3. Нажмите "Зарегистрировать приложение"
4. Скачайте файл `GoogleService-Info.plist`
5. Откройте проект в Xcode: `open ios/Runner.xcworkspace`
6. Перетащите `GoogleService-Info.plist` в папку `Runner` в Xcode
7. Убедитесь, что файл добавлен в target "Runner"

## Шаг 4: Настройка Cloud Messaging

1. В Firebase Console перейдите в "Cloud Messaging"
2. Включите Cloud Messaging API (если еще не включено)
3. Для Android: нажмите "Обновить файл конфигурации Firebase" и скачайте обновленный `google-services.json`
4. Для iOS: убедитесь, что APNs сертификаты настроены (см. ниже)

### Настройка APNs для iOS:

1. В Apple Developer Portal создайте APNs сертификат
2. В Firebase Console перейдите в Project Settings > Cloud Messaging
3. Загрузите APNs сертификат или ключ

## Шаг 5: Установка Firebase плагинов

Плагины уже добавлены в `pubspec.yaml`. Выполните:

```bash
flutter pub get
```

## Шаг 6: Настройка Android

1. Убедитесь, что `google-services.json` находится в `android/app/`
2. Проверьте, что в `android/build.gradle` добавлен класс:

```gradle
buildscript {
    dependencies {
        classpath 'com.google.gms:google-services:4.4.0'
    }
}
```

3. В `android/app/build.gradle` в конце файла добавьте:

```gradle
apply plugin: 'com.google.gms.google-services'
```

## Шаг 7: Настройка iOS

1. Убедитесь, что `GoogleService-Info.plist` добавлен в проект Xcode
2. В Xcode включите Push Notifications в Capabilities
3. Установите CocoaPods зависимости:

```bash
cd ios
pod install
cd ..
```

## Шаг 8: Тестирование

После настройки проверьте подключение:

```bash
flutter run
```

Проверьте логи на наличие ошибок Firebase.

## Важно

- **НЕ коммитьте** реальные `google-services.json` и `GoogleService-Info.plist` в публичный репозиторий
- Добавьте их в `.gitignore`
- Используйте разные проекты Firebase для development и production

