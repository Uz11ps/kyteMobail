# Kyte Mobile - Кроссплатформенное чат-приложение

Мобильное приложение для iOS и Android с интеграцией OpenAI и Google Meet.

## Технологии

- Flutter 3.0+
- BLoC для управления состоянием
- WebSocket для сообщений в реальном времени
- Firebase для push-уведомлений
- Google Sign-In для OAuth

## Быстрый старт

См. [QUICK_START.md](QUICK_START.md) для быстрой настройки проекта.

## Структура проекта

```
lib/
├── core/           # Основные утилиты и конфигурация
├── data/           # Модели данных и репозитории
├── domain/         # Бизнес-логика
├── presentation/   # UI и BLoC
└── main.dart       # Точка входа
```

## Установка

1. Установите Flutter SDK 3.0+
2. Выполните `flutter pub get`
3. Настройте Firebase (см. `firebase_setup_instructions.md`)
4. Настройте Backend API (см. `backend_api_setup.md`)

## Документация

- [QUICK_START.md](QUICK_START.md) - Быстрый старт
- [SETUP.md](SETUP.md) - Подробная настройка
- [firebase_setup_instructions.md](firebase_setup_instructions.md) - Настройка Firebase
- [backend_api_setup.md](backend_api_setup.md) - Настройка Backend API
- [DEPLOYMENT.md](DEPLOYMENT.md) - Публикация в магазины

## Основные функции

✅ Аутентификация (Email/Телефон)  
✅ Google OAuth  
✅ Чаты в реальном времени (WebSocket)  
✅ Групповые чаты  
✅ AI интеграция (OpenAI)  
✅ Google Meet создание  
✅ Push-уведомления  

## Требования

- Flutter SDK >= 3.0.0
- Dart >= 3.0.0
- Android SDK >= 21 (Android 5.0)
- iOS >= 14.0
- Backend API с поддержкой WebSocket
- Firebase проект

