class AppConfig {
  // Backend API URL
  // Production сервер: http://94.131.80.213
  // Для локальной разработки используйте:
  // - Windows/Web: http://localhost:3000
  // - Android эмулятор: http://10.0.2.2:3000 (10.0.2.2 = localhost на хосте)
  // - Реальное Android устройство: http://192.168.1.81:3000 (IP вашего компьютера)
  // - iOS симулятор (Mac): http://localhost:3000
  // - Реальный iPhone (Mac): http://192.168.1.81:3000
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://94.131.80.213:3000', // Production сервер на Yandex Cloud
  );
  
  // WebSocket URL
  // Production сервер: ws://94.131.80.213:3000
  // Для локальной разработки используйте:
  // - Windows/Web: ws://localhost:3000
  // - Android эмулятор: ws://10.0.2.2:3000
  // - Реальное Android устройство: ws://192.168.1.81:3000
  // - iOS симулятор (Mac): ws://localhost:3000
  // - Реальный iPhone (Mac): ws://192.168.1.81:3000
  static const String wsBaseUrl = String.fromEnvironment(
    'WS_BASE_URL',
    defaultValue: 'ws://94.131.80.213:3000', // Production сервер на Yandex Cloud
  );
  
  // Google OAuth Client ID - получите в Google Cloud Console
  static const String googleClientId = String.fromEnvironment(
    'GOOGLE_CLIENT_ID',
    defaultValue: '',
  );

  // Проверка конфигурации
  static bool get isConfigured {
    return apiBaseUrl != 'https://your-backend-api.com' &&
           wsBaseUrl != 'wss://your-backend-api.com';
  }
}
