#!/bin/bash

# Скрипт для сборки APK файла для Android

echo "🔨 Сборка APK для Android..."
echo ""

# Проверка Flutter
if ! command -v flutter &> /dev/null; then
    echo "❌ Flutter не найден в PATH!"
    echo "Установите Flutter или добавьте его в PATH"
    exit 1
fi

# Переход в корневую директорию проекта
cd "$(dirname "$0")/.."

echo "📦 Обновление зависимостей..."
flutter pub get

if [ $? -ne 0 ]; then
    echo "❌ Ошибка обновления зависимостей"
    exit 1
fi

echo ""
echo "🔍 Проверка конфигурации..."

# Проверка Android SDK
if [ -z "$ANDROID_HOME" ]; then
    echo "⚠️  ANDROID_HOME не установлен"
    echo "Попытка найти Android SDK автоматически..."
fi

echo ""
echo "Выберите тип сборки:"
echo "  1) Debug APK (для тестирования, быстрее)"
echo "  2) Release APK (оптимизированный, для распространения)"
echo ""
read -p "Введите номер (1 или 2): " buildType

if [ "$buildType" = "2" ]; then
    echo ""
    echo "🔐 Release сборка требует keystore файл"
    echo "Используется debug signing для тестирования..."
    buildMode="release"
    apkType="release"
else
    buildMode="debug"
    apkType="debug"
fi

echo ""
echo "🏗️  Сборка $apkType APK..."

# Очистка предыдущих сборок
echo "🧹 Очистка..."
flutter clean

# Сборка APK
echo "📱 Сборка APK..."
flutter build apk --$buildMode

if [ $? -ne 0 ]; then
    echo "❌ Ошибка сборки APK"
    exit 1
fi

# Поиск собранного APK
if [ "$buildMode" = "release" ]; then
    apkPath="build/app/outputs/flutter-apk/app-release.apk"
else
    apkPath="build/app/outputs/flutter-apk/app-debug.apk"
fi

if [ -f "$apkPath" ]; then
    apkSize=$(du -h "$apkPath" | cut -f1)
    echo ""
    echo "✅ APK успешно собран!"
    echo ""
    echo "📦 Файл: $(pwd)/$apkPath"
    echo "📊 Размер: $apkSize"
    echo ""
    echo "📱 Установка на устройство:"
    echo "  1. Включите 'Отладка по USB' на Android устройстве"
    echo "  2. Подключите устройство к компьютеру"
    echo "  3. Выполните: flutter install"
    echo "  ИЛИ скопируйте APK на устройство и установите вручную"
    echo ""
    
    # Предложение открыть папку (macOS/Linux)
    if [[ "$OSTYPE" == "darwin"* ]]; then
        read -p "Открыть папку с APK? (y/n): " openFolder
        if [ "$openFolder" = "y" ] || [ "$openFolder" = "Y" ]; then
            open "$(dirname "$apkPath")"
        fi
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        read -p "Открыть папку с APK? (y/n): " openFolder
        if [ "$openFolder" = "y" ] || [ "$openFolder" = "Y" ]; then
            xdg-open "$(dirname "$apkPath")"
        fi
    fi
else
    echo "❌ APK файл не найден по пути: $apkPath"
    exit 1
fi

