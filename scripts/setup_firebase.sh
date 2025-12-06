#!/bin/bash

# Скрипт для настройки Firebase конфигурационных файлов

echo "🔥 Настройка Firebase для Kyte Chat"
echo ""

# Проверка наличия Flutter
if ! command -v flutter &> /dev/null; then
    echo "❌ Flutter не установлен. Установите Flutter SDK."
    exit 1
fi

# Проверка наличия файлов
ANDROID_CONFIG="android/app/google-services.json"
IOS_CONFIG="ios/Runner/GoogleService-Info.plist"

if [ -f "$ANDROID_CONFIG" ]; then
    echo "✅ Android конфигурация найдена: $ANDROID_CONFIG"
else
    echo "⚠️  Android конфигурация не найдена"
    echo "   Скачайте google-services.json из Firebase Console"
    echo "   и поместите в: $ANDROID_CONFIG"
    echo ""
fi

if [ -f "$IOS_CONFIG" ]; then
    echo "✅ iOS конфигурация найдена: $IOS_CONFIG"
else
    echo "⚠️  iOS конфигурация не найдена"
    echo "   Скачайте GoogleService-Info.plist из Firebase Console"
    echo "   и поместите в: $IOS_CONFIG"
    echo ""
fi

# Проверка SHA-1 для Android
echo "📱 Для получения SHA-1 отпечатка выполните:"
echo "   keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android"
echo ""

# Установка зависимостей
echo "📦 Установка зависимостей..."
flutter pub get

# iOS Pods
if [ -d "ios" ]; then
    echo "📦 Установка iOS зависимостей..."
    cd ios
    pod install
    cd ..
fi

echo ""
echo "✅ Настройка завершена!"
echo ""
echo "📚 Дополнительная информация:"
echo "   - Инструкции: firebase_setup_instructions.md"
echo "   - Backend API: backend_api_setup.md"

