import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

import 'core/config/app_config.dart';
import 'core/services/push_notification_service.dart';
import 'presentation/app.dart';

// Условный импорт Firebase только для мобильных платформ
import 'firebase_init.dart' if (dart.library.html) 'firebase_init_stub.dart' show initializeFirebase;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    // Инициализация Firebase только для мобильных платформ
    await initializeFirebase();
  } catch (e) {
    debugPrint('⚠️  Ошибка инициализации Firebase: $e');
  }
  
  // Инициализация Push-уведомлений только для мобильных платформ
  if (!kIsWeb) {
    try {
      await PushNotificationService().initialize();
    } catch (e) {
      debugPrint('⚠️  Ошибка инициализации Push-уведомлений: $e');
    }
  }
  
  // Проверка конфигурации API
  if (!AppConfig.isConfigured) {
    debugPrint('⚠️  API URLs не настроены!');
    debugPrint('Используйте --dart-define при запуске или обновите app_config.dart');
  }
  
  debugPrint('🚀 Запуск приложения...');
  debugPrint('🚀 APP VERSION: 1.0.1 (DEBUG UPDATE)');
  debugPrint('📱 API URL: ${AppConfig.apiBaseUrl}');
  debugPrint('🔌 WebSocket URL: ${AppConfig.wsBaseUrl}');
  
  runApp(const KyteApp());
}

