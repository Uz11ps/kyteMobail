# Инструкция по настройке проекта

## Быстрый старт

1. **Клонируйте репозиторий и установите зависимости:**
```bash
flutter pub get
```

2. **Настройте переменные окружения:**
Создайте файл `.env` или используйте аргументы при запуске:
```bash
flutter run --dart-define=API_BASE_URL=https://your-api.com \
           --dart-define=WS_BASE_URL=wss://your-api.com \
           --dart-define=GOOGLE_CLIENT_ID=your-client-id
```

3. **Настройте Firebase:**
   - Создайте проект в Firebase Console
   - Добавьте Android и iOS приложения
   - Скачайте конфигурационные файлы:
     - `google-services.json` → `android/app/`
     - `GoogleService-Info.plist` → `ios/Runner/`

4. **Настройте Google Sign-In:**
   - Получите OAuth Client ID в Google Cloud Console
   - Добавьте SHA-1 отпечаток для Android
   - Настройте Bundle ID для iOS

## Структура проекта

```
lib/
├── core/                    # Основные утилиты
│   ├── config/             # Конфигурация приложения
│   ├── constants/          # Константы (API endpoints)
│   ├── di/                 # Dependency Injection
│   ├── network/            # Сетевой слой (API, WebSocket)
│   ├── routing/            # Маршрутизация
│   ├── services/           # Сервисы (Push notifications)
│   ├── theme/              # Тема приложения
│   └── utils/              # Утилиты
├── data/                    # Слой данных
│   ├── models/             # Модели данных
│   └── repositories/       # Реализации репозиториев
├── domain/                  # Бизнес-логика
│   └── repositories/       # Интерфейсы репозиториев
└── presentation/           # UI слой
    ├── bloc/               # BLoC для управления состоянием
    ├── screens/            # Экраны приложения
    └── widgets/            # Переиспользуемые виджеты
```

## Основные функции

### Аутентификация
- Вход по email/паролю
- Вход по телефону/коду
- Регистрация
- Google OAuth

### Чаты
- Список чатов
- Отправка/получение сообщений в реальном времени
- WebSocket подключение
- Групповые чаты
- Присоединение по коду приглашения

### AI интеграция
- Кнопка "Спросить AI" в чате
- Отображение AI ответов
- Автоматические рекомендации от AI

### Google Meet
- Создание встреч по рекомендации AI
- Интеграция с Google OAuth токеном

### Push-уведомления
- Firebase Cloud Messaging
- Локальные уведомления
- Обработка уведомлений в foreground/background

## API Endpoints

Все эндпоинты определены в `lib/core/constants/api_endpoints.dart`:

- `POST /auth/login` - Вход
- `POST /auth/register` - Регистрация
- `POST /auth/refresh` - Обновление токена
- `GET /chats` - Список чатов
- `GET /chats/{chatId}/messages` - Сообщения чата
- `POST /chats/{chatId}/messages` - Отправка сообщения
- `POST /groups` - Создание группы
- `POST /groups/join` - Присоединение к группе
- `POST /auth/gmail/token` - Отправка Gmail токена
- `POST /ai/ask` - Запрос к AI
- `GET /ai/suggestions` - Получение предложений AI

## WebSocket

WebSocket подключение устанавливается автоматически при открытии чата:
```
wss://your-api.com/ws/chat/{chatId}?token={accessToken}
```

## Тестирование

```bash
# Запуск тестов
flutter test

# Запуск с покрытием
flutter test --coverage
```

## Сборка

```bash
# Android APK
flutter build apk --release

# Android App Bundle
flutter build appbundle --release

# iOS
flutter build ios --release
```

## Требования

- Flutter SDK >= 3.0.0
- Dart >= 3.0.0
- Android SDK >= 21 (Android 5.0)
- iOS >= 14.0

## Дополнительная информация

См. `DEPLOYMENT.md` для инструкций по публикации в магазины приложений.

