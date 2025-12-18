import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

import 'core/config/app_config.dart';
import 'core/services/push_notification_service.dart';
import 'presentation/app.dart';

// Условный импорт Firebase только для мобильных платформ
import 'firebase_init.dart' if (dart.library.html) 'firebase_init_stub.dart' show initializeFirebase;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Инициализация Firebase только для мобильных платформ
  await initializeFirebase();
  
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
  
  runApp(const KyteApp());
}

