# Сборка APK для Android

Инструкция по сборке APK файла для тестирования приложения на Android устройстве.

## Быстрая сборка

### Windows (PowerShell)
```powershell
.\scripts\build_apk.ps1
```

### macOS/Linux
```bash
chmod +x scripts/build_apk.sh
./scripts/build_apk.sh
```

### Или через Flutter напрямую

**Debug APK (для тестирования):**
```bash
flutter build apk --debug
```

**Release APK (оптимизированный):**
```bash
flutter build apk --release
```

## Расположение APK файлов

После сборки APK файлы находятся в:
- **Debug**: `build/app/outputs/flutter-apk/app-debug.apk`
- **Release**: `build/app/outputs/flutter-apk/app-release.apk`

## Установка на устройство

### Способ 1: Через USB (ADB)

1. Включите **"Отладка по USB"** на Android устройстве:
   - Настройки → О телефоне → Нажмите 7 раз на "Номер сборки"
   - Настройки → Для разработчиков → Включите "Отладка по USB"

2. Подключите устройство к компьютеру

3. Установите APK:
```bash
flutter install
```

Или напрямую через ADB:
```bash
adb install build/app/outputs/flutter-apk/app-debug.apk
```

### Способ 2: Вручную

1. Скопируйте APK файл на Android устройство (через USB, email, облако и т.д.)

2. На устройстве откройте файловый менеджер

3. Найдите APK файл и нажмите на него

4. Разрешите установку из неизвестных источников (если требуется)

5. Нажмите "Установить"

## Требования

- Flutter SDK установлен и добавлен в PATH
- Android SDK установлен (через Android Studio или отдельно)
- Для release сборки: настроен keystore (опционально для тестирования)

## Проверка подключенных устройств

```bash
flutter devices
```

или

```bash
adb devices
```

## Отладка

Для просмотра логов во время работы приложения:

```bash
flutter logs
```

## Размер APK

- **Debug APK**: ~50-100 MB (включает отладочную информацию)
- **Release APK**: ~20-40 MB (оптимизированный)

## Troubleshooting

### Ошибка: "ANDROID_HOME не установлен"
Установите Android SDK и добавьте в переменные окружения:
```bash
export ANDROID_HOME=/path/to/android/sdk
export PATH=$PATH:$ANDROID_HOME/tools:$ANDROID_HOME/platform-tools
```

### Ошибка: "Gradle build failed"
Проверьте версию Java (нужна Java 11+):
```bash
java -version
```

### Ошибка: "SDK location not found"
Создайте файл `android/local.properties`:
```properties
sdk.dir=C:\\Users\\YourUsername\\AppData\\Local\\Android\\Sdk
```

## Следующие шаги

После успешной установки APK:
1. Откройте приложение на устройстве
2. Проверьте подключение к backend API
3. Протестируйте основные функции
4. Проверьте работу WebSocket соединения

