#!/bin/bash

# Скрипт для проверки конфигурации проекта

echo "🔍 Проверка конфигурации Kyte Chat"
echo ""

ERRORS=0

# Проверка Firebase файлов
if [ ! -f "android/app/google-services.json" ]; then
    echo "❌ android/app/google-services.json не найден"
    ERRORS=$((ERRORS + 1))
else
    echo "✅ android/app/google-services.json найден"
fi

if [ ! -f "ios/Runner/GoogleService-Info.plist" ]; then
    echo "❌ ios/Runner/GoogleService-Info.plist не найден"
    ERRORS=$((ERRORS + 1))
else
    echo "✅ ios/Runner/GoogleService-Info.plist найден"
fi

# Проверка переменных окружения
if [ -z "$API_BASE_URL" ] && [ -z "$WS_BASE_URL" ]; then
    echo "⚠️  Переменные окружения API_BASE_URL и WS_BASE_URL не установлены"
    echo "   Используйте --dart-define при запуске или обновите app_config.dart"
else
    echo "✅ Переменные окружения установлены"
fi

# Проверка Flutter
if command -v flutter &> /dev/null; then
    echo "✅ Flutter установлен"
    flutter --version | head -n 1
else
    echo "❌ Flutter не установлен"
    ERRORS=$((ERRORS + 1))
fi

# Проверка зависимостей
if [ -f "pubspec.yaml" ]; then
    echo "✅ pubspec.yaml найден"
    if flutter pub get &> /dev/null; then
        echo "✅ Зависимости установлены"
    else
        echo "⚠️  Проблемы с зависимостями"
    fi
else
    echo "❌ pubspec.yaml не найден"
    ERRORS=$((ERRORS + 1))
fi

echo ""
if [ $ERRORS -eq 0 ]; then
    echo "✅ Конфигурация в порядке!"
else
    echo "❌ Найдено ошибок: $ERRORS"
    echo "   См. firebase_setup_instructions.md и backend_api_setup.md"
fi

exit $ERRORS

