class AppConfig {
  // Backend API URL
  // Production сервер: http://94.131.88.135
  // Для локальной разработки используйте:
  // - Windows/Web: http://localhost:3000
  // - Android эмулятор: http://10.0.2.2:3000 (10.0.2.2 = localhost на хосте)
  // - Реальное Android устройство: http://192.168.1.81:3000 (IP вашего компьютера)
  // - iOS симулятор (Mac): http://localhost:3000
  // - Реальный iPhone (Mac): http://192.168.1.81:3000
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://94.131.88.135', // Production сервер на Yandex Cloud (Nginx проксирует на порт 3000)
  );
  
  // WebSocket URL
  // Production сервер: ws://94.131.88.135 (через Nginx)
  // Для локальной разработки используйте:
  // - Windows/Web: ws://localhost:3000
  // - Android эмулятор: ws://10.0.2.2:3000
  // - Реальное Android устройство: ws://192.168.1.81:3000
  // - iOS симулятор (Mac): ws://localhost:3000
  // - Реальный iPhone (Mac): ws://192.168.1.81:3000
  static const String wsBaseUrl = String.fromEnvironment(
    'WS_BASE_URL',
    defaultValue: 'ws://94.131.88.135', // Production сервер на Yandex Cloud (Nginx проксирует на порт 3000)
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

  // Проверка, используется ли localhost для разработки
  static bool get isLocalhost {
    return apiBaseUrl.contains('localhost') ||
           apiBaseUrl.contains('127.0.0.1') ||
           apiBaseUrl.contains('10.0.2.2') ||
           apiBaseUrl.startsWith('http://192.168.');
  }
}
