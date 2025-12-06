# Чеклист настройки проекта

Используйте этот чеклист для проверки готовности проекта к запуску.

## Firebase настройка

- [ ] Создан проект в Firebase Console
- [ ] Добавлено Android приложение с package name `com.kyte.mobile`
- [ ] Скачан и размещен `google-services.json` в `android/app/`
- [ ] Добавлен SHA-1 отпечаток в Firebase Console (Android)
- [ ] Добавлено iOS приложение с bundle ID `com.kyte.mobile`
- [ ] Скачан и размещен `GoogleService-Info.plist` в `ios/Runner/`
- [ ] Настроены APNs сертификаты для iOS (для push-уведомлений)
- [ ] Включен Cloud Messaging API в Firebase Console

## Backend API настройка

- [ ] Backend API развернут и доступен
- [ ] Настроены все REST API endpoints (см. `backend_api_setup.md`)
- [ ] Настроен WebSocket сервер
- [ ] Обновлены URL в `lib/core/config/app_config.dart` или используются переменные окружения
- [ ] API поддерживает JWT аутентификацию
- [ ] API поддерживает CORS (для WebSocket)

## Google OAuth

- [ ] Создан OAuth Client ID в Google Cloud Console
- [ ] Добавлен Client ID в Firebase Console
- [ ] Обновлен `GOOGLE_CLIENT_ID` в конфигурации

## Зависимости

- [ ] Выполнено `flutter pub get`
- [ ] Выполнено `cd ios && pod install && cd ..` (для iOS)
- [ ] Все зависимости установлены без ошибок

## Тестирование

- [ ] Приложение запускается без ошибок
- [ ] Firebase инициализируется успешно
- [ ] Можно зарегистрироваться/войти
- [ ] WebSocket подключается к backend
- [ ] Сообщения отправляются и получаются
- [ ] Push-уведомления работают (опционально для первого запуска)

## Переменные окружения (опционально)

Если используете `.env` файл:
- [ ] Создан файл `.env` на основе `.env.example`
- [ ] Заполнены все необходимые переменные
- [ ] `.env` добавлен в `.gitignore`

## Проверка конфигурации

Запустите проверку:
```bash
# Linux/Mac
./scripts/check_config.sh

# Windows (PowerShell)
# Проверьте файлы вручную согласно чеклисту выше
```

## Следующие шаги

После завершения настройки:
1. Запустите приложение: `flutter run`
2. Протестируйте основные функции
3. Настройте CI/CD (опционально)
4. Подготовьте к публикации (см. `DEPLOYMENT.md`)

## Полезные ссылки

- Firebase Console: https://console.firebase.google.com/
- Google Cloud Console: https://console.cloud.google.com/
- Flutter документация: https://flutter.dev/docs

