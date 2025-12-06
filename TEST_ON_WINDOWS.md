# Тестирование приложения на Windows

## ⚠️ Важно: iPhone требует Mac

К сожалению, **нельзя запустить Flutter приложение на iPhone с Windows** - для этого нужен Mac с Xcode.

## ✅ Альтернативы для тестирования на Windows:

### Вариант 1: Android эмулятор (Рекомендуется)

Android эмулятор работает на Windows и позволяет протестировать приложение.

#### Шаг 1: Установите Android Studio

1. Скачайте: https://developer.android.com/studio
2. Установите Android Studio
3. В Android Studio: **Tools → SDK Manager → SDK Tools**
4. Установите:
   - Android SDK Platform-Tools
   - Android Emulator
   - Android SDK Build-Tools

#### Шаг 2: Создайте эмулятор

1. В Android Studio: **Tools → Device Manager**
2. Нажмите **Create Device**
3. Выберите устройство (например, Pixel 5)
4. Выберите систему (например, Android 13)
5. Нажмите **Finish**

#### Шаг 3: Запустите эмулятор

```bash
# Через Android Studio или командой:
flutter emulators
flutter emulators --launch <emulator-id>
```

#### Шаг 4: Обновите конфигурацию

В `lib/core/config/app_config.dart`:
```dart
static const String apiBaseUrl = 'http://10.0.2.2:3000';  // Специальный адрес для Android эмулятора
static const String wsBaseUrl = 'ws://10.0.2.2:3000';
```

#### Шаг 5: Запустите приложение

```bash
flutter devices  # Должен показать эмулятор
flutter run
```

---

### Вариант 2: Реальное Android устройство

Если у вас есть Android телефон:

1. **Включите режим разработчика:**
   - Настройки → О телефоне → Нажмите 7 раз на "Номер сборки"

2. **Включите USB отладку:**
   - Настройки → Для разработчиков → USB отладка

3. **Подключите к Windows:**
   - Подключите через USB
   - Разрешите отладку на телефоне

4. **Обновите конфигурацию:**
   ```dart
   static const String apiBaseUrl = 'http://192.168.1.81:3000';  // IP вашего компьютера
   static const String wsBaseUrl = 'ws://192.168.1.81:3000';
   ```

5. **Запустите:**
   ```bash
   flutter devices  # Должен показать ваш телефон
   flutter run
   ```

---

### Вариант 3: Веб-версия (Chrome) - Самый простой

Веб-версия работает сразу без дополнительной настройки:

```bash
flutter run -d chrome
```

Приложение откроется в браузере Chrome.

---

### Вариант 4: Облачная сборка для iPhone

Если нужно именно на iPhone, используйте облачные сервисы:

#### Codemagic (Бесплатный план)

1. Зарегистрируйтесь: https://codemagic.io
2. Подключите GitHub репозиторий
3. Настройте сборку iOS
4. Соберите и скачайте .ipa файл
5. Установите через TestFlight или прямо на iPhone

#### GitHub Actions

1. Создайте workflow для сборки iOS
2. Используйте Mac runner
3. Соберите и загрузите артефакт

---

## Рекомендация: Начните с Android эмулятора

Android эмулятор - лучший вариант для тестирования на Windows:
- ✅ Работает на Windows
- ✅ Полная функциональность
- ✅ Быстрый запуск
- ✅ Не требует реального устройства

---

## Быстрый старт (Android эмулятор)

```bash
# 1. Установите Android Studio и создайте эмулятор

# 2. Запустите эмулятор
flutter emulators --launch <emulator-id>

# 3. Обновите app_config.dart для Android эмулятора
# (используйте 10.0.2.2 вместо localhost)

# 4. Запустите приложение
flutter run
```

---

## Проверка подключения

После запуска backend и приложения:

1. **В эмуляторе/устройстве:** Откройте браузер
2. **Перейдите:** `http://10.0.2.2:3000/api/health` (для эмулятора)
   или `http://192.168.1.81:3000/api/health` (для реального устройства)
3. **Должен вернуться:** `{"status":"ok",...}`

Если не работает - проверьте что backend запущен и порт открыт.

