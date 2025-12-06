# Установка Flutter SDK

## Автоматическая установка завершена!

Flutter SDK был скачан и распакован в:
```
%USERPROFILE%\flutter
```

## Настройка PATH

Flutter был добавлен в PATH пользователя. Для применения изменений:

### Вариант 1: Перезапустить терминал
Закройте и откройте новый PowerShell/терминал.

### Вариант 2: Обновить PATH в текущей сессии
Выполните в текущем терминале:
```powershell
$env:Path += ";$env:USERPROFILE\flutter\bin"
```

## Проверка установки

После перезапуска терминала выполните:
```powershell
flutter --version
flutter doctor
```

## Первый запуск

1. **Принять лицензии:**
```powershell
flutter doctor --android-licenses
```

2. **Проверить установку:**
```powershell
flutter doctor
```

3. **Запустить приложение:**
```powershell
cd C:\Users\1\Documents\GitHub\kyteMobail
flutter pub get
flutter run
```

## Ручная установка (если автоматическая не сработала)

1. Скачайте Flutter SDK:
   - https://docs.flutter.dev/get-started/install/windows

2. Распакуйте архив в `C:\Users\<ваше_имя>\flutter`

3. Добавьте в PATH:
   - Откройте "Переменные среды" в Windows
   - Добавьте `C:\Users\<ваше_имя>\flutter\bin` в переменную Path

## Troubleshooting

### Flutter не найден после установки
- Перезапустите терминал
- Проверьте PATH: `echo $env:Path`
- Убедитесь что путь `flutter\bin` присутствует

### Ошибки при flutter doctor
- Установите Android Studio для Android разработки
- Установите Xcode для iOS разработки (только на Mac)
- Установите Visual Studio для Windows разработки

### Проблемы с зависимостями
```powershell
flutter clean
flutter pub get
```

## Дополнительные инструменты

Рекомендуется установить:
- **Android Studio** - для Android разработки
- **VS Code** с расширением Flutter - для удобной разработки
- **Git** - для управления версиями

## Следующие шаги

После установки Flutter:
1. Выполните `flutter doctor` для проверки
2. Установите недостающие компоненты
3. Запустите проект: `flutter run`

